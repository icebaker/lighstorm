# frozen_string_literal: true

require_relative '../invoice/all'
require_relative '../payment/all'
require_relative '../forward/all'
require_relative '../transaction/all'
require_relative '../../models/activity'

module Lighstorm
  module Controllers
    module Activity
      module All
        def self.bitcoin_how(transaction_label)
          if transaction_label =~ /:openchannel:/
            'opening-channel'
          elsif transaction_label =~ /:closechannel:/
            'closing-channel'
          else
            'spontaneously'
          end
        end

        def self.fetch(components, direction: nil, layer: nil, how: nil, order: nil, limit: nil)
          activities = []

          # components[:grpc].lightning.list_channels.channels.each do |channel|
          #   if (layer.nil? || layer == 'lightning')
          #      activities << {
          #         direction: 'out',
          #         layer: 'lightning',
          #         at: Time.now,
          #         amount: {
          #           millisatoshis: channel.to_h[:local_chan_reserve_sat] * 1000
          #         },
          #         how: 'reserve',
          #         message: nil,
          #         data: {}
          #       }

          #        activities << {
          #         direction: 'out',
          #         layer: 'lightning',
          #         at: Time.now,
          #         amount: {
          #           millisatoshis: channel.to_h[:commit_fee] * 1000
          #         },
          #         how: 'commit',
          #         message: nil,
          #         data: {}
          #       }
          #     end
          # end

          Transaction::All.data(components).each do |transaction|
            transaction_how = bitcoin_how(transaction[:label])

            if (layer.nil? || layer == 'bitcoin') && (how.nil? || transaction_how =~ /#{Regexp.escape(how)}/)
              activities << {
                direction: (transaction[:amount][:millisatoshis]).positive? ? 'in' : 'out',
                layer: 'bitcoin',
                at: transaction[:at],
                amount: {
                  millisatoshis: if (transaction[:amount][:millisatoshis]).positive?
                                   transaction[:amount][:millisatoshis]
                                 else
                                   -transaction[:amount][:millisatoshis]
                                 end
                },
                how: transaction_how,
                message: nil,
                data: { transaction: transaction }
              }
            end

            next unless (layer.nil? || layer == 'lightning') && (how.nil? || transaction_how =~ /#{Regexp.escape(how)}/) && %w[
              channel opening-channel closing-channel
            ].include?(transaction_how)

            activities << {
              direction: (transaction[:amount][:millisatoshis]).positive? ? 'out' : 'in',
              layer: 'lightning',
              at: transaction[:at] + ((transaction[:amount][:millisatoshis]).positive? ? -1 : 1),
              amount: {
                millisatoshis: if (transaction[:amount][:millisatoshis]).positive?
                                 (transaction[:amount][:millisatoshis] - transaction[:fee][:millisatoshis])
                               else
                                 -(transaction[:amount][:millisatoshis] + transaction[:fee][:millisatoshis])
                               end
              },
              how: transaction_how,
              message: nil,
              data: { transaction: transaction }
            }
          end

          if (direction.nil? || direction == 'in') && (layer.nil? || layer == 'lightning')
            Invoice::All.data(components, spontaneous: true).filter do |invoice|
              !invoice[:payments].nil? && invoice[:payments].size.positive?
            end.each do |invoice|
              activity_how = invoice[:code].nil? ? 'spontaneously' : 'with-invoice'

              next if !how.nil? && how != activity_how

              # TODO: Improve performance by reducing invoice fields and removing payments?
              invoice[:payments].each do |payment|
                activities << {
                  direction: 'in',
                  layer: 'lightning',
                  at: payment[:at],
                  amount: payment[:amount],
                  how: activity_how,
                  message: payment[:message],
                  data: { invoice: invoice }
                }
              end
            end

            Forward::All.data(components).each do |forward|
              next if !how.nil? && how != 'forwarding'

              activities << {
                direction: 'in',
                layer: 'lightning',
                at: forward[:at],
                amount: forward[:fee],
                how: 'forwarding',
                message: nil,
                data: {}
              }
            end
          end

          if (direction.nil? || direction == 'out') && (layer.nil? || layer == 'lightning')
            Payment::All.data(
              components,
              fetch: {
                get_node_info: false,
                lookup_invoice: false,
                decode_pay_req: true,
                get_chan_info: false
              }
            )[:data].each do |payment|
              activity_how = payment[:invoice][:code].nil? ? 'spontaneously' : 'with-invoice'

              next if !how.nil? && how != activity_how

              # TODO: Improve performance by reducing invoice fields?
              activities << {
                direction: 'out',
                layer: 'lightning',
                at: payment[:at],
                amount: payment[:amount],
                how: activity_how,
                message: payment[:message],
                data: { invoice: payment[:invoice] }
              }
            end
          end

          activities = if order.nil? || order == 'desc'
                         activities.sort_by { |activity| -activity[:at].to_i }
                       else
                         activities.sort_by { |activity| activity[:at].to_i }
                       end

          activities = activities[0..limit - 1] unless limit.nil?

          { activities: activities }
        end

        def self.transform(raw)
          raw[:activities].map do |activity|
            activity[:_key] = SecureRandom.hex
            activity
          end
        end

        def self.data(components, direction: nil, layer: nil, how: nil, order: nil, limit: nil, &vcr)
          raw = if vcr.nil?
                  fetch(components, direction: direction, layer: layer, how: how, order: order, limit: limit)
                else
                  vcr.call(-> { fetch(components, direction: direction, how: how, order: order, limit: limit) })
                end

          transform(raw)
        end

        def self.model(data)
          data.map { |data| Models::Activity.new(data) }
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative '../invoice/all'
require_relative '../payment/all'
require_relative '../forward/all'
require_relative '../../models/activity'

module Lighstorm
  module Controllers
    module Activity
      module All
        def self.fetch(direction: nil, how: nil, limit: nil)
          activities = []

          if direction.nil? || direction == 'in'
            Invoice::All.data(spontaneous: true).filter do |invoice|
              !invoice[:payments].nil? && invoice[:payments].size.positive?
            end.each do |invoice|
              activity_how = invoice[:code].nil? ? 'spontaneously' : 'with-invoice'

              next if !how.nil? && how != activity_how

              # TODO: Improve performance by reducing invoice fields and removing payments?
              invoice[:payments].each do |payment|
                activities << {
                  direction: 'in',
                  at: payment[:at],
                  amount: payment[:amount],
                  how: activity_how,
                  message: payment[:message],
                  data: { invoice: invoice }
                }
              end
            end

            Forward::All.data.each do |forward|
              next if !how.nil? && how != 'forwarding'

              activities << {
                direction: 'in',
                at: forward[:at],
                amount: forward[:fee],
                how: 'forwarding',
                message: nil,
                data: {}
              }
            end
          end

          if direction.nil? || direction == 'out'
            Payment::All.data(
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
                at: payment[:at],
                amount: payment[:amount],
                how: activity_how,
                message: payment[:message],
                data: { invoice: payment[:invoice] }
              }
            end
          end

          activities = activities.sort_by { |activity| -activity[:at].to_i }

          activities = activities[0..limit - 1] unless limit.nil?

          { activities: activities }
        end

        def self.transform(raw)
          raw[:activities].map do |activity|
            activity[:_key] = SecureRandom.hex
            activity
          end
        end

        def self.data(direction: nil, how: nil, limit: nil, &vcr)
          raw = if vcr.nil?
                  fetch(direction: direction, how: how, limit: limit)
                else
                  vcr.call(-> { fetch(direction: direction, how: how, limit: limit) })
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

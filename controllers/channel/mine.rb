# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/edges/channel'
require_relative '../../adapters/nodes/node'
require_relative '../../adapters/connections/channel_node/fee'

module Lighstorm
  module Controllers
    module Channel
      module Mine
        def self.fetch(components)
          data = {
            at: Time.now,
            get_info: components[:grpc].lightning.get_info.to_h,
            # Ensure that we are getting fresh up-date data about our own fees.
            fee_report: components[:grpc].lightning.fee_report.to_h,
            list_channels: components[:grpc].lightning.list_channels.channels.map(&:to_h),
            get_chan_info: {},
            get_node_info: {}
          }

          data[:list_channels].each do |channel|
            unless data[:get_chan_info][channel[:chan_id]]
              data[:get_chan_info][channel[:chan_id]] = components[:grpc].lightning.get_chan_info(
                chan_id: channel[:chan_id]
              ).to_h
            end

            next if data[:get_node_info][channel[:remote_pubkey]]

            data[:get_node_info][channel[:remote_pubkey]] = components[:grpc].lightning.get_node_info(
              pub_key: channel[:remote_pubkey]
            ).to_h
          end

          data
        end

        def self.adapt(raw)
          adapted = {
            get_info: Lighstorm::Adapter::Node.get_info(raw[:get_info]),
            fee_report: raw[:fee_report][:channel_fees].map do |raw_fee|
              Lighstorm::Adapter::Fee.fee_report(raw_fee.to_h)
            end,
            list_channels: raw[:list_channels].map do |raw_channel|
              Lighstorm::Adapter::Channel.list_channels(raw_channel.to_h, raw[:at])
            end,
            get_chan_info: {},
            get_node_info: {}
          }

          raw[:get_chan_info].each do |key, value|
            adapted[:get_chan_info][key] = Lighstorm::Adapter::Channel.get_chan_info(value.to_h)
          end

          raw[:get_node_info].each do |key, value|
            adapted[:get_node_info][key] = Lighstorm::Adapter::Node.get_node_info(value.to_h)
          end

          adapted
        end

        def self.transform(data, adapted)
          [0, 1].each do |i|
            data[:partners][i][:node] = adapted[:get_info] if data[:partners][i][:node].nil?

            adapted[:get_chan_info][data[:id].to_i][:partners].each do |partner|
              if data[:partners][i][:node][:public_key] == partner[:node][:public_key]
                data[:partners][i][:policy] = partner[:policy]
              end
            end

            if data[:partners][i][:node][:public_key] == adapted[:get_info][:public_key]
              data[:partners][i][:node][:platform] = adapted[:get_info][:platform]
              data[:partners][i][:node][:myself] = true
              data[:known] = true
              data[:mine] = true
              adapted[:fee_report].each do |channel|
                next unless data[:id] == channel[:id]

                data[:partners][i][:policy][:fee] = channel[:partner][:policy][:fee]
                break
              end
            else
              data[:partners][i][:node] = adapted[:get_node_info][data[:partners][i][:node][:public_key]]
              data[:partners][i][:node][:platform] = {
                blockchain: adapted[:get_info][:platform][:blockchain],
                network: adapted[:get_info][:platform][:network]
              }

              data[:partners][i][:node][:myself] = false
            end
          end
          data
        end

        def self.data(components, &vcr)
          raw = vcr.nil? ? fetch(components) : vcr.call(-> { fetch(components) })

          adapted = adapt(raw)

          adapted[:list_channels].map { |data| transform(data, adapted) }
        end

        def self.model(data)
          data.map do |node_data|
            Lighstorm::Models::Channel.new(node_data)
          end
        end
      end
    end
  end
end

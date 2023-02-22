# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/edges/channel'
require_relative '../../adapters/nodes/node'
require_relative '../../adapters/connections/channel_node/fee'

require_relative '../node/find_by_public_key'

module Lighstorm
  module Controllers
    module Channel
      module FindById
        def self.fetch(id)
          data = {
            at: Time.now,
            get_info: Ports::GRPC.lightning.get_info.to_h,
            # Ensure that we are getting fresh up-date data about our own fees.
            fee_report: Ports::GRPC.lightning.fee_report.to_h,
            get_chan_info: Ports::GRPC.lightning.get_chan_info(chan_id: id.to_i).to_h,
            get_node_info: {},
            list_channels: []
          }

          data[:get_node_info][data[:get_chan_info][:node1_pub]] = Ports::GRPC.lightning.get_node_info(
            pub_key: data[:get_chan_info][:node1_pub]
          ).to_h

          data[:get_node_info][data[:get_chan_info][:node2_pub]] = Ports::GRPC.lightning.get_node_info(
            pub_key: data[:get_chan_info][:node2_pub]
          ).to_h

          partners = [
            data[:get_chan_info][:node1_pub],
            data[:get_chan_info][:node2_pub]
          ]

          is_mine = partners.include?(data[:get_info][:identity_pubkey])

          if is_mine
            partner = partners.find { |p| p != data[:get_info][:identity_pubkey] }

            data[:list_channels] = Ports::GRPC.lightning.list_channels(
              peer: [partner].pack('H*')
            ).channels.map(&:to_h)
          end

          data
        end

        def self.adapt(raw)
          adapted = {
            get_info: Lighstorm::Adapter::Node.get_info(raw[:get_info]),
            get_chan_info: Lighstorm::Adapter::Channel.get_chan_info(raw[:get_chan_info]),
            fee_report: raw[:fee_report][:channel_fees].map do |raw_fee|
              Lighstorm::Adapter::Fee.fee_report(raw_fee.to_h)
            end,
            list_channels: raw[:list_channels].map do |raw_channel|
              Lighstorm::Adapter::Channel.list_channels(raw_channel.to_h, raw[:at])
            end,
            get_node_info: {}
          }

          raw[:get_node_info].each_key do |public_key|
            adapted[:get_node_info][public_key] = Lighstorm::Adapter::Node.get_node_info(
              raw[:get_node_info][public_key]
            )
          end

          adapted
        end

        def self.transform(data, adapted)
          [0, 1].each do |i|
            adapted[:list_channels].each_index do |c|
              if adapted[:list_channels][c][:partners][i][:node][:public_key].nil?
                adapted[:list_channels][c][:partners][i][:node] = adapted[:get_info]
              end
            end
          end

          data[:known] = true
          data[:mine] = false
          data[:exposure] = 'public'

          [0, 1].each do |i|
            data[:partners][i][:node] = adapted[:get_info] if data[:partners][i][:node][:public_key].nil?

            if data[:partners][i][:node][:public_key] == adapted[:get_info][:public_key]
              data[:partners][i][:node] = adapted[:get_info]
              data[:partners][i][:node][:myself] = true
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

          adapted[:list_channels].each do |channel|
            next unless channel[:id] == data[:id]

            channel.each_key do |key|
              next if data.key?(key)

              data[key] = channel[key]
            end

            data[:accounting] = channel[:accounting]

            channel[:partners].each do |partner|
              data[:partners].each_index do |i|
                next unless data[:partners][i][:node][:public_key] == partner[:node][:public_key]

                partner.each_key do |key|
                  next if data[:partners][i].key?(key)

                  data[:partners][i][key] = partner[key]
                end
              end
            end

            break
          end

          data
        end

        def self.data(id, &vcr)
          raw = vcr.nil? ? fetch(id) : vcr.call(-> { fetch(id) })

          adapted = adapt(raw)

          transform(adapted[:get_chan_info], adapted)
        end

        def self.model(data)
          Lighstorm::Models::Channel.new(data)
        end
      end
    end
  end
end

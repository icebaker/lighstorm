# frozen_string_literal: true

require 'digest'

require_relative '../../../ports/grpc'
require_relative '../../../adapters/lightning/nodes/node'
require_relative '../../../adapters/lightning/edges/channel'
require_relative '../../../adapters/lightning/edges/forward'
require_relative '../../../adapters/lightning/connections/channel_node/fee'

require_relative '../../../models/lightning/edges/forward'

module Lighstorm
  module Controller
    module Lightning
      module Forward
        module All
          def self.fetch(components, limit: nil)
            at = Time.now

            last_offset = 0

            forwards = []

            loop do
              response = components[:grpc].lightning.forwarding_history(index_offset: last_offset)

              response.forwarding_events.each { |forward| forwards << forward.to_h }

              # TODO: How to optimize this?
              # break if !limit.nil? && forwards.size >= limit

              break if last_offset == response.last_offset_index || last_offset > response.last_offset_index

              last_offset = response.last_offset_index
            end

            forwards = forwards.sort_by { |raw_forward| -raw_forward[:timestamp_ns] }

            forwards = forwards[0..limit - 1] unless limit.nil?

            data = {
              at: at,
              get_info: components[:grpc].lightning.get_info.to_h,
              fee_report: components[:grpc].lightning.fee_report.to_h,
              forwarding_history: forwards,
              list_channels: {},
              get_chan_info: {},
              get_node_info: {}
            }

            forwards.each do |forward|
              unless data[:get_chan_info][forward[:chan_id_in]]
                begin
                  data[:get_chan_info][forward[:chan_id_in]] = components[:grpc].lightning.get_chan_info(
                    chan_id: forward[:chan_id_in]
                  ).to_h
                rescue GRPC::Unknown => e
                  data[:get_chan_info][forward[:chan_id_in]] = { _error: e }
                end
              end

              next if data[:get_chan_info][forward[:chan_id_out]]

              begin
                data[:get_chan_info][forward[:chan_id_out]] = components[:grpc].lightning.get_chan_info(
                  chan_id: forward[:chan_id_out]
                ).to_h
              rescue GRPC::Unknown => e
                data[:get_chan_info][forward[:chan_id_out]] = { _error: e }
              end
            end

            list_channels_done = {}

            data[:get_chan_info].each_value do |channel|
              next if channel[:_error]

              partners = [channel[:node1_pub], channel[:node2_pub]]

              is_mine = partners.include?(data[:get_info][:identity_pubkey])

              if is_mine
                partner = partners.find { |p| p != data[:get_info][:identity_pubkey] }

                unless list_channels_done[partner]
                  components[:grpc].lightning.list_channels(
                    peer: [partner].pack('H*')
                  ).channels.map(&:to_h).each do |list_channels|
                    data[:list_channels][list_channels[:chan_id]] = list_channels
                  end

                  list_channels_done[partner] = true
                end
              end

              unless data[:get_node_info][channel[:node1_pub]]
                data[:get_node_info][channel[:node1_pub]] = components[:grpc].lightning.get_node_info(
                  pub_key: channel[:node1_pub]
                ).to_h
              end

              next if data[:get_node_info][channel[:node2_pub]]

              data[:get_node_info][channel[:node2_pub]] = components[:grpc].lightning.get_node_info(
                pub_key: channel[:node2_pub]
              ).to_h
            end

            data[:list_channels].each_value do |channel|
              next if data[:get_node_info][channel[:remote_pubkey]]

              data[:get_node_info][channel[:remote_pubkey]] = components[:grpc].lightning.get_node_info(
                pub_key: channel[:remote_pubkey]
              ).to_h
            end

            data
          end

          def self.adapt(raw)
            adapted = {
              get_info: Lighstorm::Adapter::Lightning::Node.get_info(raw[:get_info]),
              forwarding_history: raw[:forwarding_history].map do |raw_forward|
                Lighstorm::Adapter::Lightning::Forward.forwarding_history(raw_forward)
              end,
              fee_report: raw[:fee_report][:channel_fees].map do |raw_fee|
                Lighstorm::Adapter::Lightning::Fee.fee_report(raw_fee.to_h)
              end,
              list_channels: {},
              get_chan_info: {},
              get_node_info: {}
            }

            raw[:get_chan_info].each_key do |key|
              next if raw[:get_chan_info][key][:_error]

              adapted[:get_chan_info][key] = Lighstorm::Adapter::Lightning::Channel.get_chan_info(
                raw[:get_chan_info][key]
              )
            end

            raw[:list_channels].each_key do |key|
              adapted[:list_channels][key] = Lighstorm::Adapter::Lightning::Channel.list_channels(
                raw[:list_channels][key], raw[:at]
              )
            end

            raw[:get_node_info].each_key do |key|
              adapted[:get_node_info][key] = Lighstorm::Adapter::Lightning::Node.get_node_info(
                raw[:get_node_info][key]
              )
            end

            adapted
          end

          def self.transform(data, adapted)
            unless adapted[:get_chan_info][data[:id].to_i]
              data[:_key] = Digest::SHA256.hexdigest(data[:id])
              return data
            end

            data = adapted[:get_chan_info][data[:id].to_i]
            data[:known] = true

            [0, 1].each do |i|
              if data[:partners][i][:node][:public_key] == adapted[:get_info][:public_key]
                data[:partners][i][:node] =
                  adapted[:get_info]
              end

              adapted[:get_chan_info][data[:id].to_i][:partners].each do |partner|
                if data[:partners][i][:node][:public_key] == partner[:node][:public_key]
                  data[:partners][i][:policy] = partner[:policy]
                end
              end

              if data[:partners][i][:node][:public_key] == adapted[:get_info][:public_key]
                data[:partners][i][:node][:platform] = adapted[:get_info][:platform]
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

            channel = adapted[:list_channels][data[:id].to_i]

            return data unless channel

            channel.each_key do |key|
              next if data.key?(key)

              data[key] = channel[key]
            end

            data[:accounting] = channel[:accounting]

            channel[:partners].each do |partner|
              data[:partners].each_index do |i|
                partner.each_key do |key|
                  next if data[:partners][i].key?(key)

                  data[:partners][i][key] = partner[key]
                end
              end
            end

            data
          end

          def self.data(components, limit: nil, &vcr)
            raw = if vcr.nil?
                    fetch(components, limit: limit)
                  else
                    vcr.call(-> { fetch(components, limit: limit) })
                  end

            adapted = adapt(raw)

            adapted[:forwarding_history].map do |data|
              data[:in][:channel] = transform(data[:in][:channel], adapted)
              data[:out][:channel] = transform(data[:out][:channel], adapted)
              data
            end
          end

          def self.model(data)
            data.map do |node_data|
              Lighstorm::Model::Lightning::Forward.new(node_data)
            end
          end
        end
      end
    end
  end
end

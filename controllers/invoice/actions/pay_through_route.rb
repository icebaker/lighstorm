# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'

module Lighstorm
  module Controllers
    module Invoice
      module PayThroughRoute
        def self.perform(_invoice, route:, preview: false, fake: false)
          raise Errors::ToDoError, self

          channels = route.map do |channel_id|
            Channel.find_by_id(channel_id)
          end

          outgoing_channel_id = channels.first.id

          hops_public_keys = []

          hops_public_keys << if channels.first.mine?
                                channels.first.partner.node.public_key
                              else
                                channels.first.partners.last.node.public_key
                              end

          channels[1..channels.size - 2].each do |channel|
            hops_public_keys << channel.partners.last.node.public_key
          end

          hops_public_keys << if channels.last.mine?
                                channels.last.myself.node.public_key
                              else
                                channels.last.partners.last.node.public_key
                              end
          begin
            route = LND.instance.middleware('router.build_route') do
              LND.instance.client.router.build_route(
                amt_msat: amount.milisatoshis,
                outgoing_chan_id: channels.first.id.to_i,
                hop_pubkeys: hops_public_keys.map { |hpk| [hpk].pack('H*') },
                payment_addr: [address].pack('H*')
              )
            end

            if preview
              return {
                method: :send_to_route_v2,
                params: {
                  payment_hash: hash,
                  route: route.to_h[:route],
                  skip_temp_err: true
                }
              }
            end

            LND.instance.middleware('router.send_to_route_v2') do
              LND.instance.client.router.send_to_route_v2(
                payment_hash: [hash].pack('H*'),
                route: route.to_h[:route],
                skip_temp_err: true
              )
            end
          rescue StandardError => e
            e
          end
        end
      end
    end
  end
end

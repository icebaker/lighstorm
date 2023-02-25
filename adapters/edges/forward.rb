# frozen_string_literal: true

require 'digest'

module Lighstorm
  module Adapter
    class Forward
      def self.forwarding_history(grpc)
        {
          _source: :forwarding_history,
          _key: _key(grpc),
          at: Time.at(grpc[:timestamp_ns] / 1e+9),
          fee: { milisatoshis: grpc[:fee_msat] },
          in: {
            amount: { milisatoshis: grpc[:amt_in_msat] },
            channel: {
              id: grpc[:chan_id_in].to_s
            }
          },
          out: {
            amount: { milisatoshis: grpc[:amt_out_msat] },
            channel: {
              id: grpc[:chan_id_out].to_s
            }
          }
        }
      end

      def self._key(grpc)
        Digest::SHA256.hexdigest(
          [
            grpc[:timestamp_ns],
            grpc[:chan_id_in], grpc[:chan_id_out],
            grpc[:amt_in_msat], grpc[:fee_msat]
          ].join('/')
        )
      end
    end
  end
end

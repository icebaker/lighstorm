# frozen_string_literal: true

require 'digest'

module Lighstorm
  module Adapter
    class PaymentChannel
      def self.list_payments(grpc, index)
        {
          _source: :list_payments,
          hop: index + 1,
          amount: { millisatoshis: grpc[:amt_to_forward_msat] },
          fee: { millisatoshis: grpc[:fee_msat] },
          channel: {
            _key: Digest::SHA256.hexdigest(grpc[:chan_id].to_s),
            id: grpc[:chan_id].to_s,
            partners: [
              node: {
                _key: Digest::SHA256.hexdigest(grpc[:pub_key].to_s),
                public_key: grpc[:pub_key]
              }
            ]
          }
        }
      end
    end
  end
end

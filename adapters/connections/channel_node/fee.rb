# frozen_string_literal: true

module Lighstorm
  module Adapter
    class Fee
      def self.fee_report(grpc)
        {
          _source: :fee_report,
          id: grpc[:chan_id].to_s,
          partner: {
            policy: {
              fee: {
                base: {
                  millisatoshis: grpc[:base_fee_msat]
                },
                rate: {
                  parts_per_million: grpc[:fee_per_mil]
                }
              }
            }
          }
        }
      end
    end
  end
end

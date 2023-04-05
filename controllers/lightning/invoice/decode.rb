# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../adapters/lightning/invoice'
require_relative '../../../models/lightning/invoice'

module Lighstorm
  module Controller
    module Lightning
      module Invoice
        module Decode
          def self.fetch(components, code)
            {
              _code: code.sub('lightning:', ''),
              decode_pay_req: components[:grpc].lightning.decode_pay_req(
                pay_req: code.sub('lightning:', '')
              ).to_h
            }
          end

          def self.adapt(raw)
            {
              decode_pay_req: Lighstorm::Adapter::Lightning::Invoice.decode_pay_req(
                raw[:decode_pay_req], raw[:_code]
              )
            }
          end

          def self.transform(adapted)
            adapted[:decode_pay_req]
          end

          def self.data(components, code, &vcr)
            raw = if vcr.nil?
                    fetch(components, code)
                  else
                    vcr.call(-> { fetch(components, code) })
                  end

            adapted = adapt(raw)

            transform(adapted)
          end

          def self.model(data, components)
            Lighstorm::Model::Lightning::Invoice.new(data, components)
          end
        end
      end
    end
  end
end

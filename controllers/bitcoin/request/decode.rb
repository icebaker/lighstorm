# frozen_string_literal: true

require 'uri'

require_relative '../../../adapters/bitcoin/request'
require_relative '../../../models/bitcoin/request'

module Lighstorm
  module Controller
    module Bitcoin
      module Request
        module Decode
          def self.parse(uri)
            # BIP21: https://bips.xyz/21
            parsed = if uri =~ /^\w+:/
                       URI.parse(uri.sub('bitcoin:', 'bitcoin://'))
                     else
                       URI.parse("unknown://#{uri}")
                     end

            uri_hash = {
              scheme: parsed.scheme,
              host: parsed.host,
              port: parsed.port,
              path: parsed.path,
              query: parsed.query,
              fragment: parsed.fragment
            }

            params = parsed.query ? URI.decode_www_form(parsed.query).to_h : {}

            {
              raw: uri,
              parsed: uri_hash.merge({ params: params })
            }
          end

          def self.adapt(raw)
            Lighstorm::Adapter::Bitcoin::Request.decode(raw[:parsed])
          end

          def self.data(uri:)
            raw = parse(uri)

            adapt(raw)
          end

          def self.model(data, components)
            Lighstorm::Model::Bitcoin::Request.new(data, components)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'digest'

module Lighstorm
  module Adapter
    module Bitcoin
      class Request
        def self.decode(uri)
          result = {
            _source: :decode,
            _key: Digest::SHA256.hexdigest([uri[:host]].concat(uri[:params].values).join('/')),
            address: { code: uri[:host] }
          }

          if uri[:params]['amount']
            result[:amount] = {
              millisatoshis: uri[:params]['amount'].to_f * 100_000_000_000.0
            }
          end

          result[:description] = uri[:params]['label'] if uri[:params]['label'] && uri[:params]['label'] != ''

          result[:message] = uri[:params]['message'] if uri[:params]['message'] && uri[:params]['message'] != ''

          result
        end
      end
    end
  end
end

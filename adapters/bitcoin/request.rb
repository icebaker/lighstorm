# frozen_string_literal: true

require 'bigdecimal'

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
              millisatoshis: BigDecimal(uri[:params]['amount']) * BigDecimal('100000000000.0')
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

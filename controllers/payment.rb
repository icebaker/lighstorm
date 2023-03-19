# frozen_string_literal: true

require_relative './concerns/impersonatable'

require_relative './payment/all'

module Lighstorm
  module Controllers
    module Payment
      extend Impersonatable

      class DSL < Impersonatable::DSL
        def all(purpose: nil, limit: nil, fetch: {})
          All.model(All.data(components, purpose: purpose, limit: limit, fetch: fetch), components)
        end

        def first(purpose: nil, fetch: {})
          All.model(All.data(components, purpose: purpose, fetch: fetch), components).first
        end

        def last(purpose: nil, fetch: {})
          All.model(All.data(components, purpose: purpose, fetch: fetch), components).last
        end

        def find_by_secret_hash(secret_hash, &vcr)
          All.model(All.data(components, secret_hash: secret_hash, &vcr), components).first
        end

        def find_by_invoice_code(invoice_code, &vcr)
          All.model(All.data(components, invoice_code: invoice_code, &vcr), components).first
        end
      end
    end
  end
end

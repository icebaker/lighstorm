# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../static/spec'

require_relative '../../models/satoshis'

require_relative '../../controllers/node'
require_relative '../../controllers/channel'
require_relative '../../controllers/payment'
require_relative '../../controllers/forward'
require_relative '../../controllers/invoice'

module Lighstorm
  Node = Controllers::Node
  Channel = Controllers::Channel
  Payment = Controllers::Payment
  Forward = Controllers::Forward
  Invoice = Controllers::Invoice

  Satoshis = Models::Satoshis

  def self.config!(config)
    LND.instance.config = config
  end

  def self.inject_middleware!(middleware_lambda)
    LND.instance.middleware = middleware_lambda
  end

  def self.version
    Static::SPEC[:version]
  end
end

# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../static/spec'

require_relative '../../models/nodes/node'

require_relative '../../models/edges/channel'
require_relative '../../models/edges/forward'
require_relative '../../models/edges/payment'

module Lighstorm
  Node = Models::Node
  Channel = Models::Channel
  Forward = Models::Forward
  Payment = Models::Payment
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

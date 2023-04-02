# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../static/spec'

require_relative '../../models/satoshis'

require_relative '../../controllers/connection'

require_relative '../../controllers/wallet'
require_relative '../../controllers/wallet/activity'

require_relative '../../controllers/lightning/node'
require_relative '../../controllers/lightning/channel'
require_relative '../../controllers/lightning/payment'
require_relative '../../controllers/lightning/forward'
require_relative '../../controllers/lightning/invoice'

require_relative '../../controllers/bitcoin/transaction'
require_relative '../../controllers/bitcoin/request'
require_relative '../../controllers/bitcoin/address'

module Lighstorm
  Connection = Controller::Connection

  Wallet = Controller::Wallet

  Satoshis = Model::Satoshis

  module Lightning
    Node = Controller::Lightning::Node
    Channel = Controller::Lightning::Channel
    Invoice = Controller::Lightning::Invoice
    Payment = Controller::Lightning::Payment
    Forward = Controller::Lightning::Forward
  end

  module Bitcoin
    Address = Controller::Bitcoin::Address
    Request = Controller::Bitcoin::Request
    Transaction = Controller::Bitcoin::Transaction
  end

  def self.connect!(...)
    Controller::Connection.connect!(...)
  end

  def self.inject_middleware!(middleware_lambda)
    LND.instance.middleware = middleware_lambda
  end

  def self.version
    Static::SPEC[:version]
  end
end

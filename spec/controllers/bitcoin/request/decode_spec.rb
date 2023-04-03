# frozen_string_literal: true

require 'json'

require_relative '../../../../controllers/bitcoin/request/decode'
require_relative '../../../../controllers/bitcoin/request'

RSpec.describe Lighstorm::Controller::Bitcoin::Request::Decode do
  context 'complete' do
    let(:uri) do
      'bitcoin:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W?amount=50&label=Luke-Jr&message=Donation%20for%20project%20xyz'
    end

    it 'models' do
      data = described_class.data(uri: uri)

      expect(data).to eq(
        { _source: :decode,
          _key: 'cfe53fceea2fb1ce8a0d40584e1e595bbc2182e445fd726df0ac80d288bb2952',
          address: { code: '175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W' },
          amount: { millisatoshis: 5_000_000_000_000 },
          description: 'Luke-Jr',
          message: 'Donation for project xyz' }
      )

      model = described_class.model(data, Lighstorm::Controller::Bitcoin::Request.components)

      expect(model._key.size).to eq(64)
      expect(model.address.code).to eq('175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W')
      expect(model.amount.bitcoins).to eq(50)
      expect(model.description).to eq('Luke-Jr')
      expect(model.message).to eq('Donation for project xyz')
      expect(model.uri).to eq('bitcoin:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W?amount=50&label=Luke-Jr&message=Donation+for+project+xyz')

      expect(model.to_h).to eq(
        {
          _key: 'cfe53fceea2fb1ce8a0d40584e1e595bbc2182e445fd726df0ac80d288bb2952',
          address: { code: '175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W' },
          amount: { millisatoshis: 5_000_000_000_000 },
          description: 'Luke-Jr',
          message: 'Donation for project xyz',
          uri: 'bitcoin:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W?amount=50&label=Luke-Jr&message=Donation+for+project+xyz'
        }
      )
    end
  end

  context 'address' do
    let(:uri) do
      'bitcoin:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W'
    end

    it 'models' do
      data = described_class.data(uri: uri)

      expect(data).to eq(
        {
          _source: :decode,
          _key: '416b10c7da18c34ae1444db9363e382e0db29b8323be07c34f312506425b834c',
          address: { code: '175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W' }
        }
      )

      model = described_class.model(data, Lighstorm::Controller::Bitcoin::Request.components)

      expect(model.address.code).to eq('175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W')
      expect(model.amount).to be_nil
      expect(model.description).to be_nil
      expect(model.message).to be_nil
      expect(model.uri).to eq('bitcoin:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W')

      expect(model.to_h).to eq(
        {
          _key: '416b10c7da18c34ae1444db9363e382e0db29b8323be07c34f312506425b834c',
          address: { code: '175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W' },
          uri: 'bitcoin:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W'
        }
      )
    end
  end

  context 'no scheme' do
    let(:uri) do
      '175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W'
    end

    it 'models' do
      data = described_class.data(uri: uri)

      expect(data).to eq(
        {
          _source: :decode,
          _key: '416b10c7da18c34ae1444db9363e382e0db29b8323be07c34f312506425b834c',
          address: { code: '175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W' }
        }
      )

      model = described_class.model(data, Lighstorm::Controller::Bitcoin::Request.components)

      expect(model.address.code).to eq('175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W')
      expect(model.amount).to be_nil
      expect(model.description).to be_nil
      expect(model.message).to be_nil
      expect(model.uri).to eq('bitcoin:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W')

      expect(model.to_h).to eq(
        {
          _key: '416b10c7da18c34ae1444db9363e382e0db29b8323be07c34f312506425b834c',
          address: { code: '175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W' },
          uri: 'bitcoin:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W'
        }
      )
    end
  end

  context 'complete without scheme' do
    let(:uri) do
      '175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W?amount=50&label=Luke-Jr&message=Donation+for+project+xyz'
    end

    it 'models' do
      data = described_class.data(uri: uri)

      expect(data).to eq(
        { _source: :decode,
          _key: 'cfe53fceea2fb1ce8a0d40584e1e595bbc2182e445fd726df0ac80d288bb2952',
          address: { code: '175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W' },
          amount: { millisatoshis: 5_000_000_000_000 },
          description: 'Luke-Jr',
          message: 'Donation for project xyz' }
      )

      model = described_class.model(data, Lighstorm::Controller::Bitcoin::Request.components)

      expect(model.address.code).to eq('175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W')
      expect(model.amount.bitcoins).to eq(50)
      expect(model.description).to eq('Luke-Jr')
      expect(model.message).to eq('Donation for project xyz')
      expect(model.uri).to eq('bitcoin:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W?amount=50&label=Luke-Jr&message=Donation+for+project+xyz')

      expect(model.to_h).to eq(
        {
          _key: 'cfe53fceea2fb1ce8a0d40584e1e595bbc2182e445fd726df0ac80d288bb2952',
          address: { code: '175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W' },
          amount: { millisatoshis: 5_000_000_000_000 },
          description: 'Luke-Jr',
          message: 'Donation for project xyz',
          uri: 'bitcoin:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W?amount=50&label=Luke-Jr&message=Donation+for+project+xyz'
        }
      )
    end
  end
end

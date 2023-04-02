# frozen_string_literal: true

require 'json'

require_relative '../../../../controllers/lightning/payment'
require_relative '../../../../controllers/lightning/payment/all'

require_relative '../../../../models/lightning/edges/payment'
require_relative '../../../../models/satoshis'

require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Model::Lightning::Payment do
  describe 'all' do
    let(:data) do
      Lighstorm::Controller::Lightning::Payment::All.data(
        Lighstorm::Controller::Lightning::Payment.components
      ) do |fetch|
        VCR.tape.replay("Controller::Lightning::Payment.all/#{secret_hash}") do
          data = fetch.call
          data[:list_payments] = [
            data[:list_payments].find { |payment| payment[:payment_hash] == secret_hash }
          ]
          data
        end
      end
    end

    let(:payment) do
      described_class.new(data[:data][0], Lighstorm::Controller::Lightning::Payment.components)
    end

    context 'light mode' do
      let(:fetch_options) do
        {
          get_node_info: false,
          lookup_invoice: false,
          decode_pay_req: false,
          get_chan_info: false
        }
      end

      let(:data) do
        Lighstorm::Controller::Lightning::Payment::All.data(
          Lighstorm::Controller::Lightning::Payment.components,
          fetch: fetch_options
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Payment.all/#{secret_hash}", fetch: fetch_options) do
            data = fetch.call
            data[:list_payments] = [
              data[:list_payments].find { |payment| payment[:payment_hash] == secret_hash }
            ]
            data
          end
        end
      end

      let(:secret_hash) { '8e798fbcca7baccab5029f70717fea13d86de2534ab8c7669472813b8da3da16' }

      let(:from) do
        { channel: '850181973150531585', target: nil, exit: nil }
      end

      let(:to) do
        { channel: '850181973150531585', target: 'icebaker/old-stone', entry: nil }
      end

      let(:amount) do
        Lighstorm::Model::Satoshis.new(millisatoshis: 1000)
      end

      let(:to_h_contract) { '36a6dee173c4783a3ac04c0d69e60cffb34e0fe33846d8bdb7c7967888e46fb2' }

      it 'models' do
        expect(data[:meta][:calls][:decode_pay_req]).to be_nil
        expect(data[:meta][:calls][:get_chan_info]).to be_nil
        expect(data[:meta][:calls][:get_node_info]).to be_nil
        expect(data[:meta][:calls][:list_channels]).to be_nil
        expect(data[:meta][:calls][:lookup_invoice]).to be_nil

        expect(payment._key.size).to eq(64)

        expect(payment.state).to eq('succeeded')
        expect(payment.at).to be_a(Time)
        expect(payment.at.utc.to_s).to eq('2023-02-13 23:45:51 UTC')
        expect(payment.purpose).to eq('self-payment')

        expect(payment.amount.millisatoshis).to eq(1000)
        expect(payment.amount.satoshis).to eq(1.0)
        expect(payment.fee.millisatoshis).to eq(0)
        expect(payment.fee.satoshis).to eq(0.0)

        expect(payment.secret.preimage.class).to eq(String)
        expect(payment.secret.preimage.size).to eq(64)
        expect(payment.secret.hash).to eq('8e798fbcca7baccab5029f70717fea13d86de2534ab8c7669472813b8da3da16')

        expect(payment.invoice._key.size).to eq(64)

        expect(payment.invoice.created_at).to be_a(Time)
        expect(payment.invoice.created_at.utc.to_s).to eq('2023-02-13 23:45:51 UTC')

        expect(payment.invoice.settled_at).to be_a(Time)
        expect(payment.invoice.settled_at.utc.to_s).to eq('2023-02-13 23:45:59 UTC')

        expect(payment.invoice.code).to eq('lnbc10n1p374ja0pp53eucl0x20wkv4dgznac8zll2z0vxmcjnf2uvwe55w2qnhrdrmgtqdq0gd5x7cm0d3shgegcqzpgxqyz5vqsp5s5e5gfehafdhx0wvfle05qhhfkuhp0xdj3lwlv8k8tv4m8jrmj4q9qyyssqqr2575r8c4hthdkhgkyj2a6ttvpa35umndlfzncz8mtkxwcvfcj97shyeh88t8yjdeaaj5ah9f9z2qleq8jrn5u63ap2qkrpyg8w4lqqh8med5')
        expect(payment.invoice.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.invoice.amount.satoshis).to eq(amount.satoshis)
        expect(payment.invoice.secret.preimage.class).to eq(String)
        expect(payment.invoice.secret.preimage.size).to eq(64)
        expect(payment.invoice.secret.hash).to eq('8e798fbcca7baccab5029f70717fea13d86de2534ab8c7669472813b8da3da16')
        expect(payment.invoice.description.memo).to be_nil
        expect(payment.invoice.description.hash).to be_nil

        expect(payment.hops.size).to eq(2)

        expect(payment.from.first?).to be(true)
        expect(payment.from.last?).to be(false)
        expect(payment.from.hop).to eq(1)
        expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.from.amount.satoshis).to eq(amount.satoshis)
        expect(payment.from.fee.millisatoshis).to eq(0)
        expect(payment.from.fee.satoshis).to eq(0)
        expect(payment.from.channel._key.size).to eq(64)
        expect(payment.from.channel.id).to eq(from[:channel])
        expect(payment.from.channel.target.alias).to eq(from[:target])
        expect(payment.from.channel.target.public_key.size).to eq(66)
        expect(payment.from.channel.target._key.size).to eq(64)

        expect(payment.hops[0].channel.id).to eq(from[:channel])

        expect(payment.from.channel.exit.alias).to eq(from[:exit])
        expect(payment.from.channel.exit.public_key.size).to eq(66)
        expect(payment.from.channel.exit._key.size).to eq(64)
        expect(payment.from.channel.entry).to be_nil

        expect(payment.to.first?).to be(false)
        expect(payment.to.last?).to be(true)
        expect(payment.to.hop).to eq(2)
        expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.to.amount.satoshis).to eq(amount.satoshis)
        expect(payment.to.fee.millisatoshis).to eq(0)
        expect(payment.to.fee.satoshis).to eq(0)
        expect(payment.to.channel._key.size).to eq(64)
        expect(payment.to.channel.id).to eq(to[:channel])
        expect(payment.to.channel.target.alias).to eq(to[:target])
        expect(payment.to.channel.target.public_key.size).to eq(66)
        expect(payment.to.channel.target._key.size).to eq(64)

        expect(payment.hops[1].channel.id).to eq(to[:channel])

        expect(payment.to.channel.entry.alias).to eq(to[:entry])
        expect(payment.to.channel.entry.public_key.size).to eq(66)
        expect(payment.to.channel.entry._key.size).to eq(64)

        expect(payment.to.channel.exit).to be_nil

        # TODO: Is this safe? Test all the scenarios again, but in lite mode! ;)
        expect(payment.invoice.payable).to eq('once')
        expect(payment.invoice.amount.millisatoshis).to eq(1000)
        expect(payment.message).to be_nil
        expect(payment.through).to eq('non-amp')
        expect(payment.how).to eq('with-invoice')

        Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'purposes' do
      context 'self-payment' do
        let(:secret_hash) { '8e798fbcca7baccab5029f70717fea13d86de2534ab8c7669472813b8da3da16' }

        let(:from) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', exit: 'BCash_Is_Trash' }
        end

        let(:to) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', entry: 'BCash_Is_Trash' }
        end

        let(:amount) do
          Lighstorm::Model::Satoshis.new(millisatoshis: 1000)
        end

        let(:to_h_contract) { '0de14ab266b071700de90c0aa8a2f027873b30d7d997f45343a76e5d91b5f68f' }

        it 'models' do
          expect(data[:meta][:calls].keys.sort).to eq(
            %i[fee_report decode_pay_req lookup_invoice get_chan_info get_node_info list_channels].sort
          )

          expect(payment._key.size).to eq(64)

          expect(payment.at).to be_a(Time)
          expect(payment.at.utc.to_s).to eq('2023-02-13 23:45:51 UTC')

          expect(payment.state).to eq('succeeded')

          expect(payment.amount.millisatoshis).to eq(1000)
          expect(payment.amount.satoshis).to eq(1.0)

          expect(payment.fee.millisatoshis).to eq(0)
          expect(payment.fee.satoshis).to eq(0.0)

          expect(payment.purpose).to eq('self-payment')

          expect(payment.secret.preimage.class).to eq(String)
          expect(payment.secret.preimage.size).to eq(64)
          expect(payment.secret.hash).to eq(secret_hash)

          expect(payment.invoice._key.size).to eq(64)

          expect(payment.invoice.created_at).to be_a(Time)
          expect(payment.invoice.created_at.utc.to_s).to eq('2023-02-13 23:45:51 UTC')

          expect(payment.invoice.settled_at).to be_a(Time)
          expect(payment.invoice.settled_at.utc.to_s).to eq('2023-02-13 23:45:59 UTC')

          expect(payment.invoice.state).to eq('settled')

          expect(payment.invoice.code).to eq('lnbc10n1p374ja0pp53eucl0x20wkv4dgznac8zll2z0vxmcjnf2uvwe55w2qnhrdrmgtqdq0gd5x7cm0d3shgegcqzpgxqyz5vqsp5s5e5gfehafdhx0wvfle05qhhfkuhp0xdj3lwlv8k8tv4m8jrmj4q9qyyssqqr2575r8c4hthdkhgkyj2a6ttvpa35umndlfzncz8mtkxwcvfcj97shyeh88t8yjdeaaj5ah9f9z2qleq8jrn5u63ap2qkrpyg8w4lqqh8med5')

          expect(payment.invoice.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.invoice.amount.satoshis).to eq(amount.satoshis)
          expect(payment.invoice.secret.preimage.class).to eq(String)
          expect(payment.invoice.secret.preimage.size).to eq(64)
          expect(payment.invoice.secret.hash).to eq(secret_hash)
          expect(payment.invoice.description.memo).to eq('Chocolate')
          expect(payment.invoice.description.hash).to be_nil

          expect(payment.hops.size).to eq(2)

          expect(payment.from.first?).to be(true)
          expect(payment.from.last?).to be(false)
          expect(payment.from.hop).to eq(1)
          expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.from.amount.satoshis).to eq(amount.satoshis)
          expect(payment.from.fee.millisatoshis).to eq(0)
          expect(payment.from.fee.satoshis).to eq(0)
          expect(payment.from.channel._key.size).to eq(64)
          expect(payment.from.channel.id).to eq(from[:channel])
          expect(payment.from.channel.target.alias).to eq(from[:target])
          expect(payment.from.channel.target.public_key.size).to eq(66)
          expect(payment.from.channel.target._key.size).to eq(64)

          expect(payment.hops[0].channel.id).to eq(from[:channel])

          expect(payment.from.channel.exit.alias).to eq(from[:exit])
          expect(payment.from.channel.exit.public_key.size).to eq(66)
          expect(payment.from.channel.exit._key.size).to eq(64)
          expect(payment.from.channel.entry).to be_nil

          expect(payment.to.first?).to be(false)
          expect(payment.to.last?).to be(true)
          expect(payment.to.hop).to eq(2)
          expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.to.amount.satoshis).to eq(amount.satoshis)
          expect(payment.to.fee.millisatoshis).to eq(0)
          expect(payment.to.fee.satoshis).to eq(0)
          expect(payment.to.channel._key.size).to eq(64)
          expect(payment.to.channel.id).to eq(to[:channel])
          expect(payment.to.channel.target.alias).to eq(to[:target])
          expect(payment.to.channel.target.public_key.size).to eq(66)
          expect(payment.to.channel.target._key.size).to eq(64)

          expect(payment.hops[1].channel.id).to eq(to[:channel])

          expect(payment.to.channel.entry.alias).to eq(to[:entry])
          expect(payment.to.channel.entry.public_key.size).to eq(66)
          expect(payment.to.channel.entry._key.size).to eq(64)

          expect(payment.to.channel.exit).to be_nil

          expect(payment.invoice.payable).to eq('once')
          expect(payment.invoice.amount.millisatoshis).to eq(1000)
          expect(payment.message).to be_nil
          expect(payment.through).to eq('non-amp')
          expect(payment.how).to eq('with-invoice')

          Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end

      context 'payment' do
        let(:secret_hash) { '9b674ed7ebe54c5395f9e1f7ccb51f4bf9931e5c308e1e1fd25c3195be565d16' }

        let(:from) do
          { channel: '850111604344029185', target: 'deezy.io ⚡✨', exit: 'deezy.io ⚡✨' }
        end

        let(:to) do
          { channel: '825908054838018049', target: 'yalls.org yalls-tor', entry: nil }
        end

        let(:amount) do
          Lighstorm::Model::Satoshis.new(millisatoshis: 150_000)
        end

        let(:to_h_contract) { '5447edbf9384e7366a4c74283d324be2aa8ef390c44fcee365d17307bd0f43c1' }

        it 'models' do
          expect(payment._key.size).to eq(64)
          expect(payment.at).to be_a(Time)
          expect(payment.at.utc.to_s).to eq('2023-01-25 17:16:07 UTC')
          expect(payment.state).to eq('succeeded')
          expect(payment.amount.millisatoshis).to eq(150_000)
          expect(payment.amount.satoshis).to eq(150.0)
          expect(payment.fee.millisatoshis).to eq(0)
          expect(payment.fee.satoshis).to eq(0.0)
          expect(payment.purpose).to eq('payment')
          expect(payment.secret.preimage.class).to eq(String)
          expect(payment.secret.preimage.size).to eq(64)
          expect(payment.secret.hash).to eq(secret_hash)

          expect(payment.invoice._key.size).to eq(64)
          expect(payment.invoice.created_at).to be_a(Time)
          expect(payment.invoice.created_at.utc.to_s).to eq('2023-01-25 17:15:59 UTC')
          expect(payment.invoice.settled_at).to be_a(Time)
          expect(payment.invoice.settled_at.utc.to_s).to eq('2023-01-25 17:16:10 UTC')
          expect(payment.invoice.state).to be_nil
          expect(payment.invoice.code).to eq('lnbc1500n1p3azc70pp5ndn5a4ltu4x9890eu8muedglf0uex8juxz8pu87jtscet0jkt5tqdpa2fjkzep6ypyx7aeqw3hjqatnv5syyctvv9hxxe20vefkzar0wd5xjueqw3hjqcqzysxqr23ssp555e7ddtclkjy9skq2a78gaa0ydt3y6a8dctrzxxls754jqwa2k5s9qyyssqh6t6rzzstjy8dd0n8anjh89jlelkvvtm3nfupj6tt8cm9aww9228hqefagz70mcp995v30hd07g3yklhzl560y64zyzpfyymmxjr6zqpd88jh3')
          expect(payment.invoice.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.invoice.amount.satoshis).to eq(amount.satoshis)
          expect(payment.invoice.secret.preimage.class).to eq(String)
          expect(payment.invoice.secret.preimage.size).to eq(64)
          expect(payment.invoice.secret.hash).to eq(secret_hash)
          expect(payment.invoice.description.memo).to eq('Read: How to use BalanceOfSatoshis to ')
          expect(payment.invoice.description.hash).to be_nil

          expect(payment.hops.size).to eq(2)

          expect(payment.from.first?).to be(true)
          expect(payment.from.last?).to be(false)
          expect(payment.from.hop).to eq(1)
          expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.from.amount.satoshis).to eq(amount.satoshis)
          expect(payment.from.fee.millisatoshis).to eq(0)
          expect(payment.from.fee.satoshis).to eq(0)
          expect(payment.from.channel._key.size).to eq(64)
          expect(payment.from.channel.id).to eq(from[:channel])
          expect(payment.from.channel.target.alias).to eq(from[:target])
          expect(payment.from.channel.target.public_key.size).to eq(66)
          expect(payment.from.channel.target._key.size).to eq(64)

          expect(payment.hops[0].channel.id).to eq(from[:channel])

          expect(payment.from.channel.exit.alias).to eq(from[:exit])
          expect(payment.from.channel.exit.public_key.size).to eq(66)
          expect(payment.from.channel.exit._key.size).to eq(64)
          expect(payment.from.channel.entry).to be_nil

          expect(payment.to.first?).to be(false)
          expect(payment.to.last?).to be(true)
          expect(payment.to.hop).to eq(2)
          expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.to.amount.satoshis).to eq(amount.satoshis)
          expect(payment.to.fee.millisatoshis).to eq(0)
          expect(payment.to.fee.satoshis).to eq(0)
          expect(payment.to.channel._key.size).to eq(64)
          expect(payment.to.channel.id).to eq(to[:channel])
          expect(payment.to.channel.target.alias).to eq(to[:target])
          expect(payment.to.channel.target.public_key.size).to eq(66)
          expect(payment.to.channel.target._key.size).to eq(64)

          expect(payment.hops[1].channel.id).to eq(to[:channel])

          expect(payment.to.channel.entry).to be_nil
          expect(payment.to.channel.exit).to be_nil

          expect(payment.invoice.payable).to eq('once')
          expect(payment.invoice.amount.millisatoshis).to eq(150_000)
          expect(payment.message).to be_nil
          expect(payment.through).to eq('non-amp')
          expect(payment.how).to eq('with-invoice')

          Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end

      context 'p2p' do
        let(:secret_hash) { 'b0c63d4ac56e17818c68d516357629351b35df4ec5605495659a200c184801ed' }

        let(:from) do
          { channel: '850111604344029185', target: 'deezy.io ⚡✨', exit: 'deezy.io ⚡✨' }
        end

        let(:to) do
          { channel: '850111604344029185', target: 'deezy.io ⚡✨', entry: nil }
        end

        let(:amount) do
          Lighstorm::Model::Satoshis.new(millisatoshis: 3_050_000_000)
        end

        let(:to_h_contract) { '82049dafe05d8c5ddb3511538fc19af36d1f9ca4f4a91e8d99d41efd11eaac30' }

        it 'models' do
          expect(payment._key.size).to eq(64)
          expect(payment.at).to be_a(Time)
          expect(payment.at.utc.to_s).to eq('2023-01-23 11:05:45 UTC')
          expect(payment.state).to eq('succeeded')
          expect(payment.amount.millisatoshis).to eq(3_050_000_000)
          expect(payment.amount.satoshis).to eq(3_050_000.0)
          expect(payment.fee.millisatoshis).to eq(0)
          expect(payment.fee.satoshis).to eq(0.0)
          expect(payment.purpose).to eq('peer-to-peer')

          expect(payment.invoice._key.size).to eq(64)
          expect(payment.invoice.created_at).to be_a(Time)
          expect(payment.invoice.created_at.utc.to_s).to eq('2023-01-23 11:05:37 UTC')
          expect(payment.invoice.settled_at).to be_a(Time)
          expect(payment.invoice.settled_at.utc.to_s).to eq('2023-01-23 11:05:47 UTC')
          expect(payment.invoice.state).to be_nil
          expect(payment.invoice.code).to eq('lnbc30500u1p3uu6sppp5krrr6jk9dctcrrrg65tr2a3fx5dnth6wc4s9f9t9ngsqcxzgq8ksdycd9nzqurpd9jzqer9v4a8jgrhd9kxcgrnv4hxggpnxq6r2wpexvs8xct5wvsxzapqxys8xct5wvhhvc3qw3hjqcnrx9chq7tevdcnxvmcw9j85mtcd3skuvmwxv6k66psx4c8xutwwdcr26r3xvmxuarecqzpgxqyp2xqsp54dvval2wjxz4rwql30rvn5yf5vxe53upnnwchjh7dwhh5hvp27hs9qyyssq6z6ue9f37g6vf3unf82tmmln9e4pc5nxs2sxk9gjhshgrv23rn2z3ku0vq25gy5gwce7q85h7405zt69k3aqxxuyfhd638hd7tjk65gqpm0t56')
          expect(payment.invoice.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.invoice.amount.satoshis).to eq(amount.satoshis)
          expect(payment.invoice.secret.preimage.class).to eq(String)
          expect(payment.invoice.secret.preimage.size).to eq(64)
          expect(payment.invoice.secret.hash).to eq(secret_hash)
          expect(payment.invoice.description.memo).to eq('if paid deezy will send 3045893 sats at 1 sats/vb to bc1qpyycq33xqdzmxlan3n35mh05psqnsp5hq36nty')
          expect(payment.invoice.description.hash).to be_nil

          expect(payment.hops.size).to eq(1)

          expect(payment.from.first?).to be(true)
          expect(payment.from.last?).to be(true)
          expect(payment.from.hop).to eq(1)
          expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.from.amount.satoshis).to eq(amount.satoshis)
          expect(payment.from.fee.millisatoshis).to eq(0)
          expect(payment.from.fee.satoshis).to eq(0)
          expect(payment.from.channel._key.size).to eq(64)
          expect(payment.from.channel.id).to eq(from[:channel])
          expect(payment.from.channel.target.alias).to eq(from[:target])
          expect(payment.from.channel.target.public_key.size).to eq(66)
          expect(payment.from.channel.target._key.size).to eq(64)

          expect(payment.hops[0].channel.id).to eq(from[:channel])

          expect(payment.from.channel.exit.alias).to eq(from[:exit])
          expect(payment.from.channel.exit.public_key.size).to eq(66)
          expect(payment.from.channel.exit._key.size).to eq(64)
          expect(payment.from.channel.entry).to be_nil

          expect(payment.to.first?).to be(true)
          expect(payment.to.last?).to be(true)
          expect(payment.to.hop).to eq(1)
          expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.to.amount.satoshis).to eq(amount.satoshis)
          expect(payment.to.fee.millisatoshis).to eq(0)
          expect(payment.to.fee.satoshis).to eq(0)
          expect(payment.to.channel._key.size).to eq(64)
          expect(payment.to.channel.id).to eq(to[:channel])
          expect(payment.to.channel.target.alias).to eq(to[:target])
          expect(payment.to.channel.target.public_key.size).to eq(66)
          expect(payment.to.channel.target._key.size).to eq(64)

          expect(payment.to.channel.entry).to be_nil

          expect(payment.to.channel.exit.alias).to eq(from[:exit])
          expect(payment.to.channel.exit.public_key.size).to eq(66)
          expect(payment.to.channel.exit._key.size).to eq(64)

          expect(payment.invoice.payable).to eq('once')
          expect(payment.invoice.amount.millisatoshis).to eq(3_050_000_000)
          expect(payment.message).to be_nil
          expect(payment.through).to eq('non-amp')
          expect(payment.how).to eq('with-invoice')

          Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end

      context 'rebalance' do
        let(:secret_hash) { '697173cd5d0b97e6b047d37f30b8c96abbfab943880f606aedb2ab7b319cb7ec' }

        let(:from) do
          { channel: '850111604344029185', target: 'deezy.io ⚡✨', exit: 'deezy.io ⚡✨' }
        end

        let(:to) do
          { channel: '848916435345801217', target: 'icebaker/old-stone', entry: 'WalletOfSatoshi.com' }
        end

        let(:amount) do
          Lighstorm::Model::Satoshis.new(millisatoshis: 137_000)
        end

        let(:to_h_contract) { '744a266bf986652626047c64f22d26e6902cb10ebb93978c3a9338643a73cf24' }

        it 'models' do
          expect(payment._key.size).to eq(64)
          expect(payment.at).to be_a(Time)
          expect(payment.at.utc.to_s).to eq('2023-02-03 01:49:13 UTC')
          expect(payment.state).to eq('succeeded')
          expect(payment.amount.millisatoshis).to eq(137_000)
          expect(payment.amount.satoshis).to eq(137.0)
          expect(payment.fee.millisatoshis).to eq(193)
          expect(payment.fee.satoshis).to eq(0.193)
          expect(payment.purpose).to eq('rebalance')

          expect(payment.invoice._key.size).to eq(64)
          expect(payment.invoice.created_at).to be_a(Time)
          expect(payment.invoice.created_at.utc.to_s).to eq('2023-02-03 01:49:12 UTC')
          expect(payment.invoice.settled_at).to be_a(Time)
          expect(payment.invoice.settled_at.utc.to_s).to eq('2023-02-03 01:49:18 UTC')
          expect(payment.invoice.state).to eq('settled')
          expect(payment.invoice.code).to eq('lnbc1370n1p3ac6qcpp5d9ch8n2apwt7dvz86dlnpwxfd2al4w2r3q8kq6hdk24hkvvuklkqdzv2fjkyctvv9hxxefqdanzqcmgv9hxuetvypmkjargypy5ggpcxsurjvfkxsen2ve5x5urqvfjxymscqzpgxqyz5vqsp5fnl94jxqsq655um4vhfjfn7sera70xc6mun3yastxf5u5jjju9gs9qyyssq0vl5dddf2x9avcr6nfj85qtl2nc854cx7ncwhp4cmdzqtqy7xqgxsukxgyw0ga0z9rf24sf9qmtjjplwuhqshq90n92tk9zkwrkkdaqpf3dhlz')
          expect(payment.invoice.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.invoice.amount.satoshis).to eq(amount.satoshis)
          expect(payment.invoice.secret.preimage.class).to eq(String)
          expect(payment.invoice.secret.preimage.size).to eq(64)
          expect(payment.invoice.secret.hash).to eq(secret_hash)
          expect(payment.invoice.description.memo).to eq('Rebalance of channel with ID 848916435345801217')
          expect(payment.invoice.description.hash).to be_nil

          expect(payment.hops.size).to eq(3)

          expect(payment.from.first?).to be(true)
          expect(payment.from.last?).to be(false)
          expect(payment.from.hop).to eq(1)
          expect(payment.from.amount.millisatoshis).to eq(137_041)
          expect(payment.from.amount.satoshis).to eq(137.041)
          expect(payment.from.fee.millisatoshis).to eq(152)
          expect(payment.from.fee.satoshis).to eq(0.152)
          expect(payment.from.channel._key.size).to eq(64)
          expect(payment.from.channel.id).to eq(from[:channel])
          expect(payment.from.channel.target.alias).to eq(from[:target])
          expect(payment.from.channel.target.public_key.size).to eq(66)
          expect(payment.from.channel.target._key.size).to eq(64)

          expect(payment.hops[0].channel.id).to eq(from[:channel])

          expect(payment.from.channel.exit.alias).to eq(from[:exit])
          expect(payment.from.channel.exit.public_key.size).to eq(66)
          expect(payment.from.channel.exit._key.size).to eq(64)
          expect(payment.from.channel.entry).to be_nil

          expect(payment.to.first?).to be(false)
          expect(payment.to.last?).to be(true)
          expect(payment.to.hop).to eq(3)
          expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.to.amount.satoshis).to eq(amount.satoshis)
          expect(payment.to.fee.millisatoshis).to eq(0)
          expect(payment.to.fee.satoshis).to eq(0)
          expect(payment.to.channel._key.size).to eq(64)
          expect(payment.to.channel.id).to eq(to[:channel])
          expect(payment.to.channel.target.alias).to eq(to[:target])
          expect(payment.to.channel.target.public_key.size).to eq(66)
          expect(payment.to.channel.target._key.size).to eq(64)

          expect(payment.hops[2].channel.id).to eq(to[:channel])

          expect(payment.hops[1].channel.target.alias).to eq(to[:entry])

          expect(payment.to.channel.entry.alias).to eq(to[:entry])
          expect(payment.to.channel.entry.public_key.size).to eq(66)
          expect(payment.to.channel.entry._key.size).to eq(64)

          expect(payment.to.channel.exit).to be_nil

          expect(payment.invoice.payable).to eq('once')
          expect(payment.invoice.amount.millisatoshis).to eq(137_000)
          expect(payment.message).to be_nil
          expect(payment.through).to eq('non-amp')
          expect(payment.how).to eq('with-invoice')

          Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end

      context 'rebalance lost channel' do
        let(:secret_hash) { 'b116147b08e782b27be196811c6e56327a2728dcb4b95a94877e827cc48ba886' }

        let(:from) do
          { channel: '848962614654730241', target: 'BCash_Is_Trash', exit: 'BCash_Is_Trash' }
        end

        let(:to) do
          { channel: '848932927837175809', target: 'icebaker/old-stone', entry: 'deezy.io ⚡✨' }
        end

        let(:amount) do
          Lighstorm::Model::Satoshis.new(millisatoshis: 130_000_000)
        end

        let(:to_h_contract) { 'a5560d0326bf693487f32bfa81e3388c76724330736e136186b78e69b56a6ff0' }

        it 'models' do
          expect(payment._key.size).to eq(64)
          expect(payment.at).to be_a(Time)
          expect(payment.at.utc.to_s).to eq('2023-01-15 22:47:51 UTC')
          expect(payment.state).to eq('succeeded')
          expect(payment.amount.millisatoshis).to eq(130_000_000)
          expect(payment.amount.satoshis).to eq(130_000.0)
          expect(payment.fee.millisatoshis).to eq(260)
          expect(payment.fee.satoshis).to eq(0.26)
          expect(payment.purpose).to eq('rebalance')

          expect(payment.invoice._key.size).to eq(64)
          expect(payment.invoice.created_at).to be_a(Time)
          expect(payment.invoice.created_at.utc.to_s).to eq('2023-01-15 22:47:51 UTC')
          expect(payment.invoice.settled_at).to be_a(Time)
          expect(payment.invoice.settled_at.utc.to_s).to eq('2023-01-15 22:48:01 UTC')
          expect(payment.invoice.code).to eq('lnbc1300u1p3ufq5hpp5kytpg7cgu7pty7lpj6q3cmjkxfazw2xukju449y806p8e3yt4zrqdqqcqzpgxqzfvsp5p3r4jgfdthngnjcmupzxfjeff4zhlkqcj6ycxjc9j3xdj88jttaq9qyyssqvj5t0t6w3rt29yfjrdpqc62u4mjvt2fdz8x55tesw50wvadtj5lse6vkmj8r4r3khj4tlwlykz7n5k5fvgdj6qz3e9xghn4e4he5tpsplg3nqj')
          expect(payment.invoice.state).to eq('settled')
          expect(payment.invoice.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.invoice.amount.satoshis).to eq(amount.satoshis)
          expect(payment.invoice.secret.preimage.class).to eq(String)
          expect(payment.invoice.secret.preimage.size).to eq(64)
          expect(payment.invoice.secret.hash).to eq(secret_hash)
          expect(payment.invoice.description.memo).to be_nil
          expect(payment.invoice.description.hash).to be_nil

          expect(payment.hops.size).to eq(4)

          expect(payment.from.first?).to be(true)
          expect(payment.from.last?).to be(false)
          expect(payment.from.hop).to eq(1)
          expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.from.amount.satoshis).to eq(amount.satoshis)
          expect(payment.from.fee.millisatoshis).to eq(260)
          expect(payment.from.fee.satoshis).to eq(0.26)
          expect(payment.from.channel._key.size).to eq(64)
          expect(payment.from.channel.id).to eq(from[:channel])
          expect(payment.from.channel.target.alias).to eq(from[:target])
          expect(payment.from.channel.target.public_key.size).to eq(66)
          expect(payment.from.channel.target._key.size).to eq(64)

          expect(payment.hops[0].channel.id).to eq(from[:channel])

          expect(payment.from.channel.exit.alias).to eq(from[:exit])
          expect(payment.from.channel.exit.public_key.size).to eq(66)
          expect(payment.from.channel.exit._key.size).to eq(64)
          expect(payment.from.channel.entry).to be_nil

          expect(payment.to.first?).to be(false)
          expect(payment.to.last?).to be(true)
          expect(payment.to.hop).to eq(4)
          expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.to.amount.satoshis).to eq(amount.satoshis)
          expect(payment.to.fee.millisatoshis).to eq(0)
          expect(payment.to.fee.satoshis).to eq(0)
          expect(payment.to.channel._key.size).to eq(64)
          expect(payment.to.channel.id).to eq(to[:channel])
          expect(payment.to.channel.target.alias).to eq(to[:target])
          expect(payment.to.channel.target.public_key.size).to eq(66)
          expect(payment.to.channel.target._key.size).to eq(64)

          expect(payment.hops[3].channel.id).to eq(to[:channel])

          expect(payment.to.channel.entry.alias).to eq(to[:entry])
          expect(payment.to.channel.entry.public_key.size).to eq(66)
          expect(payment.to.channel.entry._key.size).to eq(64)

          expect(payment.to.channel.exit).to be_nil

          expect(payment.invoice.payable).to eq('once')
          expect(payment.invoice.amount.millisatoshis).to eq(130_000_000)
          expect(payment.message).to be_nil
          expect(payment.through).to eq('non-amp')
          expect(payment.how).to eq('with-invoice')

          Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end

    context 'ways of payments' do
      context 'spontaneous keysend' do
        let(:secret_hash) { '5473f899c378e1016e168c884122d341c0fde47620f6eaca9237f2e5f1f2d9c7' }

        let(:from) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', exit: 'BCash_Is_Trash' }
        end

        let(:to) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', entry: 'BCash_Is_Trash' }
        end

        let(:amount) do
          Lighstorm::Model::Satoshis.new(millisatoshis: 1200)
        end

        let(:to_h_contract) { '39039307f9b86cb29aa45300709600111c5a985c6ce1fc8d0905a625e7b6f02c' }

        it 'models' do
          expect(payment._key.size).to eq(64)
          expect(payment.at).to be_a(Time)
          expect(payment.at.utc.to_s).to eq('2023-03-11 01:20:28 UTC')
          expect(payment.state).to eq('succeeded')
          expect(payment.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.amount.satoshis).to eq(amount.satoshis)
          expect(payment.fee.millisatoshis).to eq(0)
          expect(payment.fee.satoshis).to eq(0)
          expect(payment.purpose).to eq('self-payment')

          expect(payment.invoice).to be_nil

          expect(payment.hops.size).to eq(2)

          expect(payment.from.first?).to be(true)
          expect(payment.from.last?).to be(false)
          expect(payment.from.hop).to eq(1)
          expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.from.amount.satoshis).to eq(amount.satoshis)
          expect(payment.from.fee.millisatoshis).to eq(0)
          expect(payment.from.fee.satoshis).to eq(0.0)
          expect(payment.from.channel._key.size).to eq(64)
          expect(payment.from.channel.id).to eq(from[:channel])
          expect(payment.from.channel.target.alias).to eq(from[:target])
          expect(payment.from.channel.target.public_key.size).to eq(66)
          expect(payment.from.channel.target._key.size).to eq(64)

          expect(payment.hops[0].channel.id).to eq(from[:channel])

          expect(payment.from.channel.exit.alias).to eq(from[:exit])
          expect(payment.from.channel.exit.public_key.size).to eq(66)
          expect(payment.from.channel.exit._key.size).to eq(64)
          expect(payment.from.channel.entry).to be_nil

          expect(payment.to.first?).to be(false)
          expect(payment.to.last?).to be(true)
          expect(payment.to.hop).to eq(2)
          expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.to.amount.satoshis).to eq(amount.satoshis)
          expect(payment.to.fee.millisatoshis).to eq(0)
          expect(payment.to.fee.satoshis).to eq(0)
          expect(payment.to.channel._key.size).to eq(64)
          expect(payment.to.channel.id).to eq(to[:channel])
          expect(payment.to.channel.target.alias).to eq(to[:target])
          expect(payment.to.channel.target.public_key.size).to eq(66)
          expect(payment.to.channel.target._key.size).to eq(64)

          expect(payment.hops[1].channel.id).to eq(to[:channel])

          expect(payment.to.channel.entry.alias).to eq(to[:entry])
          expect(payment.to.channel.entry.public_key.size).to eq(66)
          expect(payment.to.channel.entry._key.size).to eq(64)

          expect(payment.to.channel.exit).to be_nil

          expect(payment.invoice).to be_nil
          expect(payment.message).to eq('spontaneous keysend!')
          expect(payment.through).to eq('keysend')
          expect(payment.how).to eq('spontaneously')

          Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end

      context 'spontaneous amp' do
        let(:secret_hash) { 'd4b38d2f42fe4b3d1c39478207646898a481baadc632c7381ad0d48d97f44ea2' }

        let(:from) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', exit: 'BCash_Is_Trash' }
        end

        let(:to) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', entry: 'BCash_Is_Trash' }
        end

        let(:amount) do
          Lighstorm::Model::Satoshis.new(millisatoshis: 1500)
        end

        let(:to_h_contract) { '39039307f9b86cb29aa45300709600111c5a985c6ce1fc8d0905a625e7b6f02c' }

        it 'models' do
          expect(payment._key.size).to eq(64)
          expect(payment.at).to be_a(Time)
          expect(payment.at.utc.to_s).to eq('2023-03-11 01:19:56 UTC')
          expect(payment.state).to eq('succeeded')
          expect(payment.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.amount.satoshis).to eq(amount.satoshis)
          expect(payment.fee.millisatoshis).to eq(0)
          expect(payment.fee.satoshis).to eq(0)
          expect(payment.purpose).to eq('self-payment')

          expect(payment.invoice).to be_nil

          expect(payment.hops.size).to eq(2)

          expect(payment.from.first?).to be(true)
          expect(payment.from.last?).to be(false)
          expect(payment.from.hop).to eq(1)
          expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.from.amount.satoshis).to eq(amount.satoshis)
          expect(payment.from.fee.millisatoshis).to eq(0)
          expect(payment.from.fee.satoshis).to eq(0.0)
          expect(payment.from.channel._key.size).to eq(64)
          expect(payment.from.channel.id).to eq(from[:channel])
          expect(payment.from.channel.target.alias).to eq(from[:target])
          expect(payment.from.channel.target.public_key.size).to eq(66)
          expect(payment.from.channel.target._key.size).to eq(64)

          expect(payment.hops[0].channel.id).to eq(from[:channel])

          expect(payment.from.channel.exit.alias).to eq(from[:exit])
          expect(payment.from.channel.exit.public_key.size).to eq(66)
          expect(payment.from.channel.exit._key.size).to eq(64)
          expect(payment.from.channel.entry).to be_nil

          expect(payment.to.first?).to be(false)
          expect(payment.to.last?).to be(true)
          expect(payment.to.hop).to eq(2)
          expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.to.amount.satoshis).to eq(amount.satoshis)
          expect(payment.to.fee.millisatoshis).to eq(0)
          expect(payment.to.fee.satoshis).to eq(0)
          expect(payment.to.channel._key.size).to eq(64)
          expect(payment.to.channel.id).to eq(to[:channel])
          expect(payment.to.channel.target.alias).to eq(to[:target])
          expect(payment.to.channel.target.public_key.size).to eq(66)
          expect(payment.to.channel.target._key.size).to eq(64)

          expect(payment.hops[1].channel.id).to eq(to[:channel])

          expect(payment.to.channel.entry.alias).to eq(to[:entry])
          expect(payment.to.channel.entry.public_key.size).to eq(66)
          expect(payment.to.channel.entry._key.size).to eq(64)

          expect(payment.to.channel.exit).to be_nil

          expect(payment.invoice).to be_nil
          expect(payment.message).to eq('spontaneous amp!')
          expect(payment.through).to eq('amp')
          expect(payment.how).to eq('spontaneously')

          Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end

      context 'amp indefinitely payable fixed amount payment' do
        let(:secret_hash) { '92d7b4252d24a6bc018ab401b57ee735ea2a21c1ea1963490dc1af7d65e3a491' }

        let(:from) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', exit: 'BCash_Is_Trash' }
        end

        let(:to) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', entry: 'BCash_Is_Trash' }
        end

        let(:amount) do
          Lighstorm::Model::Satoshis.new(millisatoshis: 1000)
        end

        let(:to_h_contract) { '5faff4c86ce94b6f06af506fa564da999640f9909ecfb4745a3a3bbbb1446f07' }

        it 'models' do
          expect(payment._key.size).to eq(64)

          expect(payment.at).to be_a(Time)
          expect(payment.at.utc.to_s).to eq('2023-03-10 22:41:06 UTC')

          expect(payment.state).to eq('succeeded')

          expect(payment.amount.millisatoshis).to eq(1000)
          expect(payment.amount.satoshis).to eq(1.0)

          expect(payment.fee.millisatoshis).to eq(0)
          expect(payment.fee.satoshis).to eq(0.0)

          expect(payment.purpose).to eq('self-payment')

          expect(payment.secret.preimage.class).to eq(String)
          expect(payment.secret.preimage.size).to eq(64)
          expect(payment.secret.hash).to eq(secret_hash)

          expect(payment.invoice._key.size).to eq(64)

          expect(payment.invoice.created_at).to be_a(Time)
          expect(payment.invoice.created_at.utc.to_s).to eq('2023-03-10 21:58:05 UTC')

          expect(payment.invoice.settled_at).to be_a(Time)
          expect(payment.invoice.settled_at.utc.to_s).to eq('2023-03-10 22:41:10 UTC')

          expect(payment.invoice.payable).to eq('indefinitely')
          expect(payment.invoice.state).to be_nil

          expect(payment.invoice.code).to eq('lnbc10n1pjqhfldpp502qqwwx8gxks3l0c05uj7a4f072206d2vt7m632nve5l4wzf07hsdqcg3hkuct5v5srz6eqd4ekzarncqzpgxqyz5vqsp5lmj5suzpg93uhk5268lk6axn3gz3dvamcg5n6fcgskr8968spwwq9q8pqqqssq0qced26llyuk3583yrf7yhq4mt89nnd8tnrelm6dmap2gp0wva736ppgdrj9gvl5pvupkm8lvnhx36nkpfjq6seduzjysggcwuv3sgqpynrw75')

          expect(payment.invoice.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.invoice.amount.satoshis).to eq(amount.satoshis)
          expect(payment.invoice.secret.preimage.class).to eq(String)
          expect(payment.invoice.secret.preimage.size).to eq(64)
          expect(payment.invoice.secret.hash).to eq(secret_hash)
          expect(payment.invoice.description.memo).to eq('Donate 1k msats')
          expect(payment.invoice.description.hash).to be_nil

          expect(payment.hops.size).to eq(2)

          expect(payment.from.first?).to be(true)
          expect(payment.from.last?).to be(false)
          expect(payment.from.hop).to eq(1)
          expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.from.amount.satoshis).to eq(amount.satoshis)
          expect(payment.from.fee.millisatoshis).to eq(0)
          expect(payment.from.fee.satoshis).to eq(0)
          expect(payment.from.channel._key.size).to eq(64)
          expect(payment.from.channel.id).to eq(from[:channel])
          expect(payment.from.channel.target.alias).to eq(from[:target])
          expect(payment.from.channel.target.public_key.size).to eq(66)
          expect(payment.from.channel.target._key.size).to eq(64)

          expect(payment.hops[0].channel.id).to eq(from[:channel])

          expect(payment.from.channel.exit.alias).to eq(from[:exit])
          expect(payment.from.channel.exit.public_key.size).to eq(66)
          expect(payment.from.channel.exit._key.size).to eq(64)
          expect(payment.from.channel.entry).to be_nil

          expect(payment.to.first?).to be(false)
          expect(payment.to.last?).to be(true)
          expect(payment.to.hop).to eq(2)
          expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.to.amount.satoshis).to eq(amount.satoshis)
          expect(payment.to.fee.millisatoshis).to eq(0)
          expect(payment.to.fee.satoshis).to eq(0)
          expect(payment.to.channel._key.size).to eq(64)
          expect(payment.to.channel.id).to eq(to[:channel])
          expect(payment.to.channel.target.alias).to eq(to[:target])
          expect(payment.to.channel.target.public_key.size).to eq(66)
          expect(payment.to.channel.target._key.size).to eq(64)

          expect(payment.hops[1].channel.id).to eq(to[:channel])

          expect(payment.to.channel.entry.alias).to eq(to[:entry])
          expect(payment.to.channel.entry.public_key.size).to eq(66)
          expect(payment.to.channel.entry._key.size).to eq(64)

          expect(payment.to.channel.exit).to be_nil

          expect(payment.invoice.payable).to eq('indefinitely')
          expect(payment.invoice.amount.millisatoshis).to eq(1000)
          expect(payment.message).to be_nil
          expect(payment.through).to eq('amp')
          expect(payment.how).to eq('with-invoice')

          Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end

      context 'amp indefinitely payable open amount payment' do
        let(:secret_hash) { 'd19644cdd193f48679adb26761553624d7c853382acbd99fd6d4cc602d2d1175' }

        let(:from) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', exit: 'BCash_Is_Trash' }
        end

        let(:to) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', entry: 'BCash_Is_Trash' }
        end

        let(:amount) do
          Lighstorm::Model::Satoshis.new(millisatoshis: 1210)
        end

        let(:to_h_contract) { '4a98877e35774b817e887922ccfb86c5d6ac7ebb7b18749077922886741542be' }

        it 'models' do
          expect(payment._key.size).to eq(64)

          expect(payment.at).to be_a(Time)
          expect(payment.at.utc.to_s).to eq('2023-03-10 21:50:21 UTC')

          expect(payment.state).to eq('succeeded')

          expect(payment.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.amount.satoshis).to eq(amount.satoshis)

          expect(payment.fee.millisatoshis).to eq(0)
          expect(payment.fee.satoshis).to eq(0.0)

          expect(payment.purpose).to eq('self-payment')

          expect(payment.secret.preimage.class).to eq(String)
          expect(payment.secret.preimage.size).to eq(64)
          expect(payment.secret.hash).to eq(secret_hash)

          expect(payment.invoice._key.size).to eq(64)

          expect(payment.invoice.created_at).to be_a(Time)
          expect(payment.invoice.created_at.utc.to_s).to eq('2023-03-10 21:49:35 UTC')

          expect(payment.invoice.settled_at).to be_a(Time)
          expect(payment.invoice.settled_at.utc.to_s).to eq('2023-03-10 21:50:25 UTC')

          expect(payment.invoice.payable).to eq('indefinitely')
          expect(payment.invoice.state).to be_nil

          expect(payment.invoice.code).to eq('lnbc1pjqhf00pp50wcqgps2scm7la8hwegtacadzc7efxh5535uzhqg5vk0cske5klsdq4facx2m3qg3hkuct5d9hkucqzpgxqyz5vqsp54ry4te3hyvkaatzt60qr56z8z8fdvzkr3m2va5g0vpdnzfuawads9q8pqqqssq36wvptehc6tka3d938eh4zrgrhanxmpfk3ptkty0cqjcwcrln609h45252peagstjf527d7y5emhl8m5jh20pdnlqtl7tnhav56zp9cqspw2e3')

          expect(payment.invoice.amount).to be_nil
          expect(payment.invoice.secret.preimage.class).to eq(String)
          expect(payment.invoice.secret.preimage.size).to eq(64)
          expect(payment.invoice.secret.hash).to eq(secret_hash)
          expect(payment.invoice.description.memo).to eq('Open Donation')
          expect(payment.invoice.description.hash).to be_nil

          expect(payment.hops.size).to eq(2)

          expect(payment.from.first?).to be(true)
          expect(payment.from.last?).to be(false)
          expect(payment.from.hop).to eq(1)
          expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.from.amount.satoshis).to eq(amount.satoshis)
          expect(payment.from.fee.millisatoshis).to eq(0)
          expect(payment.from.fee.satoshis).to eq(0)
          expect(payment.from.channel._key.size).to eq(64)
          expect(payment.from.channel.id).to eq(from[:channel])
          expect(payment.from.channel.target.alias).to eq(from[:target])
          expect(payment.from.channel.target.public_key.size).to eq(66)
          expect(payment.from.channel.target._key.size).to eq(64)

          expect(payment.hops[0].channel.id).to eq(from[:channel])

          expect(payment.from.channel.exit.alias).to eq(from[:exit])
          expect(payment.from.channel.exit.public_key.size).to eq(66)
          expect(payment.from.channel.exit._key.size).to eq(64)
          expect(payment.from.channel.entry).to be_nil

          expect(payment.to.first?).to be(false)
          expect(payment.to.last?).to be(true)
          expect(payment.to.hop).to eq(2)
          expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.to.amount.satoshis).to eq(amount.satoshis)
          expect(payment.to.fee.millisatoshis).to eq(0)
          expect(payment.to.fee.satoshis).to eq(0)
          expect(payment.to.channel._key.size).to eq(64)
          expect(payment.to.channel.id).to eq(to[:channel])
          expect(payment.to.channel.target.alias).to eq(to[:target])
          expect(payment.to.channel.target.public_key.size).to eq(66)
          expect(payment.to.channel.target._key.size).to eq(64)

          expect(payment.hops[1].channel.id).to eq(to[:channel])

          expect(payment.to.channel.entry.alias).to eq(to[:entry])
          expect(payment.to.channel.entry.public_key.size).to eq(66)
          expect(payment.to.channel.entry._key.size).to eq(64)

          expect(payment.to.channel.exit).to be_nil

          expect(payment.invoice.payable).to eq('indefinitely')
          expect(payment.invoice.amount).to be_nil
          expect(payment.message).to eq('here we go!')
          expect(payment.through).to eq('amp')
          expect(payment.how).to eq('with-invoice')

          Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end

      context 'non-amp once payable open amount payment' do
        let(:secret_hash) { '15cf219e3db2b721d1eff89ef64111a7bf4ff2f70ab86bdd2c359248b1f91c0e' }

        let(:from) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', exit: 'BCash_Is_Trash' }
        end

        let(:to) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', entry: 'BCash_Is_Trash' }
        end

        let(:amount) do
          Lighstorm::Model::Satoshis.new(millisatoshis: 1121)
        end

        let(:to_h_contract) { 'bf98664158b4c62929000d2df2dc3d2140f1b629b372306498b0d13689fe4a6e' }

        it 'models' do
          expect(payment._key.size).to eq(64)

          expect(payment.at).to be_a(Time)
          expect(payment.at.utc.to_s).to eq('2023-03-10 21:46:54 UTC')

          expect(payment.state).to eq('succeeded')

          expect(payment.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.amount.satoshis).to eq(amount.satoshis)

          expect(payment.fee.millisatoshis).to eq(0)
          expect(payment.fee.satoshis).to eq(0.0)

          expect(payment.purpose).to eq('self-payment')

          expect(payment.secret.preimage.class).to eq(String)
          expect(payment.secret.preimage.size).to eq(64)
          expect(payment.secret.hash).to eq(secret_hash)

          expect(payment.invoice._key.size).to eq(64)

          expect(payment.invoice.created_at).to be_a(Time)
          expect(payment.invoice.created_at.utc.to_s).to eq('2023-03-10 21:46:23 UTC')

          expect(payment.invoice.settled_at).to be_a(Time)
          expect(payment.invoice.settled_at.utc.to_s).to eq('2023-03-10 21:46:58 UTC')

          expect(payment.invoice.payable).to eq('once')
          expect(payment.invoice.state).to eq('settled')

          expect(payment.invoice.code).to eq('lnbc1pjqhff0pp5zh8jr83ak2mjr500lz00vsg357l5luhhp2uxhhfvxkfy3v0ers8qdqafahx2gz5d9kk2gzzv4jhygz0wpjkucqzpgxqyz5vqsp54dxu84v66rzhmg98uzadgc9hqy7na7jtx62xltdyt0ug8te5w7dq9qyyssqgjl6avmq543x5gfw2zsplvvka7mpv78r8slkw8x5uhyv8lawdsppntn5texwr66vmv590szn5wdqk48vtguhxhvf2zvh58eqj2nmq5gpv54ehd')

          expect(payment.invoice.amount).to be_nil
          expect(payment.invoice.secret.preimage.class).to eq(String)
          expect(payment.invoice.secret.preimage.size).to eq(64)
          expect(payment.invoice.secret.hash).to eq(secret_hash)
          expect(payment.invoice.description.memo).to eq('One Time Beer Open')
          expect(payment.invoice.description.hash).to be_nil

          expect(payment.hops.size).to eq(2)

          expect(payment.from.first?).to be(true)
          expect(payment.from.last?).to be(false)
          expect(payment.from.hop).to eq(1)
          expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.from.amount.satoshis).to eq(amount.satoshis)
          expect(payment.from.fee.millisatoshis).to eq(0)
          expect(payment.from.fee.satoshis).to eq(0)
          expect(payment.from.channel._key.size).to eq(64)
          expect(payment.from.channel.id).to eq(from[:channel])
          expect(payment.from.channel.target.alias).to eq(from[:target])
          expect(payment.from.channel.target.public_key.size).to eq(66)
          expect(payment.from.channel.target._key.size).to eq(64)

          expect(payment.hops[0].channel.id).to eq(from[:channel])

          expect(payment.from.channel.exit.alias).to eq(from[:exit])
          expect(payment.from.channel.exit.public_key.size).to eq(66)
          expect(payment.from.channel.exit._key.size).to eq(64)
          expect(payment.from.channel.entry).to be_nil

          expect(payment.to.first?).to be(false)
          expect(payment.to.last?).to be(true)
          expect(payment.to.hop).to eq(2)
          expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.to.amount.satoshis).to eq(amount.satoshis)
          expect(payment.to.fee.millisatoshis).to eq(0)
          expect(payment.to.fee.satoshis).to eq(0)
          expect(payment.to.channel._key.size).to eq(64)
          expect(payment.to.channel.id).to eq(to[:channel])
          expect(payment.to.channel.target.alias).to eq(to[:target])
          expect(payment.to.channel.target.public_key.size).to eq(66)
          expect(payment.to.channel.target._key.size).to eq(64)

          expect(payment.hops[1].channel.id).to eq(to[:channel])

          expect(payment.to.channel.entry.alias).to eq(to[:entry])
          expect(payment.to.channel.entry.public_key.size).to eq(66)
          expect(payment.to.channel.entry._key.size).to eq(64)

          expect(payment.to.channel.exit).to be_nil

          expect(payment.invoice.payable).to eq('once')
          expect(payment.invoice.amount).to be_nil
          expect(payment.message).to eq('paying what I want')
          expect(payment.through).to eq('non-amp')
          expect(payment.how).to eq('with-invoice')

          Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end

      context 'non-amp once payable fixed amount payment' do
        let(:secret_hash) { 'e8bcaeacc407ff1192407cda123ff02768f89f9278a885dbd2e6687c271a89b6' }

        let(:from) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', exit: 'BCash_Is_Trash' }
        end

        let(:to) do
          { channel: '850181973150531585', target: 'icebaker/old-stone', entry: 'BCash_Is_Trash' }
        end

        let(:amount) do
          Lighstorm::Model::Satoshis.new(millisatoshis: 1278)
        end

        let(:to_h_contract) { '5360e82c935621238eedc10fea167472af32cc795bba828f23b74ae8c4156c89' }

        it 'models' do
          expect(payment._key.size).to eq(64)

          expect(payment.at).to be_a(Time)
          expect(payment.at.utc.to_s).to eq('2023-03-10 21:42:35 UTC')

          expect(payment.state).to eq('succeeded')

          expect(payment.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.amount.satoshis).to eq(amount.satoshis)

          expect(payment.fee.millisatoshis).to eq(0)
          expect(payment.fee.satoshis).to eq(0.0)

          expect(payment.purpose).to eq('self-payment')

          expect(payment.secret.preimage.class).to eq(String)
          expect(payment.secret.preimage.size).to eq(64)
          expect(payment.secret.hash).to eq(secret_hash)

          expect(payment.invoice._key.size).to eq(64)

          expect(payment.invoice.created_at).to be_a(Time)
          expect(payment.invoice.created_at.utc.to_s).to eq('2023-03-10 21:42:26 UTC')

          expect(payment.invoice.settled_at).to be_a(Time)
          expect(payment.invoice.settled_at.utc.to_s).to eq('2023-03-10 21:42:39 UTC')

          expect(payment.invoice.payable).to eq('once')
          expect(payment.invoice.state).to eq('settled')

          expect(payment.invoice.code).to eq('lnbc12780p1pjqhfzzpp5az72atxyqll3ryjq0ndpy0lsya5038uj0z5gtk7jue58cfc63xmqdqcfahx2gz5d9kk2gzrdanxvet9cqzpgxqyz5vqsp5tw5mwdscy7jhtpjh3wn9lw43q4ffu047f5wnkc2g70fhwwmj7nts9qyyssqrthrhkehvwjx606v6hvhj5uwar7cxk523y0rx8dx4mm5zcavqwpncz2yla64ppk82nwx3xamzlca8kzjudl49mndeqlyzsdzqkj9jkcq74sv8g')

          expect(payment.invoice.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.invoice.secret.preimage.class).to eq(String)
          expect(payment.invoice.secret.preimage.size).to eq(64)
          expect(payment.invoice.secret.hash).to eq(secret_hash)
          expect(payment.invoice.description.memo).to eq('One Time Coffee')
          expect(payment.invoice.description.hash).to be_nil

          expect(payment.hops.size).to eq(2)

          expect(payment.from.first?).to be(true)
          expect(payment.from.last?).to be(false)
          expect(payment.from.hop).to eq(1)
          expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.from.amount.satoshis).to eq(amount.satoshis)
          expect(payment.from.fee.millisatoshis).to eq(0)
          expect(payment.from.fee.satoshis).to eq(0)
          expect(payment.from.channel._key.size).to eq(64)
          expect(payment.from.channel.id).to eq(from[:channel])
          expect(payment.from.channel.target.alias).to eq(from[:target])
          expect(payment.from.channel.target.public_key.size).to eq(66)
          expect(payment.from.channel.target._key.size).to eq(64)

          expect(payment.hops[0].channel.id).to eq(from[:channel])

          expect(payment.from.channel.exit.alias).to eq(from[:exit])
          expect(payment.from.channel.exit.public_key.size).to eq(66)
          expect(payment.from.channel.exit._key.size).to eq(64)
          expect(payment.from.channel.entry).to be_nil

          expect(payment.to.first?).to be(false)
          expect(payment.to.last?).to be(true)
          expect(payment.to.hop).to eq(2)
          expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.to.amount.satoshis).to eq(amount.satoshis)
          expect(payment.to.fee.millisatoshis).to eq(0)
          expect(payment.to.fee.satoshis).to eq(0)
          expect(payment.to.channel._key.size).to eq(64)
          expect(payment.to.channel.id).to eq(to[:channel])
          expect(payment.to.channel.target.alias).to eq(to[:target])
          expect(payment.to.channel.target.public_key.size).to eq(66)
          expect(payment.to.channel.target._key.size).to eq(64)

          expect(payment.hops[1].channel.id).to eq(to[:channel])

          expect(payment.to.channel.entry.alias).to eq(to[:entry])
          expect(payment.to.channel.entry.public_key.size).to eq(66)
          expect(payment.to.channel.entry._key.size).to eq(64)

          expect(payment.to.channel.exit).to be_nil

          expect(payment.invoice.payable).to eq('once')
          expect(payment.invoice.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.message).to eq('paying the coffee')
          expect(payment.through).to eq('non-amp')
          expect(payment.how).to eq('with-invoice')

          Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end

      context 'private node' do
        let(:secret_hash) { '80eba71f056b5a02f008c576b52e2c8e269adc53a05582cbecfcb57f42aa5349' }

        let(:from) do
          { channel: '850099509773795329', target: 'Boltz', exit: 'Boltz' }
        end

        let(:to) do
          { channel: '1099511627776', target: nil, entry: 'BCash_Is_Trash' }
        end

        let(:amount) do
          Lighstorm::Model::Satoshis.new(millisatoshis: 3_000_000)
        end

        let(:to_h_contract) { 'fb3562b218ee7deee56bcd12b54e5cdf697f8bb8a68c6fc3b7de5c95c1f5fc1c' }

        it 'models' do
          expect(payment._key.size).to eq(64)

          expect(payment.at).to be_a(Time)
          expect(payment.at.utc.to_s).to eq('2023-03-12 01:09:56 UTC')

          expect(payment.state).to eq('succeeded')

          expect(payment.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.amount.satoshis).to eq(amount.satoshis)

          expect(payment.fee.millisatoshis).to eq(2236)
          expect(payment.fee.satoshis).to eq(2.236)

          expect(payment.purpose).to eq('payment')

          expect(payment.secret.preimage.class).to eq(String)
          expect(payment.secret.preimage.size).to eq(64)
          expect(payment.secret.hash).to eq(secret_hash)

          expect(payment.invoice._key.size).to eq(64)

          expect(payment.invoice.created_at).to be_a(Time)
          expect(payment.invoice.created_at.utc.to_s).to eq('2023-03-12 00:48:06 UTC')

          expect(payment.invoice.settled_at).to be_a(Time)
          expect(payment.invoice.settled_at.utc.to_s).to eq('2023-03-12 01:10:34 UTC')

          expect(payment.invoice.payable).to eq('once')
          expect(payment.invoice.state).to be_nil

          expect(payment.invoice.code).to eq('lnbc30u1pjq6g2xpp5sr46w8c9dddq9uqgc4mt2t3v3cnf4hzn5p2c9jlvlj6h7s422dysdqqcqzpgxqrrssrzjqvgptfurj3528snx6e3dtwepafxw5fpzdymw9pj20jj09sunnqmwqqqqqyqqqqqqqqqqqqlgqqqqqqgqjqnp4q2k4f66f04u08mwnkpx4ttpkm28z9ztxa364rr97w2tqvm7tqkmf7sp5pk7znhtnjk6msfscjufkeypg2hp64s9q9qkrantxmedq7r0r3xns9qyyssqhuneqh6y49xct5n6t6q57u4fahj7jsu997kwkauemqx5d47l7879aau7d2yx7cf2lxpq0zc4qw96cw5e4u5nzja3arkypyqyc7sy4qgqx3je87')

          expect(payment.invoice.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.invoice.secret.preimage.class).to eq(String)
          expect(payment.invoice.secret.preimage.size).to eq(64)
          expect(payment.invoice.secret.hash).to eq(secret_hash)
          expect(payment.invoice.description.memo).to be_nil
          expect(payment.invoice.description.hash).to be_nil

          expect(payment.hops.size).to eq(5)

          expect(payment.from.first?).to be(true)
          expect(payment.from.last?).to be(false)
          expect(payment.from.hop).to eq(1)
          expect(payment.from.amount.millisatoshis).to eq(3_002_233)
          expect(payment.from.amount.satoshis).to eq(3002.233)
          expect(payment.from.fee.millisatoshis).to eq(3)
          expect(payment.from.fee.satoshis).to eq(0.003)
          expect(payment.from.channel._key.size).to eq(64)
          expect(payment.from.channel.id).to eq(from[:channel])
          expect(payment.from.channel.target.alias).to eq(from[:target])
          expect(payment.from.channel.target.public_key.size).to eq(66)
          expect(payment.from.channel.target._key.size).to eq(64)

          expect(payment.hops[0].channel.id).to eq(from[:channel])

          expect(payment.from.channel.exit.alias).to eq(from[:exit])
          expect(payment.from.channel.exit.public_key.size).to eq(66)
          expect(payment.from.channel.exit._key.size).to eq(64)
          expect(payment.from.channel.entry).to be_nil

          expect(payment.to.first?).to be(false)
          expect(payment.to.last?).to be(true)
          expect(payment.to.hop).to eq(5)
          expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.to.amount.satoshis).to eq(amount.satoshis)
          expect(payment.to.fee.millisatoshis).to eq(0)
          expect(payment.to.fee.satoshis).to eq(0)
          expect(payment.to.channel._key.size).to eq(64)
          expect(payment.to.channel.id).to eq(to[:channel])
          expect(payment.to.channel.target.alias).to eq(to[:target])
          expect(payment.to.channel.target.public_key.size).to eq(66)
          expect(payment.to.channel.target._key.size).to eq(64)

          expect(payment.hops[4].channel.id).to eq(to[:channel])

          expect(payment.to.channel.entry).to be_nil

          expect(payment.to.channel.exit).to be_nil

          expect(payment.invoice.payable).to eq('once')
          expect(payment.invoice.amount.millisatoshis).to eq(amount.millisatoshis)
          expect(payment.message).to be_nil
          expect(payment.through).to eq('non-amp')
          expect(payment.how).to eq('with-invoice')

          Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end

    context 'find by invoice_code' do
      let(:invoice_code) do
        'lnbc490n1pjqma6vpp58kkl5n6h8wtw9wq22v86ddvj8p5lnv3xvmffeda708h5heldq28sdqyv93qcqzysxqr23ssp57jq9y6t4fsplxz6lgr3ryqtnf7y4xjc6hr90nasg44y23cc5xkgq9qyyssqfw6p66h7cdy93zh8fs4xd9s4a3fyy6pwj6t3t9t8d36w49vyrpzqdxrc9kwq9uqzg2eluaxet75px70dsltm0cg9qye967f09stcefsq92nuxh'
      end

      let(:data) do
        Lighstorm::Controller::Lightning::Payment::All.data(
          Lighstorm::Controller::Lightning::Payment.components,
          invoice_code: invoice_code
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Payment.all/invoice_code/#{invoice_code}") do
            fetch.call
          end
        end
      end

      let(:from) do
        { channel: '850099509773795329', target: 'Boltz', exit: 'Boltz' }
      end

      let(:to) do
        { channel: '816834884962287617', target: 'yalls.org yalls-tor', entry: nil }
      end

      let(:amount) do
        Lighstorm::Model::Satoshis.new(millisatoshis: 49_000)
      end

      let(:to_h_contract) { 'e5e5b0901e2a5c1e401aea998b2b75bfd9f6d794747dc07521005b771c00954a' }

      it 'models' do
        expect(payment._key.size).to eq(64)
        expect(payment.at).to be_a(Time)
        expect(payment.at.utc.to_s).to eq('2023-03-12 16:01:54 UTC')
        expect(payment.state).to eq('succeeded')
        expect(payment.amount.millisatoshis).to eq(49_000)
        expect(payment.amount.satoshis).to eq(49.0)
        expect(payment.fee.millisatoshis).to eq(0)
        expect(payment.fee.satoshis).to eq(0.0)
        expect(payment.purpose).to eq('payment')
        expect(payment.secret.preimage.class).to eq(String)
        expect(payment.secret.preimage.size).to eq(64)
        expect(payment.secret.hash).to eq('3dadfa4f573b96e2b80a530fa6b5923869f9b22666d29cb7be79ef4be7ed028f')

        expect(payment.invoice._key.size).to eq(64)
        expect(payment.invoice.created_at).to be_a(Time)
        expect(payment.invoice.created_at.utc.to_s).to eq('2023-03-12 16:01:16 UTC')
        expect(payment.invoice.settled_at).to be_a(Time)
        expect(payment.invoice.settled_at.utc.to_s).to eq('2023-03-12 16:01:56 UTC')
        expect(payment.invoice.state).to be_nil
        expect(payment.invoice.code).to eq(invoice_code)
        expect(payment.invoice.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.invoice.amount.satoshis).to eq(amount.satoshis)
        expect(payment.invoice.secret.preimage.class).to eq(String)
        expect(payment.invoice.secret.preimage.size).to eq(64)
        expect(payment.invoice.secret.hash).to eq('3dadfa4f573b96e2b80a530fa6b5923869f9b22666d29cb7be79ef4be7ed028f')
        expect(payment.invoice.description.memo).to eq('ab')
        expect(payment.invoice.description.hash).to be_nil

        expect(payment.hops.size).to eq(2)

        expect(payment.from.first?).to be(true)
        expect(payment.from.last?).to be(false)
        expect(payment.from.hop).to eq(1)
        expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.from.amount.satoshis).to eq(amount.satoshis)
        expect(payment.from.fee.millisatoshis).to eq(0)
        expect(payment.from.fee.satoshis).to eq(0)
        expect(payment.from.channel._key.size).to eq(64)
        expect(payment.from.channel.id).to eq(from[:channel])
        expect(payment.from.channel.target.alias).to eq(from[:target])
        expect(payment.from.channel.target.public_key.size).to eq(66)
        expect(payment.from.channel.target._key.size).to eq(64)

        expect(payment.hops[0].channel.id).to eq(from[:channel])

        expect(payment.from.channel.exit.alias).to eq(from[:exit])
        expect(payment.from.channel.exit.public_key.size).to eq(66)
        expect(payment.from.channel.exit._key.size).to eq(64)
        expect(payment.from.channel.entry).to be_nil

        expect(payment.to.first?).to be(false)
        expect(payment.to.last?).to be(true)
        expect(payment.to.hop).to eq(2)
        expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.to.amount.satoshis).to eq(amount.satoshis)
        expect(payment.to.fee.millisatoshis).to eq(0)
        expect(payment.to.fee.satoshis).to eq(0)
        expect(payment.to.channel._key.size).to eq(64)
        expect(payment.to.channel.id).to eq(to[:channel])
        expect(payment.to.channel.target.alias).to eq(to[:target])
        expect(payment.to.channel.target.public_key.size).to eq(66)
        expect(payment.to.channel.target._key.size).to eq(64)

        expect(payment.hops[1].channel.id).to eq(to[:channel])

        expect(payment.to.channel.entry).to be_nil
        expect(payment.to.channel.exit).to be_nil

        expect(payment.invoice.payable).to eq('once')
        expect(payment.invoice.amount.millisatoshis).to eq(49_000)
        expect(payment.message).to eq('yalls test')
        expect(payment.through).to eq('non-amp')
        expect(payment.how).to eq('with-invoice')

        Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'find by secret_hash' do
      let(:invoice_code) do
        'lnbc490n1pjqma6vpp58kkl5n6h8wtw9wq22v86ddvj8p5lnv3xvmffeda708h5heldq28sdqyv93qcqzysxqr23ssp57jq9y6t4fsplxz6lgr3ryqtnf7y4xjc6hr90nasg44y23cc5xkgq9qyyssqfw6p66h7cdy93zh8fs4xd9s4a3fyy6pwj6t3t9t8d36w49vyrpzqdxrc9kwq9uqzg2eluaxet75px70dsltm0cg9qye967f09stcefsq92nuxh'
      end

      let(:secret_hash) do
        '3dadfa4f573b96e2b80a530fa6b5923869f9b22666d29cb7be79ef4be7ed028f'
      end

      let(:data) do
        Lighstorm::Controller::Lightning::Payment::All.data(
          Lighstorm::Controller::Lightning::Payment.components,
          secret_hash: secret_hash
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Payment.all/secret_hash/#{secret_hash}") do
            fetch.call
          end
        end
      end

      let(:from) do
        { channel: '850099509773795329', target: 'Boltz', exit: 'Boltz' }
      end

      let(:to) do
        { channel: '816834884962287617', target: 'yalls.org yalls-tor', entry: nil }
      end

      let(:amount) do
        Lighstorm::Model::Satoshis.new(millisatoshis: 49_000)
      end

      let(:to_h_contract) { 'e5e5b0901e2a5c1e401aea998b2b75bfd9f6d794747dc07521005b771c00954a' }

      it 'models' do
        expect(payment._key.size).to eq(64)
        expect(payment.at).to be_a(Time)
        expect(payment.at.utc.to_s).to eq('2023-03-12 16:01:54 UTC')
        expect(payment.state).to eq('succeeded')
        expect(payment.amount.millisatoshis).to eq(49_000)
        expect(payment.amount.satoshis).to eq(49.0)
        expect(payment.fee.millisatoshis).to eq(0)
        expect(payment.fee.satoshis).to eq(0.0)
        expect(payment.purpose).to eq('payment')
        expect(payment.secret.preimage.class).to eq(String)
        expect(payment.secret.preimage.size).to eq(64)
        expect(payment.secret.hash).to eq('3dadfa4f573b96e2b80a530fa6b5923869f9b22666d29cb7be79ef4be7ed028f')

        expect(payment.invoice._key.size).to eq(64)
        expect(payment.invoice.created_at).to be_a(Time)
        expect(payment.invoice.created_at.utc.to_s).to eq('2023-03-12 16:01:16 UTC')
        expect(payment.invoice.settled_at).to be_a(Time)
        expect(payment.invoice.settled_at.utc.to_s).to eq('2023-03-12 16:01:56 UTC')
        expect(payment.invoice.state).to be_nil
        expect(payment.invoice.code).to eq(invoice_code)
        expect(payment.invoice.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.invoice.amount.satoshis).to eq(amount.satoshis)
        expect(payment.invoice.secret.preimage.class).to eq(String)
        expect(payment.invoice.secret.preimage.size).to eq(64)
        expect(payment.invoice.secret.hash).to eq('3dadfa4f573b96e2b80a530fa6b5923869f9b22666d29cb7be79ef4be7ed028f')
        expect(payment.invoice.description.memo).to eq('ab')
        expect(payment.invoice.description.hash).to be_nil

        expect(payment.hops.size).to eq(2)

        expect(payment.from.first?).to be(true)
        expect(payment.from.last?).to be(false)
        expect(payment.from.hop).to eq(1)
        expect(payment.from.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.from.amount.satoshis).to eq(amount.satoshis)
        expect(payment.from.fee.millisatoshis).to eq(0)
        expect(payment.from.fee.satoshis).to eq(0)
        expect(payment.from.channel._key.size).to eq(64)
        expect(payment.from.channel.id).to eq(from[:channel])
        expect(payment.from.channel.target.alias).to eq(from[:target])
        expect(payment.from.channel.target.public_key.size).to eq(66)
        expect(payment.from.channel.target._key.size).to eq(64)

        expect(payment.hops[0].channel.id).to eq(from[:channel])

        expect(payment.from.channel.exit.alias).to eq(from[:exit])
        expect(payment.from.channel.exit.public_key.size).to eq(66)
        expect(payment.from.channel.exit._key.size).to eq(64)
        expect(payment.from.channel.entry).to be_nil

        expect(payment.to.first?).to be(false)
        expect(payment.to.last?).to be(true)
        expect(payment.to.hop).to eq(2)
        expect(payment.to.amount.millisatoshis).to eq(amount.millisatoshis)
        expect(payment.to.amount.satoshis).to eq(amount.satoshis)
        expect(payment.to.fee.millisatoshis).to eq(0)
        expect(payment.to.fee.satoshis).to eq(0)
        expect(payment.to.channel._key.size).to eq(64)
        expect(payment.to.channel.id).to eq(to[:channel])
        expect(payment.to.channel.target.alias).to eq(to[:target])
        expect(payment.to.channel.target.public_key.size).to eq(66)
        expect(payment.to.channel.target._key.size).to eq(64)

        expect(payment.hops[1].channel.id).to eq(to[:channel])

        expect(payment.to.channel.entry).to be_nil
        expect(payment.to.channel.exit).to be_nil

        expect(payment.invoice.payable).to eq('once')
        expect(payment.invoice.amount.millisatoshis).to eq(49_000)
        expect(payment.message).to eq('yalls test')
        expect(payment.through).to eq('non-amp')
        expect(payment.how).to eq('with-invoice')

        Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end
end

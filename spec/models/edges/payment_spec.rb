# frozen_string_literal: true

require 'json'

require_relative '../../../controllers/payment/all'

require_relative '../../../models/edges/payment'
require_relative '../../../models/satoshis'

require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Payment do
  describe 'all' do
    let(:data) do
      Lighstorm::Controllers::Payment::All.data do |fetch|
        VCR.tape.replay("Controllers::Payment.all/#{secret_hash}") do
          data = fetch.call
          data[:list_payments] = [
            data[:list_payments].find { |payment| payment[:payment_hash] == secret_hash }
          ]
          data
        end
      end
    end

    let(:payment) { described_class.new(data[:data][0]) }

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
        Lighstorm::Controllers::Payment::All.data(fetch: fetch_options) do |fetch|
          VCR.tape.replay("Controllers::Payment.all/#{secret_hash}", fetch: fetch_options) do
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
        Lighstorm::Models::Satoshis.new(millisatoshis: 1000)
      end

      let(:to_h_contract) { '1a9544bc8c09286938c4485fd8ccabb39d376f9d232a6a1187ac69fccaf24640' }

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
        expect(payment.spontaneous?).to be(false)

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
          Lighstorm::Models::Satoshis.new(millisatoshis: 1000)
        end

        let(:to_h_contract) { '0e0b114bdcd118e18f9a6e72de18c5b6c426303063d9a1d3b4a085811a1e9ef2' }

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
          expect(payment.spontaneous?).to be(false)

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
          Lighstorm::Models::Satoshis.new(millisatoshis: 150_000)
        end

        let(:to_h_contract) { '2e13a2f0e7bb93be9a744604c2c3bd9470f661cffc09e9a82903b497c0142187' }

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
          expect(payment.spontaneous?).to be(false)

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
          Lighstorm::Models::Satoshis.new(millisatoshis: 3_050_000_000)
        end

        let(:to_h_contract) { '55c503c34e06ddeefbf969c4ba7110a87011e5540d7443a7ab80a6b06ea0e2b4' }

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
          expect(payment.spontaneous?).to be(false)

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
          Lighstorm::Models::Satoshis.new(millisatoshis: 137_000)
        end

        let(:to_h_contract) { '466c3b2fe3d2c58bcb0355717bc811eb84c48f91c0a8e38633dc36279ac61d39' }

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
          expect(payment.spontaneous?).to be(false)

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
          Lighstorm::Models::Satoshis.new(millisatoshis: 130_000_000)
        end

        let(:to_h_contract) { '8839b3c8d55dcd1bfe27234077042a04e4103f2ca5aa065198b08cef3308491a' }

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
          expect(payment.spontaneous?).to be(false)

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
          Lighstorm::Models::Satoshis.new(millisatoshis: 1200)
        end

        let(:to_h_contract) { '4f0eadc4b3e039d5fcaa66c27e22a8a849654c3bfa9718ee9645d1d2aab0c189' }

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
          expect(payment.spontaneous?).to be(true)

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
          Lighstorm::Models::Satoshis.new(millisatoshis: 1500)
        end

        let(:to_h_contract) { '4f0eadc4b3e039d5fcaa66c27e22a8a849654c3bfa9718ee9645d1d2aab0c189' }

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
          expect(payment.spontaneous?).to be(true)

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
          Lighstorm::Models::Satoshis.new(millisatoshis: 1000)
        end

        let(:to_h_contract) { 'ba9486e85c1d8938a946a30f5716b79a2e90f4ef36361f5574b599a29087fe62' }

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
          expect(payment.spontaneous?).to be(false)

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
          Lighstorm::Models::Satoshis.new(millisatoshis: 1210)
        end

        let(:to_h_contract) { '4d9b450a162f4b198e9fe8d146154efc351183bc66d9c04e755a7a29b352f050' }

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
          expect(payment.spontaneous?).to be(false)

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
          Lighstorm::Models::Satoshis.new(millisatoshis: 1121)
        end

        let(:to_h_contract) { '84d6b3aea1a5bf260e9bf6cc7dccbdd4c3041fde81052083511a0f4f9325104a' }

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
          expect(payment.spontaneous?).to be(false)

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
          Lighstorm::Models::Satoshis.new(millisatoshis: 1278)
        end

        let(:to_h_contract) { '6e5dce9ab7fab68daa6dea2520fff037329354b25ad1fc3ce4b4ce8a21c35c0d' }

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
          expect(payment.spontaneous?).to be(false)

          Contract.expect(payment.to_h, to_h_contract) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end
  end
end

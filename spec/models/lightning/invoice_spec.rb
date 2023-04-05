# frozen_string_literal: true

require 'json'

require_relative '../../../controllers/lightning/invoice'
require_relative '../../../controllers/lightning/invoice/all'
require_relative '../../../controllers/lightning/invoice/find_by_secret_hash'
require_relative '../../../controllers/lightning/invoice/find_by_code'
require_relative '../../../controllers/lightning/invoice/decode'

require_relative '../../../models/lightning/invoice'

require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Model::Lightning::Invoice do
  describe 'all' do
    context 'settled' do
      it 'models' do
        data = Lighstorm::Controller::Lightning::Invoice::All.data(
          Lighstorm::Controller::Lightning::Invoice.components
        ) do |fetch|
          VCR.tape.replay('Controller::Lightning::Invoice.all.last/memo/settled') do
            data = fetch.call

            data[:list_invoices] = [
              data[:list_invoices].reverse.find do |invoice|
                invoice[:memo] != '' && invoice[:state] == :SETTLED
              end
            ]

            data
          end
        end

        invoice = described_class.new(data[0], Lighstorm::Controller::Lightning::Invoice.components)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-01-16 09:29:02 UTC')

        expect(invoice.settled_at).to be_a(Time)
        expect(invoice.settled_at.utc.to_s).to eq('2023-01-16 09:29:17 UTC')

        expect(invoice.state).to eq('settled')

        expect(invoice.code).to eq('lnbc9823420n1p3u2xx7pp50hq2v50jg8zujs9wxqen36t2l9ptw4vsp9egu24sgmv0vkp5rxaqdpvf3hkxctv94fx2cnpd3skucm995unsv3nxsez65mpw3escqzpgxqrrsssp53fgraya36c9x3qugf5cxkls52shxzhflln6k8p7w23amkufwsycs9qyyssqffdlwu4pvvyyzy79jtkcsr97ttqy0c4fr9xrq63akg2fmfxhzruj9lz2wwnzyzmyalf7mu7vmxn3rf4az5w2c03z5axdmdnv423q9cqq62y7jd')
        expect(invoice.amount.millisatoshis).to eq(982_342_000)
        expect(invoice.amount.satoshis).to eq(982_342.0)
        expect(invoice.received.millisatoshis).to eq(982_342_000)
        expect(invoice.description.memo).to eq('Local-Rebalance-982342-Sats')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq('7dc0a651f241c5c940ae303338e96af942b7559009728e2ab046d8f6583419ba')

        Contract.expect(
          invoice.to_h, 'a6d33323703b4c469122201d93662d9cff0f6d720a0f9341a8edbf158b9a4e9f'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end

  describe 'find_by_secret_hash' do
    context 'settled' do
      it 'models' do
        secret_hash = '7dc0a651f241c5c940ae303338e96af942b7559009728e2ab046d8f6583419ba'

        data = Lighstorm::Controller::Lightning::Invoice::FindBySecretHash.data(
          Lighstorm::Controller::Lightning::Invoice.components,
          secret_hash
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data, Lighstorm::Controller::Lightning::Invoice.components)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-01-16 09:29:02 UTC')

        expect(invoice.settled_at).to be_a(Time)
        expect(invoice.settled_at.utc.to_s).to eq('2023-01-16 09:29:17 UTC')

        expect(invoice.state).to eq('settled')

        expect(invoice.code).to eq('lnbc9823420n1p3u2xx7pp50hq2v50jg8zujs9wxqen36t2l9ptw4vsp9egu24sgmv0vkp5rxaqdpvf3hkxctv94fx2cnpd3skucm995unsv3nxsez65mpw3escqzpgxqrrsssp53fgraya36c9x3qugf5cxkls52shxzhflln6k8p7w23amkufwsycs9qyyssqffdlwu4pvvyyzy79jtkcsr97ttqy0c4fr9xrq63akg2fmfxhzruj9lz2wwnzyzmyalf7mu7vmxn3rf4az5w2c03z5axdmdnv423q9cqq62y7jd')
        expect(invoice.amount.millisatoshis).to eq(982_342_000)
        expect(invoice.amount.satoshis).to eq(982_342.0)
        expect(invoice.received.millisatoshis).to eq(982_342_000)
        expect(invoice.description.memo).to eq('Local-Rebalance-982342-Sats')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq('7dc0a651f241c5c940ae303338e96af942b7559009728e2ab046d8f6583419ba')

        expect(invoice.secret.valid_proof?(invoice.secret.proof)).to be(true)

        Contract.expect(
          invoice.to_h, 'a6d33323703b4c469122201d93662d9cff0f6d720a0f9341a8edbf158b9a4e9f'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'open' do
      it 'models' do
        secret_hash = '6fc9ff07f27467fccf827ad138df79a8cac8e333944ccc436be3dfaa3c662234'

        data = Lighstorm::Controller::Lightning::Invoice::FindBySecretHash.data(
          Lighstorm::Controller::Lightning::Invoice.components,
          secret_hash
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data, Lighstorm::Controller::Lightning::Invoice.components)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s.size).to eq(23)

        expect(invoice.settled_at).to be_nil

        expect(invoice.state).to eq('open')

        expect(invoice.code).to start_with('lnbc')
        expect(invoice.code.size).to eq(269)
        expect(invoice.amount.millisatoshis).to eq(1000)
        expect(invoice.amount.satoshis).to eq(1.0)
        expect(invoice.received).to be_nil
        expect(invoice.description.memo).to eq('Coffee')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq(secret_hash)

        Contract.expect(
          invoice.to_h, '9e01749ec3c4124742fd4a2b9ed74c7dc04156adcf23f2564f26313ef1ff07aa'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)

          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end

  describe 'decode' do
    let(:code) do
      'lnbc20n1pjq2ywjpp5qy4mms9xqe7h3uhgtct7gt4qxmx56630xwdgenup9x73ggcsk7lsdqggaexzur9cqzpgxqyz5vqsp5je8mp8d49gvq0hj37jkp6y7vapvsgc6nflehhwpqw0yznclzuuqq9qyyssqt38umwt9wdd09dgejd68v88jnwezr9j2y87pv3yr5yglw77kqk6hn3jv6ue573m003n06r2yfa8yzzyh8zr3rgkkwqg9sf4arv490eqps7h0k9'
    end

    it 'models' do
      data = Lighstorm::Controller::Lightning::Invoice::Decode.data(
        Lighstorm::Controller::Lightning::Invoice.components,
        code
      ) do |fetch|
        VCR.tape.replay("Controller::Lightning::Invoice.decode/#{code}") { fetch.call }
      end

      invoice = described_class.new(data, Lighstorm::Controller::Lightning::Invoice.components)

      expect(invoice._key.size).to eq(64)

      expect(invoice.created_at).to be_a(Time)
      expect(invoice.created_at.utc.to_s).to eq('2023-03-05 22:04:02 UTC')

      expect(invoice.settled_at).to be_nil

      expect(invoice.state).to be_nil

      expect(invoice.code).to eq(code)
      expect(invoice.amount.millisatoshis).to eq(2000)
      expect(invoice.amount.satoshis).to eq(2)
      expect(invoice.received).to be_nil
      expect(invoice.description.memo).to eq('Grape')
      expect(invoice.description.hash).to be_nil
      expect(invoice.secret.preimage).to be_nil
      expect(invoice.secret.hash).to eq('012bbdc0a6067d78f2e85e17e42ea036cd4d6a2f339a8ccf8129bd142310b7bf')

      Contract.expect(
        invoice.to_h, '26c46a85f78133c9f509db56402139f4c70bff937aa27f89729aa352d079e80d'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)

        expect(actual.contract).to eq(expected.contract)
      end
    end
  end

  describe 'kinds of invoice' do
    context 'invalid UTF-8 spontaneous keysend self-payment' do
      it 'models' do
        secret_hash = '95178ac5940c2db18da40992f78fcb45bc60d93980a66bbb2756e5d0488467fa'

        data = Lighstorm::Controller::Lightning::Invoice::FindBySecretHash.data(
          Lighstorm::Controller::Lightning::Invoice.components,
          secret_hash
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data, Lighstorm::Controller::Lightning::Invoice.components)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-03-09 19:55:36 UTC')

        expect(invoice.settled_at).to be_a(Time)
        expect(invoice.settled_at.utc.to_s).to eq('2023-03-09 19:55:36 UTC')

        expect(invoice.state).to eq('settled')

        expect(invoice.code).to be_nil
        expect(invoice.amount.millisatoshis).to eq(1789)
        expect(invoice.amount.satoshis).to eq(1.789)
        expect(invoice.received.millisatoshis).to eq(1789)
        expect(invoice.description.memo).to be_nil
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq(secret_hash)

        expect(invoice.payment.message).to eq('c987da7e8ec04e2ce7d0ce5fd9a26e7d')

        expect { JSON.generate(invoice.to_h) }.not_to raise_error

        Contract.expect(
          invoice.to_h, '4faf68f7ff17c42044973f3a3a8ea371da401625ca2fba5f00bdaaee43cc6169'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'spontaneous keysend self-payment' do
      it 'models' do
        secret_hash = '08ac2953c03578fee7684918398087479b6301ac9384fb67f369184b4e528274'

        data = Lighstorm::Controller::Lightning::Invoice::FindBySecretHash.data(
          Lighstorm::Controller::Lightning::Invoice.components,
          secret_hash
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data, Lighstorm::Controller::Lightning::Invoice.components)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-03-10 11:52:15 UTC')

        expect(invoice.settled_at).to be_a(Time)
        expect(invoice.settled_at.utc.to_s).to eq('2023-03-10 11:52:15 UTC')

        expect(invoice.state).to eq('settled')

        expect(invoice.code).to be_nil
        expect(invoice.amount.millisatoshis).to eq(1500)
        expect(invoice.amount.satoshis).to eq(1.500)
        expect(invoice.received.millisatoshis).to eq(1500)
        expect(invoice.description.memo).to be_nil
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq(secret_hash)

        expect(invoice.payment.message).to eq('spontaneous keysend self-payment')

        Contract.expect(
          invoice.to_h, '4faf68f7ff17c42044973f3a3a8ea371da401625ca2fba5f00bdaaee43cc6169'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'spontaneous amp self-payment' do
      it 'models' do
        secret_hash = '62e4d7f9e3add7b4d28e48d80413f1c600e59ec757f01577902824cdf68dcdb5'

        data = Lighstorm::Controller::Lightning::Invoice::FindBySecretHash.data(
          Lighstorm::Controller::Lightning::Invoice.components,
          secret_hash
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data, Lighstorm::Controller::Lightning::Invoice.components)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-03-11 21:43:38 UTC')

        expect(invoice.settled_at).to be_nil

        expect(invoice.state).to eq('settled')

        expect(invoice.code).to be_nil
        expect(invoice.amount.millisatoshis).to eq(1500)
        expect(invoice.received.millisatoshis).to eq(1500)
        expect(invoice.description.memo).to be_nil
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage).to be_nil
        expect(invoice.secret.hash).to be_nil

        expect { invoice.payment.message }.to raise_error(
          InvoiceMayHaveMultiplePaymentsError,
          'payable: indefinitely, payments: 8'
        )

        expect(invoice.payments.first.at).to be_a(Time)
        expect(invoice.payments.first.at.utc.to_s).to eq('2023-03-11 21:43:38 UTC')
        expect(invoice.payments.first.message).to eq('spontaneous amp self-payment')

        Contract.expect(
          invoice.to_h, 'e016af081caeea0d4547b97741a950d3e4e9ed5e71de1508ab8e21b863a7be86'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'defined amount payable once invoice' do
      it 'models' do
        secret_hash = 'e8bcaeacc407ff1192407cda123ff02768f89f9278a885dbd2e6687c271a89b6'

        data = Lighstorm::Controller::Lightning::Invoice::FindBySecretHash.data(
          Lighstorm::Controller::Lightning::Invoice.components,
          secret_hash
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data, Lighstorm::Controller::Lightning::Invoice.components)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-03-10 21:42:26 UTC')

        expect(invoice.settled_at).to be_a(Time)
        expect(invoice.settled_at.utc.to_s).to eq('2023-03-10 21:42:38 UTC')

        expect(invoice.state).to eq('settled')

        expect(invoice.code).to eq('lnbc12780p1pjqhfzzpp5az72atxyqll3ryjq0ndpy0lsya5038uj0z5gtk7jue58cfc63xmqdqcfahx2gz5d9kk2gzrdanxvet9cqzpgxqyz5vqsp5tw5mwdscy7jhtpjh3wn9lw43q4ffu047f5wnkc2g70fhwwmj7nts9qyyssqrthrhkehvwjx606v6hvhj5uwar7cxk523y0rx8dx4mm5zcavqwpncz2yla64ppk82nwx3xamzlca8kzjudl49mndeqlyzsdzqkj9jkcq74sv8g')
        expect(invoice.amount.millisatoshis).to eq(1278)
        expect(invoice.amount.satoshis).to eq(1.278)
        expect(invoice.received.millisatoshis).to eq(1278)
        expect(invoice.description.memo).to eq('One Time Coffee')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq(secret_hash)

        expect(invoice.payment.message).to eq('paying the coffee')

        Contract.expect(
          invoice.to_h, '47ce40909b22357579629161d58620c5c36faa4d4f514afd94745a3f14b7d253'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'undefined amount payable once invoice' do
      it 'models' do
        secret_hash = '15cf219e3db2b721d1eff89ef64111a7bf4ff2f70ab86bdd2c359248b1f91c0e'

        data = Lighstorm::Controller::Lightning::Invoice::FindBySecretHash.data(
          Lighstorm::Controller::Lightning::Invoice.components,
          secret_hash
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data, Lighstorm::Controller::Lightning::Invoice.components)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-03-10 21:46:23 UTC')

        expect(invoice.settled_at).to be_a(Time)
        expect(invoice.settled_at.utc.to_s).to eq('2023-03-10 21:46:57 UTC')

        expect(invoice.state).to eq('settled')

        expect(invoice.code).to eq('lnbc1pjqhff0pp5zh8jr83ak2mjr500lz00vsg357l5luhhp2uxhhfvxkfy3v0ers8qdqafahx2gz5d9kk2gzzv4jhygz0wpjkucqzpgxqyz5vqsp54dxu84v66rzhmg98uzadgc9hqy7na7jtx62xltdyt0ug8te5w7dq9qyyssqgjl6avmq543x5gfw2zsplvvka7mpv78r8slkw8x5uhyv8lawdsppntn5texwr66vmv590szn5wdqk48vtguhxhvf2zvh58eqj2nmq5gpv54ehd')
        expect(invoice.amount).to be_nil
        expect(invoice.received.millisatoshis).to eq(1121)
        expect(invoice.description.memo).to eq('One Time Beer Open')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq(secret_hash)

        expect(invoice.payment.message).to eq('paying what I want')

        Contract.expect(
          invoice.to_h, 'a9cd278876d5dec062c731ff90497cbbed8b56affd86d366be19dff382d50281'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'undefined amount payable indefinitely invoice' do
      it 'models' do
        invoice_code = 'lnbcrt1pjzjm08pp5faw5se0teuvyck44chs3ara45rm2h5rhw66djasynf2s5uc8fuasdq0g3hkuct5d9hkuuccqzpgxqyz5vqsp5fzsee6yvkg4qnjpy7eeke5c0nkt9gcvredsu6c2x9hrsr3h4cass9q8pqqqssqh2yj4sx2l3sccf3rt9aeum64dj028xt0drflmzmakfdk8hvevwsj26q8sljvy70423n723skexjhqrc4kcx0gx5xumrpqq5cv9jdg0sqzd547p'

        data = Lighstorm::Controller::Lightning::Invoice::FindByCode.data(
          Lighstorm::Controller::Lightning::Invoice.components,
          invoice_code
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Invoice.find_by_code/#{invoice_code}") { fetch.call }
        end

        invoice = described_class.new(data, Lighstorm::Controller::Lightning::Invoice.components)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-04-02 11:58:31 UTC')

        expect(invoice.expires_at).to be_a(Time)
        expect(invoice.expires_at.utc.to_s).to eq('2023-04-03 11:58:31 UTC')

        expect(invoice.settled_at).to be_nil

        expect(invoice.state).to eq('open')

        expect(invoice.code).to eq(invoice_code)
        expect(invoice.amount).to be_nil
        expect(invoice.received.millisatoshis).to eq(2500)
        expect(invoice.description.memo).to eq('Donations')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage).to be_nil
        expect(invoice.secret.hash.size).to eq(64)

        expect(invoice.payments.size).to eq(2)

        expect(invoice.payments.first.at.utc.to_s).to eq('2023-04-02 11:59:27 UTC')
        expect(invoice.payments.first.amount.millisatoshis).to eq(1500)
        expect(invoice.payments.first.from.channel.id).to eq(118_747_255_865_345)
        expect(invoice.payments.first.secret.hash).to eq('4afe3d8c141aacc5ca7604c099e2c7fd10a7ef926aecbdfbb3a0e664a658b290')
        expect(invoice.payments.first.secret.preimage.size).to eq(64)
        expect(invoice.payments.first.message).to be_nil

        expect(invoice.payments.last.at.utc.to_s).to eq('2023-04-02 11:59:21 UTC')
        expect(invoice.payments.last.amount.millisatoshis).to eq(1000)
        expect(invoice.payments.last.from.channel.id).to eq(118_747_255_865_345)
        expect(invoice.payments.last.secret.hash).to eq('4863f8f0d4e2f02787ac4730466eaf96d7770694453e2cf79d13f980deb177d6')
        expect(invoice.payments.last.secret.preimage.size).to eq(64)
        expect(invoice.payments.last.message).to be_nil

        expect(invoice.payments.last.secret.hash).not_to eq(invoice.payments.first.secret.hash)
        expect(invoice.payments.last.secret.preimage).not_to eq(invoice.payments.first.secret.preimage)

        expect(
          invoice.payments.first.amount.millisatoshis + invoice.payments.last.amount.millisatoshis
        ).to eq(invoice.received.millisatoshis)

        Contract.expect(
          invoice.to_h, '8236a81077793f943f64782f41166f41940c193b8f2b35ee6343983d373d9b23'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'defined amount payable indefinitely invoice' do
      it 'models' do
        invoice_code = 'lnbcrt10n1pjzj72lpp55669zd5q66ncp0twj5k2lcsxl2fefpw5vkxa3c6n3x2lwmy5unmsdq6g3hkuct5v5srzgznv96x7umgdycqzpgxqyz5vqsp5xd2ejy5frcf63m80mvzxtpufh6uxrfwnpxskqnm3qu0dy8gumu2q9q8pqqqssqexmhzyyz079u9kpxnpf4mdjtqlcfeflzn8rxjkwpcgp7yyuyn8kjqf2tt2kglk7qayjwxw2ffrmwd2q32tpe6x7lvvlsu2pt4marqxqp58qnvg'

        data = Lighstorm::Controller::Lightning::Invoice::FindByCode.data(
          Lighstorm::Controller::Lightning::Invoice.components,
          invoice_code
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Invoice.find_by_code/#{invoice_code}") { fetch.call }
        end

        invoice = described_class.new(data, Lighstorm::Controller::Lightning::Invoice.components)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-04-02 12:47:27 UTC')

        expect(invoice.settled_at).to be_nil

        expect(invoice.state).to eq('open')

        expect(invoice.code).to eq(invoice_code)
        expect(invoice.amount.millisatoshis).to eq(1000)
        expect(invoice.received.millisatoshis).to eq(2000)
        expect(invoice.description.memo).to eq('Donate 1 Satoshi')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage).to be_nil
        expect(invoice.secret.hash).to eq('a6b4513680d6a780bd6e952cafe206fa939485d4658dd8e3538995f76c94e4f7')

        expect(invoice.payments.first.at.utc.to_s).to eq('2023-04-02 12:48:33 UTC')
        expect(invoice.payments.first.amount.millisatoshis).to eq(1000)
        expect(invoice.payments.first.from.channel.id).to eq(118_747_255_865_345)
        expect(invoice.payments.first.secret.hash).to eq('7d1143ac98d02acde1d7e7e9775699eae1cdaa8913c61ce615ae4c355642a114')
        expect(invoice.payments.first.secret.preimage.size).to eq(64)
        expect(invoice.payments.first.message).to eq('1k going')

        expect(invoice.payments.last.at.utc.to_s).to eq('2023-04-02 12:48:26 UTC')
        expect(invoice.payments.last.amount.millisatoshis).to eq(1000)
        expect(invoice.payments.last.from.channel.id).to eq(118_747_255_865_345)
        expect(invoice.payments.last.secret.hash).to eq('701839749da58863c18cc39550cd0913634d5a57afe3295f1c60c521d5a6f9c7')
        expect(invoice.payments.last.secret.preimage.size).to eq(64)
        expect(invoice.payments.last.message).to eq('+1k going')

        expect(invoice.payments.last.secret.hash).not_to eq(invoice.payments.first.secret.hash)
        expect(invoice.payments.last.secret.preimage).not_to eq(invoice.payments.first.secret.preimage)

        Contract.expect(
          invoice.to_h, '650daa2a462b08b64970f23b719220a9b6e655c5c23da59ec54005cb7a026506'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'expired undefined amount payable indefinitely invoice' do
      let(:secret_hash) { '93ea9358cf63c4edb7bf88a451e6ac57d327dbd355c6814d2644053b8c190faf' }

      it 'models' do
        data = Lighstorm::Controller::Lightning::Invoice::All.data(
          Lighstorm::Controller::Lightning::Invoice.components,
          spontaneous: true
        ) do |fetch|
          VCR.tape.replay('Controller::Lightning::Invoice.all.first/expired-indefinitely') do
            data = fetch.call
            data[:list_invoices] = [data[:list_invoices].find do |invoice|
              invoice[:r_hash].unpack1('H*') == secret_hash
            end]
            data
          end
        end

        invoice = described_class.new(data[0], Lighstorm::Controller::Lightning::Invoice.components)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-03-09 23:04:56 UTC')

        expect(invoice.settled_at).to be_nil

        expect(invoice.state).to eq('settled')

        expect(invoice.code).to eq('lnbc1pjq5escpp5j04fxkx0v0zwmdal3zj9re4v2lfj0k7n2hrgznfxgsznhrqep7hsdq0g3hkuct5d9hkuuccqzpgxqyz5vqsp5pxpdl2ftelf5vf4jqjpvynl3u29py5nmjlfrstvxj73hl0fu56fq9q8pqqqssqaaymvqdetmke004rhlk9dvjkdpy63mgjffve0dnzznm0arce78e4srkausw4grfwwwetazrk99rudt03apt9nxx9k4496usgneknqyqp7rrc5w')
        expect(invoice.amount).to be_nil
        expect(invoice.received.millisatoshis).to eq(7500)
        expect(invoice.description.memo).to eq('Donations')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage).to be_nil
        expect(invoice.secret.hash).to eq(secret_hash)

        expect(invoice.payments.first.at.utc.to_s).to eq('2023-03-10 01:01:38 UTC')
        expect(invoice.payments.first.amount.millisatoshis).to eq(1000)
        expect(invoice.payments.first.from.channel.id).to eq(848_916_435_345_801_217)
        expect(invoice.payments.first.secret.hash).to eq('7aff82949d9ffbbce0ccd517660d30b1de2c5228b43d300b9de0a9145cab2520')
        expect(invoice.payments.first.secret.preimage.size).to eq(64)
        expect(invoice.payments.first.message).to be_nil

        expect(invoice.payments.last.at.utc.to_s).to eq('2023-03-09 23:07:00 UTC')
        expect(invoice.payments.last.amount.millisatoshis).to eq(1000)
        expect(invoice.payments.last.from.channel.id).to eq(850_181_973_150_531_585)
        expect(invoice.payments.last.secret.hash).to eq('edeeb2a6e3fadb9fb803b3fd40cda2667c280fd26d67a18416d85d4ef0cbe284')
        expect(invoice.payments.last.secret.preimage.size).to eq(64)
        expect(invoice.payments.last.message).to be_nil

        expect(invoice.payments.last.secret.hash).not_to eq(invoice.payments.first.secret.hash)
        expect(invoice.payments.last.secret.preimage).not_to eq(invoice.payments.first.secret.preimage)

        Contract.expect(
          invoice.to_h, 'dfee1968d70a1efca9f25ccadfe9dda20eb95b15907862ea7cf5340c8f7f952b'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end

  describe 'find_by_code' do
    context 'settled' do
      let(:code) do
        'lnbc10n1pjqux8spp5e5vr8d2f50et6y2mgvltyynecxzun22y2urzmxuhvwcp9877u4nsdqcxysyxatsyphkvgzrdanxvet9cqzpgxqyz5vqsp5ku00sl5p5r76eu9aw6n7mzny9d94r03hpr69r9uvh9yc074pepds9qyyssq0q79336f9qpdfztfflmkfyzweucsphw008mhh2nmtz2m27vugpsnjay5q5p5p5d0dl2gvakzplg757xw8efu4734lpgr88z2y9t3rjqqgfn9yd'
      end

      it 'models' do
        data = Lighstorm::Controller::Lightning::Invoice::FindByCode.data(
          Lighstorm::Controller::Lightning::Invoice.components,
          code
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Invoice.find_by_code/#{code}") { fetch.call }
        end

        invoice = described_class.new(data, Lighstorm::Controller::Lightning::Invoice.components)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-03-12 18:24:48 UTC')

        expect(invoice.settled_at).to be_a(Time)
        expect(invoice.settled_at.utc.to_s).to eq('2023-03-12 18:41:26 UTC')

        expect(invoice.state).to eq('settled')

        expect(invoice.code).to eq(code)
        expect(invoice.amount.millisatoshis).to eq(1000)
        expect(invoice.amount.satoshis).to eq(1.0)
        expect(invoice.received.millisatoshis).to eq(1000)
        expect(invoice.description.memo).to eq('1 Cup of Coffee')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq('cd1833b549a3f2bd115b433eb21279c185c9a94457062d9b9763b0129fdee567')

        Contract.expect(
          invoice.to_h, 'be05a9d04997ba2b487e5c50924fe42c53becb751874c996908a4ba6419ef146'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'open' do
      it 'models' do
        secret_hash = '6fc9ff07f27467fccf827ad138df79a8cac8e333944ccc436be3dfaa3c662234'

        data = Lighstorm::Controller::Lightning::Invoice::FindBySecretHash.data(
          Lighstorm::Controller::Lightning::Invoice.components,
          secret_hash
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data, Lighstorm::Controller::Lightning::Invoice.components)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s.size).to eq(23)

        expect(invoice.settled_at).to be_nil

        expect(invoice.state).to eq('open')

        expect(invoice.code).to start_with('lnbc')
        expect(invoice.code.size).to eq(269)
        expect(invoice.amount.millisatoshis).to eq(1000)
        expect(invoice.amount.satoshis).to eq(1.0)
        expect(invoice.received).to be_nil
        expect(invoice.description.memo).to eq('Coffee')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq(secret_hash)

        Contract.expect(
          invoice.to_h, '9e01749ec3c4124742fd4a2b9ed74c7dc04156adcf23f2564f26313ef1ff07aa'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)

          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end
end

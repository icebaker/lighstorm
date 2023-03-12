# frozen_string_literal: true

require 'json'

require_relative '../../controllers/invoice/all'
require_relative '../../controllers/invoice/find_by_secret_hash'
require_relative '../../controllers/invoice/find_by_code'
require_relative '../../controllers/invoice/decode'

require_relative '../../models/invoice'

require_relative '../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Invoice do
  describe 'all' do
    context 'settled' do
      it 'models' do
        data = Lighstorm::Controllers::Invoice::All.data do |fetch|
          VCR.tape.replay('Controllers::Invoice.all.last/memo/settled') do
            data = fetch.call

            data[:list_invoices] = [
              data[:list_invoices].reverse.find do |invoice|
                invoice[:memo] != '' && invoice[:state] == :SETTLED
              end
            ]

            data
          end
        end

        invoice = described_class.new(data[0])

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
          invoice.to_h, '8360b42081b5e7716668e8028d8d334a62d4a44064ffe16a1d5779e51e1c2f2d'
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

        data = Lighstorm::Controllers::Invoice::FindBySecretHash.data(secret_hash) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data)

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

        puts invoice.secret.proof
        expect(invoice.secret.valid_proof?(invoice.secret.proof)).to eq(true)
        expect(invoice.secret.valid_proof?('123')).to eq(false)

        Contract.expect(
          invoice.to_h, '8360b42081b5e7716668e8028d8d334a62d4a44064ffe16a1d5779e51e1c2f2d'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'open' do
      it 'models' do
        secret_hash = 'ea5ad6e07b476fecfcc9cb44c73a93bc8acc186efc8e0c658e3fb8541d79511e'

        data = Lighstorm::Controllers::Invoice::FindBySecretHash.data(secret_hash) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s.size).to eq(23)

        expect(invoice.settled_at).to be_nil

        expect(invoice.state).to eq('open')

        expect(invoice.code).to start_with('lnbc')
        expect(invoice.code.size).to eq(267)
        expect(invoice.amount.millisatoshis).to eq(1000)
        expect(invoice.amount.satoshis).to eq(1.0)
        expect(invoice.received).to be_nil
        expect(invoice.description.memo).to eq('Coffee')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq(secret_hash)

        Contract.expect(
          invoice.to_h, 'e206115c9b0709d46e46382eefbc0e25e9e49682dce2aac62f3844e5e8bbb9d5'
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
      data = Lighstorm::Controllers::Invoice::Decode.data(code) do |fetch|
        VCR.tape.replay("Controllers::Invoice.decode/#{code}") { fetch.call }
      end

      invoice = described_class.new(data)

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
        invoice.to_h, '4a13965e8c7a02bf362b9db710a39bc4e4ca8ef3de15a6b2b14cd5681a876201'
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

        data = Lighstorm::Controllers::Invoice::FindBySecretHash.data(secret_hash) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data)

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
          invoice.to_h, '0cbf4cba89284e635e3a3e2d6e7fba1cd73b361ed83a9011574b3312866aefe0'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'spontaneous keysend self-payment' do
      it 'models' do
        secret_hash = '08ac2953c03578fee7684918398087479b6301ac9384fb67f369184b4e528274'

        data = Lighstorm::Controllers::Invoice::FindBySecretHash.data(secret_hash) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data)

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
          invoice.to_h, '0cbf4cba89284e635e3a3e2d6e7fba1cd73b361ed83a9011574b3312866aefe0'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'spontaneous amp self-payment' do
      it 'models' do
        secret_hash = '62e4d7f9e3add7b4d28e48d80413f1c600e59ec757f01577902824cdf68dcdb5'

        data = Lighstorm::Controllers::Invoice::FindBySecretHash.data(secret_hash) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data)

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
          invoice.to_h, '29f189e7af8de3085990c0188005eca209e0e54a0fe4f488176942d3a1cf0df0'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'defined amount payable once invoice' do
      it 'models' do
        secret_hash = 'e8bcaeacc407ff1192407cda123ff02768f89f9278a885dbd2e6687c271a89b6'

        data = Lighstorm::Controllers::Invoice::FindBySecretHash.data(secret_hash) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data)

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
          invoice.to_h, 'e6c08c5b078b5a3800587d419da948fe32a99292c00dbb7a483b54334fadda4e'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'undefined amount payable once invoice' do
      it 'models' do
        secret_hash = '15cf219e3db2b721d1eff89ef64111a7bf4ff2f70ab86bdd2c359248b1f91c0e'

        data = Lighstorm::Controllers::Invoice::FindBySecretHash.data(secret_hash) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data)

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
          invoice.to_h, '1d824aceeeb994793b0a15fadddccdcc346c0ea5c80dfe6c543a480005571a63'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'undefined amount payable indefinitely invoice' do
      it 'models' do
        invoice_code = 'lnbc1pjqeakgpp54n5rsd6x48ku26h6dutr2tvmljjmr85t6apsud8p9ka4pxjd4edsdq4facx2m3qg3hkuct5d9hkucqzpgxqyz5vqsp5kp4klrul4kh8jq7259uenz3gdppmqajcqp54tx9yp6j4p5q4ntks9q8pqqqssq2zn0emqa3emqcaylvst0xxvh9h9qrgdmzwz2vrwhr08fyf7f2qlke3elnsehhyncwd4j5t07k6ln94lrgd49602dj27c3jvpg36ruzqpwktt3h'

        data = Lighstorm::Controllers::Invoice::FindByCode.data(invoice_code) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_code/#{invoice_code}") { fetch.call }
        end

        invoice = described_class.new(data)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-03-11 21:46:48 UTC')

        expect(invoice.expires_at).to be_a(Time)
        expect(invoice.expires_at.utc.to_s).to eq('2023-03-12 21:46:48 UTC')

        expect(invoice.settled_at).to be_nil

        expect(invoice.state).to eq('open')

        expect(invoice.code).to eq('lnbc1pjqeakgpp54n5rsd6x48ku26h6dutr2tvmljjmr85t6apsud8p9ka4pxjd4edsdq4facx2m3qg3hkuct5d9hkucqzpgxqyz5vqsp5kp4klrul4kh8jq7259uenz3gdppmqajcqp54tx9yp6j4p5q4ntks9q8pqqqssq2zn0emqa3emqcaylvst0xxvh9h9qrgdmzwz2vrwhr08fyf7f2qlke3elnsehhyncwd4j5t07k6ln94lrgd49602dj27c3jvpg36ruzqpwktt3h')
        expect(invoice.amount).to be_nil
        expect(invoice.received.millisatoshis).to eq(2555)
        expect(invoice.description.memo).to eq('Open Donation')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage).to be_nil
        expect(invoice.secret.hash.size).to eq(64)

        expect(invoice.payments.size).to eq(2)

        expect(invoice.payments.first.at.utc.to_s).to eq('2023-03-11 21:47:46 UTC')
        expect(invoice.payments.first.amount.millisatoshis).to eq(1345)
        expect(invoice.payments.first.from.channel.id).to eq(850_181_973_150_531_585)
        expect(invoice.payments.first.secret.hash).to eq('b91e9712fbe67eee3f9140b2bacae075d85b9c8c7dd59d761c2a2345f4612409')
        expect(invoice.payments.first.secret.preimage.size).to eq(64)
        expect(invoice.payments.first.message).to eq('happy to help!')

        expect(invoice.payments.last.at.utc.to_s).to eq('2023-03-11 21:47:23 UTC')
        expect(invoice.payments.last.amount.millisatoshis).to eq(1210)
        expect(invoice.payments.last.from.channel.id).to eq(850_181_973_150_531_585)
        expect(invoice.payments.last.secret.hash).to eq('528da8c037b3e11373b4fdeffa3a35dab8d43ab27232f4b8e482dbd31bffa64f')
        expect(invoice.payments.last.secret.preimage.size).to eq(64)
        expect(invoice.payments.last.message).to eq('here we go!')

        expect(invoice.payments.last.secret.hash).not_to eq(invoice.payments.first.secret.hash)
        expect(invoice.payments.last.secret.preimage).not_to eq(invoice.payments.first.secret.preimage)

        expect(
          invoice.payments.first.amount.millisatoshis + invoice.payments.last.amount.millisatoshis
        ).to eq(invoice.received.millisatoshis)

        Contract.expect(
          invoice.to_h, 'b48b759c3c6b2a16ee90fb4c7af9c513616ea1beba17ad817c4ec7591a208149'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'defined amount payable indefinitely invoice' do
      it 'models' do
        invoice_code = 'lnbc10n1pjqeaagpp547hctzgurgxt5gswku6yujyztf5c0mkr4zr7ts5d39vgkmpc0wzsdq6g3hkuct5v5srzgznv96x7umgdycqzpgxqyz5vqsp5zrhkyds6ggxqf5pcwqv6tj74nxwdtesdhfmjaavvp5kjzwn9qyps9q8pqqqssqnp765vtvlkphr8z0842t33xyejfex5eyf7umnsuxew9s2dswx64809rls45lcnpex2vnte50hrm3m4dsvr07603jsgv7tkj2n6r70gcpemuu5p'

        data = Lighstorm::Controllers::Invoice::FindByCode.data(invoice_code) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_code/#{invoice_code}") { fetch.call }
        end

        invoice = described_class.new(data)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-03-11 21:50:32 UTC')

        expect(invoice.settled_at).to be_nil

        expect(invoice.state).to eq('open')

        expect(invoice.code).to eq('lnbc10n1pjqeaagpp547hctzgurgxt5gswku6yujyztf5c0mkr4zr7ts5d39vgkmpc0wzsdq6g3hkuct5v5srzgznv96x7umgdycqzpgxqyz5vqsp5zrhkyds6ggxqf5pcwqv6tj74nxwdtesdhfmjaavvp5kjzwn9qyps9q8pqqqssqnp765vtvlkphr8z0842t33xyejfex5eyf7umnsuxew9s2dswx64809rls45lcnpex2vnte50hrm3m4dsvr07603jsgv7tkj2n6r70gcpemuu5p')
        expect(invoice.amount.millisatoshis).to eq(1000)
        expect(invoice.received.millisatoshis).to eq(2000)
        expect(invoice.description.memo).to eq('Donate 1 Satoshi')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage).to be_nil
        expect(invoice.secret.hash).to eq('afaf85891c1a0cba220eb7344e48825a6987eec3a887e5c28d89588b6c387b85')

        expect(invoice.payments.first.at.utc.to_s).to eq('2023-03-11 21:51:11 UTC')
        expect(invoice.payments.first.amount.millisatoshis).to eq(1000)
        expect(invoice.payments.first.from.channel.id).to eq(850_181_973_150_531_585)
        expect(invoice.payments.first.secret.hash).to eq('072f401abff1bdb3a2bd5c9b486e8176ea1ec4f71eacf1b8b15abff5346e332e')
        expect(invoice.payments.first.secret.preimage.size).to eq(64)
        expect(invoice.payments.first.message).to eq('+1k going')

        expect(invoice.payments.last.at.utc.to_s).to eq('2023-03-11 21:51:01 UTC')
        expect(invoice.payments.last.amount.millisatoshis).to eq(1000)
        expect(invoice.payments.last.from.channel.id).to eq(850_181_973_150_531_585)
        expect(invoice.payments.last.secret.hash).to eq('89436a7fd2644e7b36522ed5beab0c2ff89d2131b076ddd64739d3a089e493c6')
        expect(invoice.payments.last.secret.preimage.size).to eq(64)
        expect(invoice.payments.last.message).to eq('1k going')

        expect(invoice.payments.last.secret.hash).not_to eq(invoice.payments.first.secret.hash)
        expect(invoice.payments.last.secret.preimage).not_to eq(invoice.payments.first.secret.preimage)

        Contract.expect(
          invoice.to_h, '97246af2cdcb78d19b3f7c768f1f794ed0c67888e1fb00931d012e15546ca666'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'expired undefined amount payable indefinitely invoice' do
      let(:secret_hash) { '93ea9358cf63c4edb7bf88a451e6ac57d327dbd355c6814d2644053b8c190faf' }

      it 'models' do
        data = Lighstorm::Controllers::Invoice::All.data(spontaneous: true) do |fetch|
          VCR.tape.replay('Controllers::Invoice.all.first/expired-indefinitely') do
            data = fetch.call
            data[:list_invoices] = [data[:list_invoices].find do |invoice|
              invoice[:r_hash].unpack1('H*') == secret_hash
            end]
            data
          end
        end

        invoice = described_class.new(data[0])

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
          invoice.to_h, '7c314ec3eeeba0fc1de71159b0a0953fbe7972ac2e5bbc96ea97856cab76fa82'
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
        data = Lighstorm::Controllers::Invoice::FindByCode.data(code) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_code/#{code}") { fetch.call }
        end

        invoice = described_class.new(data)

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
          invoice.to_h, '95b6c6e15eea0c9c4f575d6680567ee30d6debf6f0dd2fe6904a409e7f2ef21e'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'open' do
      it 'models' do
        secret_hash = 'ea5ad6e07b476fecfcc9cb44c73a93bc8acc186efc8e0c658e3fb8541d79511e'

        data = Lighstorm::Controllers::Invoice::FindBySecretHash.data(secret_hash) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s.size).to eq(23)

        expect(invoice.settled_at).to be_nil

        expect(invoice.state).to eq('open')

        expect(invoice.code).to start_with('lnbc')
        expect(invoice.code.size).to eq(267)
        expect(invoice.amount.millisatoshis).to eq(1000)
        expect(invoice.amount.satoshis).to eq(1.0)
        expect(invoice.received).to be_nil
        expect(invoice.description.memo).to eq('Coffee')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq(secret_hash)

        Contract.expect(
          invoice.to_h, 'e206115c9b0709d46e46382eefbc0e25e9e49682dce2aac62f3844e5e8bbb9d5'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)

          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end
end

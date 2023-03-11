# frozen_string_literal: true

require 'json'

require_relative '../../controllers/invoice/all'
require_relative '../../controllers/invoice/find_by_secret_hash'
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
        expect(invoice.paid.millisatoshis).to eq(982_342_000)
        expect(invoice.description.memo).to eq('Local-Rebalance-982342-Sats')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq('7dc0a651f241c5c940ae303338e96af942b7559009728e2ab046d8f6583419ba')

        Contract.expect(
          invoice.to_h, 'f10dfd433f5005262ae4ef0912b1a6f630ac5db1542ccd2d482de2cba598954b'
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
        expect(invoice.paid.millisatoshis).to eq(982_342_000)
        expect(invoice.description.memo).to eq('Local-Rebalance-982342-Sats')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq('7dc0a651f241c5c940ae303338e96af942b7559009728e2ab046d8f6583419ba')

        Contract.expect(
          invoice.to_h, 'f10dfd433f5005262ae4ef0912b1a6f630ac5db1542ccd2d482de2cba598954b'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'open' do
      it 'models' do
        secret_hash = 'f1eec36442c3caa6f46eb85894f5778c3ba95d67d08fcf7549af79df6829f0ee'

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
        expect(invoice.paid).to be_nil
        expect(invoice.description.memo).to eq('Coffee')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq(secret_hash)

        Contract.expect(
          invoice.to_h, 'b155d010d473ceeac7a0f782d01520f386884370cce47c52fff288e8efed7b93'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)

          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end

  describe 'decode' do
    let(:request_code) do
      'lnbc20n1pjq2ywjpp5qy4mms9xqe7h3uhgtct7gt4qxmx56630xwdgenup9x73ggcsk7lsdqggaexzur9cqzpgxqyz5vqsp5je8mp8d49gvq0hj37jkp6y7vapvsgc6nflehhwpqw0yznclzuuqq9qyyssqt38umwt9wdd09dgejd68v88jnwezr9j2y87pv3yr5yglw77kqk6hn3jv6ue573m003n06r2yfa8yzzyh8zr3rgkkwqg9sf4arv490eqps7h0k9'
    end

    it 'models' do
      data = Lighstorm::Controllers::Invoice::Decode.data(request_code) do |fetch|
        VCR.tape.replay("Controllers::Invoice.decode/#{request_code}") { fetch.call }
      end

      invoice = described_class.new(data)

      expect(invoice._key.size).to eq(64)

      expect(invoice.created_at).to be_a(Time)
      expect(invoice.created_at.utc.to_s).to eq('2023-03-05 22:04:02 UTC')

      expect(invoice.settled_at).to be_nil

      expect(invoice.state).to be_nil

      expect(invoice.code).to eq(request_code)
      expect(invoice.amount.millisatoshis).to eq(2000)
      expect(invoice.amount.satoshis).to eq(2)
      expect(invoice.paid).to be_nil
      expect(invoice.description.memo).to eq('Grape')
      expect(invoice.description.hash).to be_nil
      expect(invoice.secret.preimage).to be_nil
      expect(invoice.secret.hash).to eq('012bbdc0a6067d78f2e85e17e42ea036cd4d6a2f339a8ccf8129bd142310b7bf')

      Contract.expect(
        invoice.to_h, '52a964699bfc5b4bbb664db7643233a259c9c07e6dec8432a65aba1e2936dacd'
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
        expect(invoice.paid.millisatoshis).to eq(1789)
        expect(invoice.description.memo).to be_nil
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq(secret_hash)

        expect(invoice.payment.message).to eq('c987da7e8ec04e2ce7d0ce5fd9a26e7d')

        expect { JSON.generate(invoice.to_h) }.not_to raise_error

        Contract.expect(
          invoice.to_h, '5a55f6c0d4b0dd07d0590529805e18660f24656c316cff0e0078c80105895f86'
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
        expect(invoice.paid.millisatoshis).to eq(1500)
        expect(invoice.description.memo).to be_nil
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.class).to eq(String)
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq(secret_hash)

        expect(invoice.payment.message).to eq('spontaneous keysend self-payment')

        Contract.expect(
          invoice.to_h, '5a55f6c0d4b0dd07d0590529805e18660f24656c316cff0e0078c80105895f86'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'spontaneous amp self-payment' do
      it 'models' do
        data = Lighstorm::Controllers::Invoice::All.data(spontaneous: true) do |fetch|
          VCR.tape.replay('Controllers::Invoice.all.first/amp') do
            data = fetch.call
            data[:list_invoices] = [data[:list_invoices].first]
            data
          end
        end

        invoice = described_class.new(data[0])

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-03-10 22:27:24 UTC')

        expect(invoice.settled_at).to be_nil

        expect(invoice.state).to eq('settled')

        expect(invoice.code).to be_nil
        expect(invoice.amount.millisatoshis).to eq(1500)
        expect(invoice.paid.millisatoshis).to eq(1500)
        expect(invoice.description.memo).to be_nil
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage).to be_nil
        expect(invoice.secret.hash).to be_nil

        expect { invoice.payment.message }.to raise_error(
          InvoiceMayHaveMultiplePaymentsError,
          'payable: indefinitely, payments: 8'
        )

        expect(invoice.payments.first.at).to be_a(Time)
        expect(invoice.payments.first.at.utc.to_s).to eq('2023-03-10 22:27:24 UTC')
        expect(invoice.payments.first.message).to eq('spontaneous amp self-payment')

        Contract.expect(
          invoice.to_h, 'a8393bc86e900254577bd25a66d3ffb79c038fa0991ec6c797653050af3dc294'
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
        expect(invoice.paid.millisatoshis).to eq(1278)
        expect(invoice.description.memo).to eq('One Time Coffee')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq(secret_hash)

        expect(invoice.payment.message).to eq('paying the coffee')

        Contract.expect(
          invoice.to_h, '97ad213f64c136110b1c67dcd8c489d959e5756edad746ffaf5573835cee5c6d'
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
        expect(invoice.paid.millisatoshis).to eq(1121)
        expect(invoice.description.memo).to eq('One Time Beer Open')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.secret.hash).to eq(secret_hash)

        expect(invoice.payment.message).to eq('paying what I want')

        Contract.expect(
          invoice.to_h, '2bc28f2f2be5b876b83c4b4007147133814fb1b402ee622d52e620d75ae0b27e'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'undefined amount payable indefinitely invoice' do
      it 'models' do
        data = Lighstorm::Controllers::Invoice::All.data(spontaneous: true) do |fetch|
          VCR.tape.replay('Controllers::Invoice.all.first/open-donation') do
            data = fetch.call
            data[:list_invoices] = [data[:list_invoices].first]
            data
          end
        end

        invoice = described_class.new(data[0])

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-03-10 21:49:35 UTC')

        expect(invoice.settled_at).to be_nil

        expect(invoice.state).to eq('settled')

        expect(invoice.code).to eq('lnbc1pjqhf00pp50wcqgps2scm7la8hwegtacadzc7efxh5535uzhqg5vk0cske5klsdq4facx2m3qg3hkuct5d9hkucqzpgxqyz5vqsp54ry4te3hyvkaatzt60qr56z8z8fdvzkr3m2va5g0vpdnzfuawads9q8pqqqssq36wvptehc6tka3d938eh4zrgrhanxmpfk3ptkty0cqjcwcrln609h45252peagstjf527d7y5emhl8m5jh20pdnlqtl7tnhav56zp9cqspw2e3')
        expect(invoice.amount).to be_nil
        expect(invoice.paid.millisatoshis).to eq(2555)
        expect(invoice.description.memo).to eq('Open Donation')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage).to be_nil
        expect(invoice.secret.hash.size).to eq(64)

        expect(invoice.payments.size).to eq(2)

        expect(invoice.payments.first.at.utc.to_s).to eq('2023-03-10 21:50:24 UTC')
        expect(invoice.payments.first.amount.millisatoshis).to eq(1210)
        expect(invoice.payments.first.from.channel.id).to eq(850_181_973_150_531_585)
        expect(invoice.payments.first.secret.hash).to eq('73c41594fe95817ba15dc38acc67a6da800fb627327e0b0145af4de76ed905ce')
        expect(invoice.payments.first.secret.preimage.size).to eq(64)
        expect(invoice.payments.first.message).to eq('here we go!')

        expect(invoice.payments.last.at.utc.to_s).to eq('2023-03-10 21:50:02 UTC')
        expect(invoice.payments.last.amount.millisatoshis).to eq(1345)
        expect(invoice.payments.last.from.channel.id).to eq(850_181_973_150_531_585)
        expect(invoice.payments.last.secret.hash).to eq('87c3e0431a92f2901af7d33907aa73c9dd7b9793f51f8508cfc5a254b9ac096e')
        expect(invoice.payments.last.secret.preimage.size).to eq(64)
        expect(invoice.payments.last.message).to eq('happy to help!')

        expect(invoice.payments.last.secret.hash).not_to eq(invoice.payments.first.secret.hash)
        expect(invoice.payments.last.secret.preimage).not_to eq(invoice.payments.first.secret.preimage)

        expect(
          invoice.payments.first.amount.millisatoshis + invoice.payments.last.amount.millisatoshis
        ).to eq(invoice.paid.millisatoshis)

        Contract.expect(
          invoice.to_h, '763eeeaf406359b1326897007500f3a3e0e1608b74729b1e623074b399c6a6d3'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'defined amount payable indefinitely invoice' do
      it 'models' do
        data = Lighstorm::Controllers::Invoice::All.data(spontaneous: true) do |fetch|
          VCR.tape.replay('Controllers::Invoice.all.first/open-donation-1k') do
            data = fetch.call
            data[:list_invoices] = [data[:list_invoices].first]
            data
          end
        end

        invoice = described_class.new(data[0])

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-03-10 21:58:05 UTC')

        expect(invoice.settled_at).to be_nil

        expect(invoice.state).to eq('settled')

        expect(invoice.code).to eq('lnbc10n1pjqhfldpp502qqwwx8gxks3l0c05uj7a4f072206d2vt7m632nve5l4wzf07hsdqcg3hkuct5v5srz6eqd4ekzarncqzpgxqyz5vqsp5lmj5suzpg93uhk5268lk6axn3gz3dvamcg5n6fcgskr8968spwwq9q8pqqqssq0qced26llyuk3583yrf7yhq4mt89nnd8tnrelm6dmap2gp0wva736ppgdrj9gvl5pvupkm8lvnhx36nkpfjq6seduzjysggcwuv3sgqpynrw75')
        expect(invoice.amount.millisatoshis).to eq(1000)
        expect(invoice.paid.millisatoshis).to eq(2000)
        expect(invoice.description.memo).to eq('Donate 1k msats')
        expect(invoice.description.hash).to be_nil
        expect(invoice.secret.preimage).to be_nil
        expect(invoice.secret.hash).to eq('7a800738c741ad08fdf87d392f76a97f94a7e9aa62fdbd45536669fab8497faf')

        expect(invoice.payments.first.at.utc.to_s).to eq('2023-03-10 22:18:06 UTC')
        expect(invoice.payments.first.amount.millisatoshis).to eq(1000)
        expect(invoice.payments.first.from.channel.id).to eq(850_181_973_150_531_585)
        expect(invoice.payments.first.secret.hash).to eq('b1b1435cd4d931b6ed4b5ffe59f85dcb978be9bbf77efb02723290b75101c839')
        expect(invoice.payments.first.secret.preimage.size).to eq(64)
        expect(invoice.payments.first.message).to eq('+1000')

        expect(invoice.payments.last.at.utc.to_s).to eq('2023-03-10 22:17:40 UTC')
        expect(invoice.payments.last.amount.millisatoshis).to eq(1000)
        expect(invoice.payments.last.from.channel.id).to eq(850_181_973_150_531_585)
        expect(invoice.payments.last.secret.hash).to eq('20e5e8e550f41359b29f6e021c8863d34af46baeba74b88c5792790bc4ea3e7c')
        expect(invoice.payments.last.secret.preimage.size).to eq(64)
        expect(invoice.payments.last.message).to eq('+1000')

        expect(invoice.payments.last.secret.hash).not_to eq(invoice.payments.first.secret.hash)
        expect(invoice.payments.last.secret.preimage).not_to eq(invoice.payments.first.secret.preimage)

        Contract.expect(
          invoice.to_h, '6eda0abb2b4e3c92b72a3b521aee040277a4a57bb1a01c2247de2e6ffa9e9e6b'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end
end

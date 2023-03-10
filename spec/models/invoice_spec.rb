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
          invoice.to_h, 'bea94a6e02e18a9212e0cf0c6335702eb219d7522d3ae955393cc9e27196a8df'
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
          invoice.to_h, 'bea94a6e02e18a9212e0cf0c6335702eb219d7522d3ae955393cc9e27196a8df'
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
          invoice.to_h, '954a1e219d2acf0ce53de8f36c2028813684f9083f476c0dfcd0a6cb7a7f3bd7'
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
        invoice.to_h, 'ae89beb4adf69b2981c59d93e27ad75f908d1012e05c54090c23d63a05c4a343'
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
          invoice.to_h, '836c7bd1e5dbbe34e714db8a1abb1beda1a3cb6755f3347311eadb558bf2a623'
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
          invoice.to_h, '836c7bd1e5dbbe34e714db8a1abb1beda1a3cb6755f3347311eadb558bf2a623'
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
          invoice.to_h, 'c45ba30b5064bf6973dd8390a928624456ffbcfbb488c6eaf2de6fa1e7f9777b'
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
          invoice.to_h, 'b7ec2b48a963cd03b7867c0d09c7ba696698aebd3362874bf6152fce03b3cdee'
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
          invoice.to_h, '141eaa3a9392ae7c29d3a3f83abcde151afb69a8c6dbb46e9006e681169bb179'
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
          invoice.to_h, 'c1b7ac85b592a2fbf88bcbad7d26b41284be1f90e9f53659511246d2f0410037'
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
          invoice.to_h, 'fd97386ad6d515764e0d92715a080b2405cdcbc5ba4265ffa258601630a3a47f'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end
end

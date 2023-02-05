# frozen_string_literal: true

require 'time'
require 'date'

require_relative '../satoshis'

require_relative '../connections/payment_channel'
require_relative '../nodes/node'

module Lighstorm
  module Models
    class Payment
      KIND = :edge

      attr_reader :data

      def self.all(limit: nil, purpose: nil, hops: true)
        last_offset = 0

        payments = []

        loop do
          response = LND.instance.middleware('lightning.list_payments') do
            LND.instance.client.lightning.list_payments(index_offset: last_offset)
          end

          response.payments.each do |raw_payment|
            case purpose
            when 'potential-submarine', 'submarine'
              payments << raw_payment if raw_potential_submarine?(raw_payment)
            when '!potential-submarine', '!submarine'
              payments << raw_payment unless raw_potential_submarine?(raw_payment)
            when 'rebalance'
              payments << raw_payment if raw_rebalance?(raw_payment)
            when '!rebalance'
              payments << raw_payment unless raw_rebalance?(raw_payment)
            when '!payment'
              payments << raw_payment if raw_potential_submarine?(raw_payment) || raw_rebalance?(raw_payment)
            when 'payment'
              payments << raw_payment if !raw_potential_submarine?(raw_payment) && !raw_rebalance?(raw_payment)
            else
              payments << raw_payment
            end
          end

          # Fortunately, payments are sorted in descending order. :)
          break if !limit.nil? && payments.size >= limit

          break if last_offset == response.last_index_offset || last_offset > response.last_index_offset

          last_offset = response.last_index_offset
        end

        payments = payments.sort_by { |raw_payment| -raw_payment.creation_time_ns }

        payments = payments[0..limit - 1] unless limit.nil?

        payments.map do |raw_payment|
          Payment.new(raw_payment, respond_hops: hops)
        end
      end

      def self.first
        all(limit: 1).first
      end

      def self.last
        all.last
      end

      def initialize(raw, respond_hops: true)
        @respond_hops = respond_hops
        @data = { list_payments: { payments: [raw] } }
      end

      def id
        @id ||= @data[:list_payments][:payments].first.payment_hash
      end

      def hash
        @hash ||= @data[:list_payments][:payments].first.payment_hash
      end

      def status
        @status ||= @data[:list_payments][:payments].first.status
      end

      def created_at
        @created_at ||= DateTime.parse(Time.at(@data[:list_payments][:payments].first.creation_date).to_s)
      end

      def amount
        @amount ||= Satoshis.new(
          milisatoshis: @data[:list_payments][:payments].first.value_msat
        )
      end

      def fee
        @fee ||= Satoshis.new(
          milisatoshis: @data[:list_payments][:payments].first.fee_msat
        )
      end

      def purpose
        @purpose ||= Payment.raw_purpose(@data[:list_payments][:payments].first)
      end

      def rebalance?
        return @rebalance unless @rebalance.nil?

        validated_htlcs_number!

        @rebalance = Payment.raw_rebalance?(
          @data[:list_payments][:payments].first
        )

        @rebalance
      end

      def self.raw_rebalance?(raw_payment)
        return false if raw_payment.htlcs.first.route.hops.size <= 2

        destination_public_key = raw_payment.htlcs.first.route.hops.last.pub_key

        Node.myself.public_key == destination_public_key
      end

      def self.raw_purpose(raw_payment)
        return 'potential-submarine' if raw_potential_submarine?(raw_payment)
        return 'rebalance' if raw_rebalance?(raw_payment)

        'payment'
      end

      def self.raw_potential_submarine?(raw_payment)
        raw_payment.htlcs.first.route.hops.size == 1
      end

      def potential_submarine?
        validated_htlcs_number!

        @potential_submarine ||= Payment.raw_potential_submarine?(
          @data[:list_payments][:payments].first
        )
      end

      def validated_htlcs_number!
        return unless @data[:list_payments][:payments].first.htlcs.size > 1

        raise "Unexpected number of HTLCs (#{@data[:list_payments][:payments].first.htlcs.size}) for Payment"
      end

      def from
        return @from if @from

        if @hops
          @from = @hops.first
          return @from
        end

        validated_htlcs_number!

        @from = PaymentChannel.new(
          @data[:list_payments][:payments].first.htlcs.first.route.hops.first,
          1
        )

        @from
      end

      def to
        return @to if @to

        if @hops

          @to = rebalance? ? @hops[@hops.size - 2] : @hops.last
          return @to
        end

        validated_htlcs_number!

        @to = if rebalance?
                PaymentChannel.new(
                  @data[:list_payments][:payments].first.htlcs.first.route.hops[
                    @data[:list_payments][:payments].first.htlcs.first.route.hops.size - 2
                  ],
                  @data[:list_payments][:payments].first.htlcs.first.route.hops.size - 1
                )
              else
                PaymentChannel.new(
                  @data[:list_payments][:payments].first.htlcs.first.route.hops.last,
                  @data[:list_payments][:payments].first.htlcs.first.route.hops.size
                )
              end

        @to
      end

      def hops
        return @hops if @hops

        validated_htlcs_number!

        @hops = @data[:list_payments][:payments].first.htlcs.first.route.hops.map.with_index do |raw_hop, i|
          PaymentChannel.new(raw_hop, i + 1)
        end
      end

      def preload_hops!
        hops
        true
      end

      def to_h
        response = {
          id: id,
          hash: hash,
          created_at: created_at,
          purpose: purpose,
          status: status,
          amount: amount.to_h,
          fee: {
            milisatoshis: fee.milisatoshis,
            parts_per_million: fee.parts_per_million(amount.milisatoshis)
          }
        }

        if @respond_hops
          preload_hops!
          response[:from] = from.to_h
          response[:to] = to.to_h
          response[:hops] = hops.map(&:to_h)
        else
          response[:from] = from.to_h
          response[:to] = to.to_h
        end

        response
      end

      def raw
        {
          list_payments: {
            payments: [@data[:list_payments][:payments].first.to_h]
          }
        }
      end
    end
  end
end

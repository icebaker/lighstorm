# frozen_string_literal: true

require_relative '../../satoshis'
require_relative '../../rate'

require_relative '../../../components/lnd'

module Lighstorm
  module Models
    class Fee
      attr_reader :rate, :base

      def initialize(policy, channel, node)
        @channel = channel
        @policy = policy
        if channel.data[:fee_report] && node.myself?
          @base = Satoshis.new(
            milisatoshis: channel.data[:fee_report][:channel_fees].first.base_fee_msat
          )

          @rate = Rate.new(
            parts_per_million: channel.data[:fee_report][:channel_fees].first.fee_per_mil
          )
        elsif policy.data
          @base = policy.data.fee_base_msat ? Satoshis.new(milisatoshis: policy.data.fee_base_msat) : nil

          @rate = policy.data.fee_rate_milli_msat ? Rate.new(parts_per_million: policy.data.fee_rate_milli_msat) : nil
        end
      end

      def update(params, preview: false)
        chan_point = @channel.data[:get_chan_info].chan_point.split(':')

        # add_message "lnrpc.PolicyUpdateRequest" do
        #   optional :base_fee_msat, :int64, 3
        #   optional :fee_rate, :double, 4
        #   optional :fee_rate_ppm, :uint32, 9
        #   optional :time_lock_delta, :uint32, 5
        #   optional :max_htlc_msat, :uint64, 6
        #   optional :min_htlc_msat, :uint64, 7
        #   optional :min_htlc_msat_specified, :bool, 8
        #   oneof :scope do
        #     optional :global, :bool, 1
        #     optional :chan_point, :message, 2, "lnrpc.ChannelPoint"
        #   end
        # end

        grpc_request = {
          method: :update_channel_policy,
          params: {
            chan_point: {
              funding_txid_str: chan_point[0],
              output_index: chan_point[1].to_i
            },
            fee_rate_ppm: @policy.data.fee_rate_milli_msat,
            base_fee_msat: @policy.data.fee_base_msat,
            time_lock_delta: @policy.data.time_lock_delta,
            max_htlc_msat: @policy.data.max_htlc_msat
          }
        }

        if params[:rate] && params[:rate][:parts_per_million]
          if (params[:rate][:parts_per_million]).negative?
            raise "fee rate can't be negative [#{params[:rate][:parts_per_million]}]"
          end

          grpc_request[:params][:fee_rate_ppm] = params[:rate][:parts_per_million]
        end

        if params[:base] && params[:base][:milisatoshis]
          if (params[:base][:milisatoshis]).negative?
            raise "fee base can't be negative [#{params[:base][:milisatoshis]}]"
          end

          grpc_request[:params][:base_fee_msat] = params[:base][:milisatoshis]
        end

        return grpc_request if preview

        response = LND.instance.middleware("lightning.#{grpc_request[:method]}") do
          LND.instance.client.lightning.send(grpc_request[:method], grpc_request[:params])
        end

        if response.failed_updates.empty?
          @base = Satoshis.new(
            milisatoshis: grpc_request[:params][:base_fee_msat]
          )

          @rate = Rate.new(
            parts_per_million: grpc_request[:params][:fee_rate_ppm]
          )
        end

        response
      end

      def to_h
        {
          base: @base.to_h,
          rate: @rate.to_h
        }
      end
    end
  end
end

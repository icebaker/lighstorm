# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'
require_relative '../../../models/satoshis'
require_relative '../../../models/rate'
require_relative '../../action'

module Lighstorm
  module Controllers
    module Channel
      module UpdateFee
        def self.prepare(policy, transaction, params)
          grpc_request = {
            service: :lightning,
            method: :update_channel_policy,
            params: {
              chan_point: {
                funding_txid_str: transaction[:funding][:id],
                output_index: transaction[:funding][:index]
              },
              base_fee_msat: policy[:fee][:base][:millisatoshis],
              fee_rate_ppm: policy[:fee][:rate][:parts_per_million],
              time_lock_delta: policy[:htlc][:blocks][:delta][:minimum],
              max_htlc_msat: policy[:htlc][:maximum][:millisatoshis],
              min_htlc_msat: policy[:htlc][:minimum][:millisatoshis]
            }
          }

          if params[:rate] && params[:rate][:parts_per_million]
            if (params[:rate][:parts_per_million]).negative?
              raise Errors::NegativeNotAllowedError, "fee rate can't be negative: #{params[:rate][:parts_per_million]}"
            end

            grpc_request[:params][:fee_rate_ppm] = params[:rate][:parts_per_million]
          end

          if params[:base] && params[:base][:millisatoshis]
            if (params[:base][:millisatoshis]).negative?
              raise Errors::NegativeNotAllowedError, "fee base can't be negative: #{params[:base][:millisatoshis]}"
            end

            grpc_request[:params][:base_fee_msat] = params[:base][:millisatoshis]
          end

          grpc_request
        end

        def self.call(grpc_request)
          Lighstorm::Ports::GRPC.send(grpc_request[:service]).send(
            grpc_request[:method], grpc_request[:params]
          ).to_h
        end

        def self.dispatch(grpc_request, &vcr)
          vcr.nil? ? call(grpc_request) : vcr.call(-> { call(grpc_request) }, :dispatch)
        end

        def self.perform(policy, transaction, params, preview: false, &vcr)
          grpc_request = prepare(policy.to_h, transaction.to_h, params)

          return grpc_request if preview

          response = dispatch(grpc_request, &vcr)

          raise UpdateChannelPolicyError.new(nil, response) unless response[:failed_updates].empty?

          token = SecureRandom.hex
          policy.fee.prepare_token!(token)
          policy.fee.base = {
            value: Models::Satoshis.new(millisatoshis: grpc_request[:params][:base_fee_msat]),
            token: token
          }

          token = SecureRandom.hex
          policy.fee.prepare_token!(token)
          policy.fee.rate = {
            value: Models::Rate.new(parts_per_million: grpc_request[:params][:fee_rate_ppm]),
            token: token
          }

          Action::Output.new({ response: response, result: policy })
        end
      end
    end
  end
end

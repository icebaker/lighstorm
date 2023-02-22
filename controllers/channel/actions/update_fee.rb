# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'
require_relative '../../../models/satoshis'
require_relative '../../../models/rate'

module Lighstorm
  module Controllers
    module Channel
      module UpdateFee
        def self.perform(policy, params, preview: false, fake: false)
          grpc_request = {
            service: :lightning,
            method: :update_channel_policy,
            params: {
              chan_point: {
                funding_txid_str: policy.transaction.funding.id,
                output_index: policy.transaction.funding.index
              },
              base_fee_msat: policy.fee.base.milisatoshis,
              fee_rate_ppm: policy.fee.rate.parts_per_million,
              time_lock_delta: policy.htlc.blocks.delta.minimum,
              max_htlc_msat: policy.htlc.maximum.milisatoshis,
              min_htlc_msat: policy.htlc.minimum.milisatoshis
            }
          }

          if params[:rate] && params[:rate][:parts_per_million]
            if (params[:rate][:parts_per_million]).negative?
              raise Errors::NegativeNotAllowedError, "fee rate can't be negative: #{params[:rate][:parts_per_million]}"
            end

            grpc_request[:params][:fee_rate_ppm] = params[:rate][:parts_per_million]
          end

          if params[:base] && params[:base][:milisatoshis]
            if (params[:base][:milisatoshis]).negative?
              raise Errors::NegativeNotAllowedError, "fee base can't be negative: #{params[:base][:milisatoshis]}"
            end

            grpc_request[:params][:base_fee_msat] = params[:base][:milisatoshis]
          end

          return grpc_request if preview

          response = if fake
                       :fake
                     else
                       LND.instance.middleware("lightning.#{grpc_request[:method]}") do
                         LND.instance.client.lightning.send(grpc_request[:method], grpc_request[:params])
                       end
                     end

          raise UpdateChannelPolicyError.new(nil, response) unless fake || response.failed_updates.empty?

          token = SecureRandom.hex
          policy.fee.prepare_token!(token)
          policy.fee.base = {
            value: Models::Satoshis.new(milisatoshis: grpc_request[:params][:base_fee_msat]),
            token: token
          }

          token = SecureRandom.hex
          policy.fee.prepare_token!(token)
          policy.fee.rate = {
            value: Models::Rate.new(parts_per_million: grpc_request[:params][:fee_rate_ppm]),
            token: token
          }

          response
        end
      end
    end
  end
end

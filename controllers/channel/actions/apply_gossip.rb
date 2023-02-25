# frozen_string_literal: true

require 'securerandom'

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'
require_relative '../../../models/edges/channel'
require_relative '../../../adapters/edges/channel'

module Lighstorm
  module Controllers
    module Channel
      module ApplyGossip
        SKIPABLE = [
          '_key',
          '_source',
          'partners/0/_source',
          'partners/0/policy/_source',
          'partners/1/_source',
          'partners/1/policy/_source'
        ].freeze

        NOT_ALLOWED = [
          'id'
        ].freeze

        APPLICABLE = [
          'accounting/capacity/milisatoshis',
          'partners/0/policy/fee/base/milisatoshis',
          'partners/0/state',
          'partners/1/policy/fee/base/milisatoshis',
          'partners/1/state',
          'partners/1/policy/fee/rate/parts_per_million',
          'partners/0/policy/fee/rate/parts_per_million',
          'partners/0/policy/htlc/minimum/milisatoshis',
          'partners/1/policy/htlc/minimum/milisatoshis',
          'partners/0/policy/htlc/maximum/milisatoshis',
          'partners/1/policy/htlc/maximum/milisatoshis',
          'partners/0/policy/htlc/blocks/delta/minimum',
          'partners/1/policy/htlc/blocks/delta/minimum'
        ].freeze

        def self.perform(actual, gossip)
          updated = Models::Channel.new(Adapter::Channel.subscribe_channel_graph(gossip))

          actual_dump = actual.dump
          updated_dump = updated.dump

          if actual.partners.first.node.public_key == updated.partners.last.node.public_key &&
             actual.partners.last.node.public_key == updated.partners.first.node.public_key
            a = updated_dump[:partners][0]
            b = updated_dump[:partners][1]

            updated_dump[:partners][0] = b
            updated_dump[:partners][1] = a
          end

          diff = generate_diff(actual_dump, updated_dump)

          diff.each do |change|
            key = change[:path].join('/')
            next unless NOT_ALLOWED.include?(key)

            raise IncoherentGossipError, "Gossip doesn't belong to this Channel"
          end

          diff.filter do |change|
            key = change[:path].join('/')
            if SKIPABLE.include?(key)
              false
            elsif APPLICABLE.include?(key)
              apply!(actual, key, change)
              true
            else
              raise Lighstorm::Errors::MissingGossipHandlerError, "don't know how to apply '#{key}'"
            end
          end
        end

        def self.apply!(actual, key, change)
          case key
          when 'accounting/capacity/milisatoshis'
            token = SecureRandom.hex
            actual.accounting.prepare_token!(token)
            actual.accounting.capacity = {
              value: Models::Satoshis.new(milisatoshis: change[:to]),
              token: token
            }
          when 'partners/0/policy/htlc/maximum/milisatoshis',
                 'partners/1/policy/htlc/maximum/milisatoshis' then
            policy = actual.partners[change[:path][1]].policy

            token = SecureRandom.hex
            policy.htlc.prepare_token!(token)
            policy.htlc.maximum = {
              value: Models::Satoshis.new(milisatoshis: change[:to]),
              token: token
            }
          when 'partners/0/policy/htlc/minimum/milisatoshis',
                 'partners/1/policy/htlc/minimum/milisatoshis' then
            if actual.partners[change[:path][1]].policy.nil?
              actual.partners[change[:path][1]].policy = Lighstorm::Models::Policy.new({})
            end

            policy = actual.partners[change[:path][1]].policy

            token = SecureRandom.hex
            policy.htlc.prepare_token!(token)
            policy.htlc.minimum = {
              value: Models::Satoshis.new(milisatoshis: change[:to]),
              token: token
            }
          when 'partners/0/policy/htlc/blocks/delta/minimum',
                'partners/1/policy/htlc/blocks/delta/minimum' then
            if actual.partners[change[:path][1]].policy.nil?
              actual.partners[change[:path][1]].policy = Lighstorm::Models::Policy.new({})
            end

            policy = actual.partners[change[:path][1]].policy

            token = SecureRandom.hex
            policy.htlc.blocks.delta.prepare_token!(token)
            policy.htlc.blocks.delta.minimum = {
              value: change[:to],
              token: token
            }
          when 'partners/0/policy/fee/rate/parts_per_million',
                 'partners/1/policy/fee/rate/parts_per_million' then
            policy = actual.partners[change[:path][1]].policy

            token = SecureRandom.hex
            policy.fee.prepare_token!(token)
            policy.fee.rate = {
              value: Models::Rate.new(parts_per_million: change[:to]),
              token: token
            }
          when 'partners/0/policy/fee/base/milisatoshis',
                 'partners/1/policy/fee/base/milisatoshis' then
            policy = actual.partners[change[:path][1]].policy

            token = SecureRandom.hex
            policy.fee.prepare_token!(token)
            policy.fee.base = {
              value: Models::Satoshis.new(milisatoshis: change[:to]),
              token: token
            }
          when 'partners/0/state',
               'partners/1/state' then
            partner = actual.partners[change[:path][1]]

            token = SecureRandom.hex
            partner.prepare_token!(token)
            partner.state = { value: change[:to], token: token }
          else
            raise Lighstorm::Errors::MissingGossipHandlerError, "don't know how to apply '#{key}'"
          end
        end

        def self.generate_diff(actual, node, path = [], diff = [])
          case node
          when Hash
            result = {}
            node.each_key do |key|
              result[key] = generate_diff(actual, node[key], path.dup.push(key), diff)
            end
          when Array
            result = []
            node.each_with_index do |value, i|
              result << generate_diff(actual, value, path.dup.push(i), diff)
            end
          else
            new_value = node

            unless new_value.nil?
              actual_value = actual
              path.each do |key|
                if actual_value[key]
                  actual_value = actual_value[key]
                else
                  actual_value = nil
                  break
                end
              end

              diff << { path: path, from: actual_value, to: new_value } if actual_value != new_value
            end
          end

          diff
        end
      end
    end
  end
end

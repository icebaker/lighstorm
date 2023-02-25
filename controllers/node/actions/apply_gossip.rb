# frozen_string_literal: true

require 'securerandom'

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'
require_relative '../../../models/nodes/node'
require_relative '../../../adapters/nodes/node'

module Lighstorm
  module Controllers
    module Node
      module ApplyGossip
        SKIPABLE = %w[
          _source
          _key
        ].freeze

        NOT_ALLOWED = [
          'public_key'
        ].freeze

        APPLICABLE = %w[
          alias
          color
        ].freeze

        def self.perform(actual, gossip)
          updated = Models::Node.new(Adapter::Node.subscribe_channel_graph(gossip))

          actual_dump = actual.dump
          updated_dump = updated.dump

          diff = generate_diff(actual_dump, updated_dump)

          diff.each do |change|
            key = change[:path].join('/')
            next unless NOT_ALLOWED.include?(key)

            raise IncoherentGossipError, "Gossip doesn't belong to this Node"
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
          when 'alias'
            token = SecureRandom.hex
            actual.prepare_token!(token)
            actual.alias = {
              value: change[:to],
              token: token
            }
          when 'color'
            token = SecureRandom.hex
            actual.prepare_token!(token)
            actual.color = {
              value: change[:to],
              token: token
            }
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

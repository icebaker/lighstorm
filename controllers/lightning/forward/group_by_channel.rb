# frozen_string_literal: true

require 'digest'

require_relative './all'

require_relative '../../../models/lightning/edges/groups/channel_forwards'

module Lighstorm
  module Controller
    module Lightning
      module Forward
        module GroupByChannel
          def self.filter(forwards, hours_ago)
            return forwards if hours_ago.nil?

            forwards.filter do |forward|
              forward_hours_ago = (Time.now - Time.parse(forward[:at].to_s)).to_f / 3600
              forward_hours_ago <= hours_ago
            end
          end

          def self.group(forwards, direction)
            groups = {}

            forwards.each do |forward|
              key = forward[direction][:channel][:id]
              groups[key] = [] unless groups.key?(key)
              groups[key] << forward
            end

            groups.values
          end

          def self.analyze(forwards, direction)
            group = {
              last_at: nil,
              analysis: {
                count: 0,
                sums: { amount: { millisatoshis: 0 }, fee: { millisatoshis: 0 } }
              },
              channel: nil
            }

            forwards.each do |forward|
              group[:last_at] = forward[:at] if group[:last_at].nil? || forward[:at] > group[:last_at]

              group[:channel] = forward[direction][:channel] if group[:channel].nil?

              group[:analysis][:count] += 1
              group[:analysis][:sums][:amount][:millisatoshis] += forward[:in][:amount][:millisatoshis]
              group[:analysis][:sums][:fee][:millisatoshis] += forward[:fee][:millisatoshis]
            end

            group[:_key] = _key(group)

            group
          end

          def self._key(group)
            Digest::SHA256.hexdigest(
              [group[:last_at], group[:analysis][:count], group[:channel][:id]].join('/')
            )
          end

          def self.sort(groups)
            groups.sort_by { |group| - Time.parse(group[:last_at].to_s).to_f }
                  .sort_by { |group| - group[:analysis][:count] }
          end

          def self.data(components, direction: :out, hours_ago: nil, limit: nil, &vcr)
            data = All.data(components, &vcr)

            filtered = filter(data, hours_ago)
            groups = group(filtered, direction)
            analyzed = groups.map { |group| analyze(group, direction) }
            sorted = sort(analyzed)

            sorted = sorted[0..limit - 1] unless limit.nil?

            sorted
          end

          def self.model(data)
            data.map { |group| Model::Lightning::ChannelForwardsGroup.new(group) }
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Lighstorm
  module Model
    module Lightning
      class ChannelForwardsGroup
        Analysis = Struct.new(:data) do
          def count
            data[:count]
          end

          def sums
            Struct.new(:sums) do
              def amount
                Satoshis.new(millisatoshis: sums[:amount][:millisatoshis])
              end

              def fee
                Satoshis.new(millisatoshis: sums[:fee][:millisatoshis])
              end

              def to_h
                {
                  amount: amount.to_h,
                  fee: {
                    millisatoshis: fee.millisatoshis,
                    parts_per_million: fee.parts_per_million(amount.millisatoshis)
                  }
                }
              end
            end.new(data[:sums])
          end

          def averages
            Struct.new(:data) do
              def amount
                Satoshis.new(
                  millisatoshis: data[:sums][:amount][:millisatoshis].to_f / data[:count]
                )
              end

              def fee
                Satoshis.new(
                  millisatoshis: data[:sums][:fee][:millisatoshis].to_f / data[:count]
                )
              end

              def to_h
                {
                  amount: amount.to_h,
                  fee: {
                    millisatoshis: fee.millisatoshis,
                    parts_per_million: fee.parts_per_million(amount.millisatoshis)
                  }
                }
              end
            end.new(data)
          end

          def to_h
            {
              count: count,
              sums: sums.to_h,
              averages: averages.to_h
            }
          end
        end
      end
    end
  end
end

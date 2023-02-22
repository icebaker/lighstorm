# frozen_string_literal: true

module Lighstorm
  module Models
    class ChannelForwardsGroup
      Analysis = Struct.new(:data) do
        def count
          data[:count]
        end

        def sums
          Struct.new(:sums) do
            def amount
              Satoshis.new(milisatoshis: sums[:amount][:milisatoshis])
            end

            def fee
              Satoshis.new(milisatoshis: sums[:fee][:milisatoshis])
            end

            def to_h
              {
                amount: amount.to_h,
                fee: {
                  milisatoshis: fee.milisatoshis,
                  parts_per_million: fee.parts_per_million(amount.milisatoshis)
                }
              }
            end
          end.new(data[:sums])
        end

        def averages
          Struct.new(:data) do
            def amount
              Satoshis.new(
                milisatoshis: data[:sums][:amount][:milisatoshis].to_f / data[:count]
              )
            end

            def fee
              Satoshis.new(
                milisatoshis: data[:sums][:fee][:milisatoshis].to_f / data[:count]
              )
            end

            def to_h
              {
                amount: amount.to_h,
                fee: {
                  milisatoshis: fee.milisatoshis,
                  parts_per_million: fee.parts_per_million(amount.milisatoshis)
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

# frozen_string_literal: true

module Lighstorm
  module Models
    class ChannelForwardsGroup
      Analysis = Struct.new(:analysis) do
        def count
          analysis[:count]
        end

        def sums
          Struct.new(:sums) do
            def amount
              Satoshis.new(milisatoshis: sums[:amount])
            end

            def fee
              Satoshis.new(milisatoshis: sums[:fee])
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
          end.new(analysis[:sums])
        end

        def averages
          Struct.new(:analysis) do
            def amount
              Satoshis.new(
                milisatoshis: analysis[:sums][:amount].to_f / analysis[:count]
              )
            end

            def fee
              Satoshis.new(
                milisatoshis: analysis[:sums][:fee].to_f / analysis[:count]
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
          end.new(analysis)
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

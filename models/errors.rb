# frozen_string_literal: true

module Lighstorm
  module Errors
    class LighstormError < StandardError; end

    class ToDoError < LighstormError; end

    class ArgumentError < LighstormError; end
    class TooManyArgumentsError < LighstormError; end
    class IncoherentGossipError < LighstormError; end
    class MissingGossipHandlerError < LighstormError; end
    class MissingCredentialsError < LighstormError; end
    class MissingPartsPerMillionError < LighstormError; end
    class MissingTTLError < LighstormError; end
    class NegativeNotAllowedError < LighstormError; end
    class NotYourChannelError < LighstormError; end
    class NotYourNodeError < LighstormError; end
    class OperationNotAllowedError < LighstormError; end
    class UnexpectedNumberOfHTLCsError < LighstormError; end
    class UnknownChannelError < LighstormError; end

    class InvoiceMayHaveMultiplePaymentsError < LighstormError; end

    class PaymentError < LighstormError
      attr_reader :response, :result, :grpc

      def initialize(message, response: nil, result: nil, grpc: nil)
        super(message)
        @response = response
        @result = result
        @grpc = grpc
      end

      def to_h
        output = { message: message }

        output[:response] = response unless response.nil?
        output[:result] = result.to_h unless result.nil?
        output[:grpc] = grpc.message unless grpc.nil?

        output
      end
    end

    class NoRouteFoundError < PaymentError; end
    class AlreadyPaidError < PaymentError; end
    class AmountForNonZeroError < PaymentError; end
    class MissingMillisatoshisError < PaymentError; end

    class UpdateChannelPolicyError < LighstormError
      attr_reader :response

      def initialize(message, response)
        super(message)
        @response = response
      end
    end
  end
end

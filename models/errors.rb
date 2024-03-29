# frozen_string_literal: true

module Lighstorm
  module Errors
    class LighstormError < StandardError
      def initialize(message = nil)
        super(message)
      end

      def to_h
        { class: self.class, message: message }
      end
    end

    class ToDoError < LighstormError; end

    class ArgumentError < LighstormError; end
    class IncoherentGossipError < LighstormError; end
    class InvoiceMayHaveMultiplePaymentsError < LighstormError; end
    class MissingComponentsError < LighstormError; end
    class MissingCredentialsError < LighstormError; end
    class MissingGossipHandlerError < LighstormError; end
    class MissingPartsPerMillionError < LighstormError; end
    class MissingTTLError < LighstormError; end
    class NegativeNotAllowedError < LighstormError; end
    class NotYourChannelError < LighstormError; end
    class NotYourNodeError < LighstormError; end
    class OperationNotAllowedError < LighstormError; end
    class TooManyArgumentsError < LighstormError; end
    class UnknownChannelError < LighstormError; end

    class RequestError < LighstormError
      attr_reader :request, :response, :result, :grpc

      def initialize(message, request: nil, response: nil, result: nil, grpc: nil)
        super(message)
        @request = request
        @response = response
        @result = result
        @grpc = grpc
      end

      def to_h
        output = { class: self.class, message: message }

        output[:request] = request unless request.nil?
        output[:response] = response unless response.nil?
        output[:result] = result.to_h unless result.nil?
        output[:grpc] = { class: grpc.class, message: grpc.message } unless grpc.nil?

        output
      end
    end

    class AmountBelowDustLimitError < RequestError; end
    class NoInvoiceFoundError < RequestError; end
    class UpdateChannelPolicyError < RequestError; end

    class PaymentError < RequestError; end

    class AlreadyPaidError < PaymentError; end
    class AmountForNonZeroError < PaymentError; end
    class MissingMillisatoshisError < PaymentError; end
    class NoRouteFoundError < PaymentError; end
  end
end

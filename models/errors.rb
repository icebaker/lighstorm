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

    class GRPCError < LighstormError
      attr_reader :grpc

      def initialize(message, grpc = nil)
        super(message)
        @grpc = grpc
      end
    end

    class AlreadyPaidError < GRPCError; end
    class AmountForNonZeroError < GRPCError; end
    class MissingMillisatoshisError < GRPCError; end

    class UpdateChannelPolicyError < LighstormError
      attr_reader :response

      def initialize(message, response)
        super(message)
        @response = response
      end
    end
  end
end

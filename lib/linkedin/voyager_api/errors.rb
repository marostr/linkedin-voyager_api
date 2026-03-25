# frozen_string_literal: true

module LinkedIn
  module VoyagerApi
    class Error < StandardError
      attr_reader :status, :body

      def initialize(message = nil, status: nil, body: nil)
        @status = status
        @body = body
        super(message)
      end
    end

    class AuthenticationError < Error; end
    class RateLimitError < Error; end
    class NotFoundError < Error; end
    class ServerError < Error; end
  end
end

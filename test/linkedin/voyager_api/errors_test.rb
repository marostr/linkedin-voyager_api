# frozen_string_literal: true

require "test_helper"

module LinkedIn
  module VoyagerApi
    class ErrorTest < Minitest::Test
      def test_error_inherits_from_standard_error
        assert_operator Error, :<, StandardError
      end

      def test_error_stores_status_and_body
        error = Error.new("something broke", status: 500, body: {"message" => "fail"})
        assert_equal 500, error.status
        assert_equal({"message" => "fail"}, error.body)
        assert_equal "something broke", error.message
      end

      def test_error_defaults_status_and_body_to_nil
        error = Error.new("oops")
        assert_nil error.status
        assert_nil error.body
      end

      def test_authentication_error_inherits_from_error
        assert_operator AuthenticationError, :<, Error
      end

      def test_rate_limit_error_inherits_from_error
        assert_operator RateLimitError, :<, Error
      end

      def test_not_found_error_inherits_from_error
        assert_operator NotFoundError, :<, Error
      end

      def test_server_error_inherits_from_error
        assert_operator ServerError, :<, Error
      end

      def test_all_subclasses_accept_status_and_body
        [AuthenticationError, RateLimitError, NotFoundError, ServerError].each do |klass|
          error = klass.new("msg", status: 401, body: "x")
          assert_equal 401, error.status
          assert_equal "x", error.body
        end
      end
    end
  end
end

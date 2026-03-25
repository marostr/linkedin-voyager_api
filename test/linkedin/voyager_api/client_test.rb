# frozen_string_literal: true

require "test_helper"

module LinkedIn
  module VoyagerApi
    class ClientTest < Minitest::Test
      def setup
        @client = Client.new(
          cookies: {li_at: "AQJtoken123", jsessionid: '"ajax:123456"'}
        )
      end

      def test_requires_cookies
        assert_raises(ArgumentError) { Client.new }
      end

      def test_requires_li_at_cookie
        error = assert_raises(ArgumentError) do
          Client.new(cookies: {jsessionid: '"ajax:123"'})
        end
        assert_match(/li_at/, error.message)
      end

      def test_requires_jsessionid_cookie
        error = assert_raises(ArgumentError) do
          Client.new(cookies: {li_at: "token"})
        end
        assert_match(/jsessionid/, error.message)
      end

      def test_csrf_token_strips_quotes
        assert_equal "ajax:123456", @client.csrf_token
      end

      def test_csrf_token_handles_unquoted_value
        client = Client.new(cookies: {li_at: "tok", jsessionid: "ajax:789"})
        assert_equal "ajax:789", client.csrf_token
      end

      def test_default_headers_match_python_lib
        headers = @client.default_headers

        assert_equal(
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_5) " \
          "AppleWebKit/537.36 (KHTML, like Gecko) " \
          "Chrome/66.0.3359.181 Safari/537.36",
          headers["user-agent"]
        )
        assert_equal "en-AU,en-GB;q=0.9,en-US;q=0.8,en;q=0.7", headers["accept-language"]
        assert_equal "en_US", headers["x-li-lang"]
        assert_equal "2.0.0", headers["x-restli-protocol-version"]
        assert_equal "ajax:123456", headers["csrf-token"]
      end

      def test_base_url
        assert_equal "https://www.linkedin.com/voyager/api", Client::API_BASE_URL
      end

      def test_accepts_optional_logger
        logger = Logger.new(nil)
        client = Client.new(
          cookies: {li_at: "tok", jsessionid: "ajax:1"},
          logger: logger
        )
        assert_equal logger, client.logger
      end

      def test_default_logger_is_silent
        assert_instance_of Logger, @client.logger
      end
    end

    class ClientErrorHandlingTest < Minitest::Test
      def test_raises_authentication_error_for_401
        assert_raises(AuthenticationError) do
          Client.send(:raise_for_status, mock_response(401, "Unauthorized"))
        end
      end

      def test_raises_authentication_error_for_403
        assert_raises(AuthenticationError) do
          Client.send(:raise_for_status, mock_response(403, "Forbidden"))
        end
      end

      def test_raises_rate_limit_error_for_429
        assert_raises(RateLimitError) do
          Client.send(:raise_for_status, mock_response(429, "Too Many Requests"))
        end
      end

      def test_raises_not_found_error_for_404
        assert_raises(NotFoundError) do
          Client.send(:raise_for_status, mock_response(404, "Not Found"))
        end
      end

      def test_raises_server_error_for_500
        assert_raises(ServerError) do
          Client.send(:raise_for_status, mock_response(500, "Internal Server Error"))
        end
      end

      def test_raises_server_error_for_503
        assert_raises(ServerError) do
          Client.send(:raise_for_status, mock_response(503, "Service Unavailable"))
        end
      end

      def test_does_not_raise_for_200
        Client.send(:raise_for_status, mock_response(200, "OK"))
      end

      def test_error_includes_status_and_body
        error = assert_raises(ServerError) do
          Client.send(:raise_for_status, mock_response(500, '{"message":"fail"}'))
        end
        assert_equal 500, error.status
        assert_equal '{"message":"fail"}', error.body
      end

      private

      def mock_response(code, body)
        response = Object.new
        response.define_singleton_method(:code) { code.to_s }
        response.define_singleton_method(:body) { body }
        response
      end
    end
  end
end

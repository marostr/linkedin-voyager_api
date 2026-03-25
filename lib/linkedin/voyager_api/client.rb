# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "logger"

module LinkedIn
  module VoyagerApi
    class Client
      include Profile

      API_BASE_URL = "https://www.linkedin.com/voyager/api"

      MAX_UPDATE_COUNT = 100
      MAX_REPEATED_REQUESTS = 200

      REQUEST_HEADERS = {
        "user-agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_5) " \
                        "AppleWebKit/537.36 (KHTML, like Gecko) " \
                        "Chrome/66.0.3359.181 Safari/537.36",
        "accept-language" => "en-AU,en-GB;q=0.9,en-US;q=0.8,en;q=0.7",
        "x-li-lang" => "en_US",
        "x-restli-protocol-version" => "2.0.0",
      }.freeze

      attr_reader :logger

      def initialize(cookies:, logger: nil)
        validate_cookies!(cookies)

        @li_at = cookies[:li_at]
        @jsessionid = cookies[:jsessionid]
        @logger = logger || default_logger
      end

      def csrf_token
        @jsessionid.delete('"')
      end

      def default_headers
        REQUEST_HEADERS.merge("csrf-token" => csrf_token)
      end

      def self.raise_for_status(response)
        code = response.code.to_i
        body = response.body

        case code
        when 200..299
          nil
        when 401, 403
          raise AuthenticationError.new("HTTP #{code}", status: code, body: body)
        when 404
          raise NotFoundError.new("HTTP #{code}", status: code, body: body)
        when 429
          raise RateLimitError.new("HTTP #{code}", status: code, body: body)
        when 500..599
          raise ServerError.new("HTTP #{code}", status: code, body: body)
        else
          raise Error.new("HTTP #{code}", status: code, body: body)
        end
      end

      private

      def get(uri, params: {}, headers: {})
        evade

        url = URI("#{API_BASE_URL}#{uri}")
        url.query = URI.encode_www_form(params) unless params.empty?

        request = Net::HTTP::Get.new(url)
        default_headers.merge(headers).each { |k, v| request[k] = v }
        request["cookie"] = cookie_header

        response = execute_request(url, request)
        self.class.raise_for_status(response)

        JSON.parse(response.body)
      end

      def execute_request(url, request)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.request(request)
      end

      def cookie_header
        "li_at=#{@li_at}; JSESSIONID=#{@jsessionid}"
      end

      def evade
        sleep(rand(2..5))
      end

      def validate_cookies!(cookies)
        raise ArgumentError, "li_at cookie is required" unless cookies[:li_at]
        raise ArgumentError, "jsessionid cookie is required" unless cookies[:jsessionid]
      end

      def default_logger
        Logger.new(nil)
      end
    end
  end
end

# frozen_string_literal: true

module LinkedIn
  module VoyagerApi
    module Feed
      NORMALIZED_JSON_HEADER = {"accept" => "application/vnd.linkedin.normalized+json+2.1"}.freeze
      UPDATE_V2_TYPE = "com.linkedin.voyager.feed.render.UpdateV2"

      def home_feed(count: 100, start: 0)
        data = get("/feed/updatesV2",
          params: {count: count, q: "chronFeed", start: start},
          headers: NORMALIZED_JSON_HEADER
        )
        included = data.fetch("included", [])
        included
          .select { |item| item["$type"] == UPDATE_V2_TYPE }
          .filter_map { |update| FeedPost.from_update(update) }
      end

      def profile_posts(public_id: nil, urn_id: nil, post_count: 10)
        identifier = require_identifier(public_id, urn_id)
        profile_urn = "urn:li:fsd_profile:#{identifier}"

        raw = fetch_profile_posts(profile_urn, post_count: post_count)
        raw.filter_map { |update| FeedPost.from_update(update) }
      end

      def company_updates(public_id: nil, urn_id: nil, max_results: nil)
        identifier = require_identifier(public_id, urn_id)
        raw = fetch_feed_updates(
          ->(count, start) { Feed.company_updates_params(identifier, count: count, start: start) },
          max_results: max_results
        )
        raw.filter_map do |element|
          update = element.dig("value", UPDATE_V2_TYPE) || element
          FeedPost.from_update(update)
        end
      end

      module_function

      def company_updates_params(identifier, count:, start:)
        {
          companyUniversalName: identifier,
          q: "companyFeedByUniversalName",
          moduleKey: "member-share",
          count: count,
          start: start,
        }
      end

      def should_stop?(page, results_count:, request_count:, max_results:)
        return true if page.fetch("elements", []).empty?
        return true if max_results && results_count >= max_results
        return true if request_count >= Client::MAX_REPEATED_REQUESTS

        false
      end

      private

      def fetch_profile_posts(profile_urn, post_count:)
        results = []
        pagination_token = nil
        request_count = 0

        loop do
          params = {
            count: [post_count - results.length, Client::MAX_UPDATE_COUNT].min,
            start: results.length,
            q: "memberShareFeed",
            moduleKey: "member-shares:phone",
            includeLongTermHistory: true,
            profileUrn: profile_urn,
          }
          params[:paginationToken] = pagination_token if pagination_token

          data = get("/identity/profileUpdatesV2", params: params)
          request_count += 1

          return [] if data && data["status"] && data["status"] != 200

          elements = data.fetch("elements", [])
          results.concat(elements)

          pagination_token = data.dig("metadata", "paginationToken")
          break if elements.empty?
          break if results.length >= post_count
          break if pagination_token.nil? || pagination_token.empty?
          break if request_count >= Client::MAX_REPEATED_REQUESTS
        end

        results.first(post_count)
      end

      def fetch_feed_updates(params_builder, max_results: nil)
        results = []
        request_count = 0

        loop do
          params = params_builder.call(Client::MAX_UPDATE_COUNT, results.length)
          data = get("/feed/updates", params: params)
          request_count += 1

          return [] if data && data["status"] && data["status"] != 200

          results.concat(data.fetch("elements", []))

          break if Feed.should_stop?(data, results_count: results.length, request_count: request_count, max_results: max_results)
        end

        max_results ? results.first(max_results) : results
      end
    end
  end
end

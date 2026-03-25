# frozen_string_literal: true

module LinkedIn
  module VoyagerApi
    module Feed
      def profile_updates(public_id: nil, urn_id: nil, max_results: nil)
        fetch_feed_updates(
          -> (count, start) { Feed.profile_updates_params(public_id || urn_id, count: count, start: start) },
          max_results: max_results
        )
      end

      def company_updates(public_id: nil, urn_id: nil, max_results: nil)
        fetch_feed_updates(
          -> (count, start) { Feed.company_updates_params(public_id || urn_id, count: count, start: start) },
          max_results: max_results
        )
      end

      def home_feed(count: 100, start: 0)
        get("/feed/updates", params: {count: count, start: start})
      end

      module_function

      def profile_updates_params(identifier, count:, start:)
        {
          profileId: identifier,
          q: "memberShareFeed",
          moduleKey: "member-share",
          count: count,
          start: start,
        }
      end

      def company_updates_params(identifier, count:, start:)
        {
          companyUniversalName: identifier,
          q: "companyFeedByUniversalName",
          moduleKey: "member-share",
          count: count,
          start: start,
        }
      end

      def collect_elements(pages, max_results: nil)
        results = []
        pages.each do |page|
          results.concat(page["elements"])
          break if max_results && results.length >= max_results
        end
        max_results ? results.first(max_results) : results
      end

      def should_stop?(page, results_count:, request_count:, max_results:)
        return true if page["elements"].empty?
        return true if max_results && results_count >= max_results
        return true if request_count >= Client::MAX_REPEATED_REQUESTS

        false
      end

      private

      def fetch_feed_updates(params_builder, max_results: nil)
        results = []
        request_count = 0

        loop do
          params = params_builder.call(Client::MAX_UPDATE_COUNT, results.length)
          data = get("/feed/updates", params: params)
          request_count += 1

          results.concat(data["elements"])

          break if Feed.should_stop?(data, results_count: results.length, request_count: request_count, max_results: max_results)
        end

        max_results ? results.first(max_results) : results
      end
    end
  end
end

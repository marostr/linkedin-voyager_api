# frozen_string_literal: true

require "test_helper"

module LinkedIn
  module VoyagerApi
    class FeedPaginationTest < Minitest::Test
      include FixtureHelper

      def test_should_stop_when_empty_page
        page = load_fixture("feed_updates_empty.json")

        assert Feed.should_stop?(page, results_count: 0, request_count: 1, max_results: nil)
      end

      def test_should_stop_when_max_results_reached
        page = load_fixture("feed_updates_page1.json")

        assert Feed.should_stop?(page, results_count: 5, request_count: 1, max_results: 5)
      end

      def test_should_stop_when_safety_limit_hit
        page = load_fixture("feed_updates_page1.json")

        assert Feed.should_stop?(page, results_count: 50, request_count: 200, max_results: nil)
      end

      def test_should_not_stop_when_more_data_available
        page = load_fixture("feed_updates_page1.json")

        refute Feed.should_stop?(page, results_count: 3, request_count: 1, max_results: nil)
      end

      def test_should_not_stop_when_under_max_results
        page = load_fixture("feed_updates_page1.json")

        refute Feed.should_stop?(page, results_count: 3, request_count: 1, max_results: 10)
      end

      def test_should_stop_when_elements_key_missing
        page = {"status" => 404, "message" => "not found"}

        assert Feed.should_stop?(page, results_count: 0, request_count: 1, max_results: nil)
      end
    end

    class FeedParamsTest < Minitest::Test
      def test_company_updates_params
        params = Feed.company_updates_params("microsoft", count: 100, start: 0)

        assert_equal "microsoft", params[:companyUniversalName]
        assert_equal "companyFeedByUniversalName", params[:q]
        assert_equal "member-share", params[:moduleKey]
        assert_equal 100, params[:count]
        assert_equal 0, params[:start]
      end

      def test_company_updates_params_uses_string_not_set
        params = Feed.company_updates_params("microsoft", count: 100, start: 0)

        assert_instance_of String, params[:companyUniversalName]
      end

      def test_normalized_json_header
        assert_equal(
          "application/vnd.linkedin.normalized+json+2.1",
          Feed::NORMALIZED_JSON_HEADER["accept"]
        )
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module LinkedIn
  module VoyagerApi
    class FeedPaginationTest < Minitest::Test
      include FixtureHelper

      def test_collect_elements_from_single_page
        page = load_fixture("feed_updates_page1.json")
        elements = Feed.collect_elements([page])

        assert_equal 3, elements.length
        assert_equal "update-1", elements[0]["id"]
        assert_equal "update-3", elements[2]["id"]
      end

      def test_collect_elements_from_multiple_pages
        page1 = load_fixture("feed_updates_page1.json")
        page2 = load_fixture("feed_updates_page2.json")
        elements = Feed.collect_elements([page1, page2])

        assert_equal 5, elements.length
        assert_equal "update-5", elements[4]["id"]
      end

      def test_collect_elements_respects_max_results
        page1 = load_fixture("feed_updates_page1.json")
        page2 = load_fixture("feed_updates_page2.json")
        elements = Feed.collect_elements([page1, page2], max_results: 4)

        assert_equal 4, elements.length
      end

      def test_collect_elements_from_empty_page
        page = load_fixture("feed_updates_empty.json")
        elements = Feed.collect_elements([page])

        assert_equal [], elements
      end

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

      def test_profile_updates_params
        params = Feed.profile_updates_params("tom-quirk", count: 100, start: 0)

        assert_equal "tom-quirk", params[:profileId]
        assert_equal "memberShareFeed", params[:q]
        assert_equal "member-share", params[:moduleKey]
        assert_equal 100, params[:count]
        assert_equal 0, params[:start]
      end

      def test_company_updates_params
        params = Feed.company_updates_params("microsoft", count: 100, start: 0)

        assert_equal "microsoft", params[:companyUniversalName]
        assert_equal "companyFeedByUniversalName", params[:q]
        assert_equal "member-share", params[:moduleKey]
        assert_equal 100, params[:count]
        assert_equal 0, params[:start]
      end

      def test_profile_updates_params_uses_string_not_set
        params = Feed.profile_updates_params("tom-quirk", count: 100, start: 0)

        assert_instance_of String, params[:profileId]
      end

      def test_company_updates_params_uses_string_not_set
        params = Feed.company_updates_params("microsoft", count: 100, start: 0)

        assert_instance_of String, params[:companyUniversalName]
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module LinkedIn
  module VoyagerApi
    # Minimal client subclass that stubs network and rate-limit delay
    class StubClient < Client
      attr_reader :requests

      def initialize(responses: [], &block)
        super(cookies: {li_at: "tok", jsessionid: "ajax:1"})
        @responses = responses
        @response_block = block
        @requests = []
      end

      private

      def get(uri, params: {}, headers: {})
        @requests << {uri: uri, params: params}
        if @response_block
          @response_block.call(@requests.length, params)
        else
          @responses.shift || {"included" => []}
        end
      end

      def evade = nil
    end

    class HomeFeedPaginationTest < Minitest::Test
      include FixtureHelper

      def make_page(count, start_id: 0)
        updates = count.times.map do |i|
          id = start_id + i
          {
            "$type" => Feed::UPDATE_V2_TYPE,
            "actor" => {"urn" => "urn:li:member:#{id}", "name" => {"text" => "User #{id}"},
                        "description" => {"text" => "Desc"}, "navigationContext" => {"actionTarget" => "https://example.com"}},
            "commentary" => {"text" => {"text" => "Post #{id}"}},
            "updateMetadata" => {"urn" => "urn:li:fs_updateV2:(urn:li:activity:#{id},MEMBER_SHARES,DEBUG_REASON,DEFAULT,false)",
                                 "shareUrn" => "urn:li:ugcPost:#{id}"},
            "socialDetail" => {"totalSocialActivityCounts" => {"numLikes" => 0, "numComments" => 0, "numShares" => 0, "reactionTypeCounts" => []}},
          }
        end
        {"included" => updates}
      end

      def test_single_page_under_limit
        client = StubClient.new(responses: [make_page(3)])

        posts = client.home_feed(limit: 10)

        assert_equal 3, posts.length
        # 2 requests: first returns 3 posts, second returns empty → stops
        assert_equal 2, client.requests.length
      end

      def test_batches_until_limit_reached
        client = StubClient.new { |req_num, _params|
          make_page(Client::MAX_UPDATE_COUNT, start_id: (req_num - 1) * Client::MAX_UPDATE_COUNT)
        }

        posts = client.home_feed(limit: 250)

        assert_equal 250, posts.length
        assert_equal 3, client.requests.length
      end

      def test_stops_on_empty_page
        client = StubClient.new(responses: [
          make_page(50, start_id: 0),
          {"included" => []},
        ])

        posts = client.home_feed(limit: 200)

        assert_equal 50, posts.length
        assert_equal 2, client.requests.length
      end

      def test_increments_start_offset
        client = StubClient.new(responses: [
          make_page(50, start_id: 0),
          make_page(50, start_id: 50),
        ])

        client.home_feed(limit: 100)

        assert_equal 0, client.requests[0][:params][:start]
        assert_equal 50, client.requests[1][:params][:start]
      end

      def test_uses_batch_size_for_count
        client = StubClient.new(responses: [make_page(3)])

        client.home_feed(limit: 10, batch_size: 50)

        assert_equal 50, client.requests[0][:params][:count]
      end

      def test_default_batch_size
        client = StubClient.new(responses: [make_page(3)])

        client.home_feed(limit: 10)

        assert_equal Feed::HOME_FEED_BATCH_SIZE, client.requests[0][:params][:count]
      end

      def test_retries_once_on_failure
        failed = false
        client = StubClient.new { |req_num, _params|
          if !failed
            failed = true
            raise Error.new("HTTP 500", status: 500, body: "fail")
          else
            make_page(3)
          end
        }

        posts = client.home_feed(limit: 3, retry_delay: 0)

        assert_equal 3, posts.length
      end

      def test_returns_partial_results_on_double_failure
        first_page = make_page(50, start_id: 0)
        batch_2_attempts = 0
        client = StubClient.new { |req_num, _params|
          if req_num == 1
            first_page
          else
            batch_2_attempts += 1
            raise Error.new("HTTP 500", status: 500, body: "fail")
          end
        }

        posts = client.home_feed(limit: 200, retry_delay: 0)

        assert_equal 50, posts.length
        assert_equal 2, batch_2_attempts # original + 1 retry
      end

      def test_stops_at_safety_limit
        client = StubClient.new { |_req_num, _params|
          make_page(1)
        }

        client.home_feed(limit: 999_999)

        assert_equal Client::MAX_REPEATED_REQUESTS, client.requests.length
      end

      def test_filters_non_update_v2_types
        page = make_page(2)
        page["included"] << {"$type" => "com.linkedin.voyager.identity.shared.MiniProfile", "firstName" => "X"}
        client = StubClient.new(responses: [page])

        posts = client.home_feed(limit: 10)

        assert_equal 2, posts.length
        assert(posts.all? { |p| p.is_a?(FeedPost) })
      end

      def test_returns_feed_post_objects
        client = StubClient.new(responses: [make_page(2)])

        posts = client.home_feed(limit: 10)

        assert(posts.all? { |p| p.is_a?(FeedPost) })
        assert_equal "Post 0", posts[0].text
        assert_equal "Post 1", posts[1].text
      end

      def test_backward_compatible_count_parameter
        client = StubClient.new(responses: [make_page(3)])

        posts = client.home_feed(count: 50)

        assert_equal 50, client.requests[0][:params][:count]
        assert_equal 3, posts.length
      end
    end
  end
end

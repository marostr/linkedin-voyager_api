# frozen_string_literal: true

require "test_helper"

module LinkedIn
  module VoyagerApi
    class AuthorTest < Minitest::Test
      include FixtureHelper

      def setup
        @update = load_fixture("feed_update_v2.json")
      end

      def test_from_actor_extracts_name
        author = Author.from_actor(@update["actor"])
        assert_equal "Jane Doe", author.name
      end

      def test_from_actor_extracts_urn
        author = Author.from_actor(@update["actor"])
        assert_equal "urn:li:member:12345", author.urn
      end

      def test_from_actor_extracts_description
        author = Author.from_actor(@update["actor"])
        assert_equal "Senior Engineer at Acme Corp", author.description
      end

      def test_from_actor_extracts_profile_url
        author = Author.from_actor(@update["actor"])
        assert_includes author.profile_url, "linkedin.com/in/janedoe"
      end

      def test_from_actor_returns_nil_for_nil
        assert_nil Author.from_actor(nil)
      end
    end

    class SocialCountsTest < Minitest::Test
      include FixtureHelper

      def setup
        @update = load_fixture("feed_update_v2.json")
      end

      def test_from_social_detail_extracts_likes
        counts = SocialCounts.from_social_detail(@update["socialDetail"])
        assert_equal 42, counts.num_likes
      end

      def test_from_social_detail_extracts_comments
        counts = SocialCounts.from_social_detail(@update["socialDetail"])
        assert_equal 5, counts.num_comments
      end

      def test_from_social_detail_extracts_shares
        counts = SocialCounts.from_social_detail(@update["socialDetail"])
        assert_equal 3, counts.num_shares
      end

      def test_from_social_detail_extracts_reaction_counts
        counts = SocialCounts.from_social_detail(@update["socialDetail"])
        assert_equal 30, counts.reaction_counts["LIKE"]
        assert_equal 8, counts.reaction_counts["PRAISE"]
        assert_equal 4, counts.reaction_counts["EMPATHY"]
      end

      def test_from_social_detail_returns_nil_for_nil
        assert_nil SocialCounts.from_social_detail(nil)
      end

      def test_from_social_detail_handles_missing_counts
        counts = SocialCounts.from_social_detail({})
        assert_equal 0, counts.num_likes
        assert_equal 0, counts.num_comments
        assert_equal 0, counts.num_shares
        assert_equal({}, counts.reaction_counts)
      end
    end

    class FeedPostTest < Minitest::Test
      include FixtureHelper

      def setup
        @update = load_fixture("feed_update_v2.json")
      end

      def test_from_update_extracts_text
        post = FeedPost.from_update(@update)
        assert_equal "Excited to share our latest project! We've been working on something really cool.", post.text
      end

      def test_from_update_extracts_activity_urn
        post = FeedPost.from_update(@update)
        assert_equal "urn:li:activity:7400000000000000001", post.activity_urn
      end

      def test_from_update_extracts_share_urn
        post = FeedPost.from_update(@update)
        assert_equal "urn:li:ugcPost:7400000000000000000", post.share_urn
      end

      def test_from_update_builds_permalink
        post = FeedPost.from_update(@update)
        assert_equal "https://www.linkedin.com/feed/update/urn:li:activity:7400000000000000001", post.permalink
      end

      def test_from_update_extracts_author
        post = FeedPost.from_update(@update)
        assert_equal "Jane Doe", post.author.name
        assert_equal "urn:li:member:12345", post.author.urn
      end

      def test_from_update_extracts_social_counts
        post = FeedPost.from_update(@update)
        assert_equal 42, post.social_counts.num_likes
        assert_equal 5, post.social_counts.num_comments
      end

      def test_from_update_preserves_raw
        post = FeedPost.from_update(@update)
        assert_equal @update, post.raw
      end

      def test_from_update_returns_nil_for_nil
        assert_nil FeedPost.from_update(nil)
      end

      def test_from_update_handles_minimal_data
        minimal = load_fixture("feed_update_v2_minimal.json")
        post = FeedPost.from_update(minimal)

        assert_equal "Bot Account", post.author.name
        assert_nil post.text
        assert_nil post.share_urn
        assert_nil post.social_counts
      end

      def test_feed_post_is_immutable
        post = FeedPost.from_update(@update)
        assert post.frozen?
      end
    end
  end
end

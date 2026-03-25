# frozen_string_literal: true

module LinkedIn
  module VoyagerApi
    Author = Data.define(:name, :urn, :description, :profile_url) do
      def self.from_actor(actor)
        return nil unless actor

        new(
          name: actor.dig("name", "text"),
          urn: actor["urn"],
          description: actor.dig("description", "text"),
          profile_url: actor.dig("navigationContext", "actionTarget"),
        )
      end
    end

    SocialCounts = Data.define(:num_likes, :num_comments, :num_shares, :reaction_counts) do
      def self.from_social_detail(detail)
        return nil unless detail

        counts = detail["totalSocialActivityCounts"] || {}
        new(
          num_likes: counts["numLikes"] || 0,
          num_comments: counts["numComments"] || 0,
          num_shares: counts["numShares"] || 0,
          reaction_counts: (counts["reactionTypeCounts"] || []).to_h { |r| [r["reactionType"], r["count"]] },
        )
      end
    end

    FeedPost = Data.define(:activity_urn, :share_urn, :text, :author, :social_counts, :permalink, :raw) do
      def self.from_update(update)
        return nil unless update

        text = update.dig("commentary", "text", "text")
        meta = update["updateMetadata"] || {}
        activity_urn = meta["urn"]&.then { |u| u[/urn:li:activity:\d+/] }
        permalink = activity_urn ? "https://www.linkedin.com/feed/update/#{activity_urn}" : nil

        new(
          activity_urn: activity_urn,
          share_urn: meta["shareUrn"],
          text: text,
          author: Author.from_actor(update["actor"]),
          social_counts: SocialCounts.from_social_detail(update["socialDetail"]),
          permalink: permalink,
          raw: update,
        )
      end
    end
  end
end

# linkedin-voyager_api

Ruby client for LinkedIn's internal Voyager API. Cookie-based authentication, zero external dependencies.

Provides access to LinkedIn feeds and company data through the same API that powers linkedin.com.

## Installation

Add to your Gemfile:

```ruby
gem "linkedin-voyager_api", path: "/path/to/linkedin-voyagerapi"
```

Requires Ruby 4.0+.

## Authentication

This gem uses cookie-based auth. You need `li_at` and `JSESSIONID` cookies from an authenticated LinkedIn browser session.

To get them: open LinkedIn in your browser, open DevTools > Application > Cookies, and copy the values for `li_at` and `JSESSIONID`.

```ruby
require "linkedin/voyager_api"

client = LinkedIn::VoyagerApi::Client.new(
  cookies: {
    li_at: "AQEDAROh7zI...",
    jsessionid: '"ajax:4330950531968023643"',
  }
)
```

## Usage

### Home Feed

```ruby
posts = client.home_feed(count: 10)

posts.each do |post|
  puts post.author.name        # "Jane Doe"
  puts post.text               # "Excited to share..."
  puts post.permalink           # "https://www.linkedin.com/feed/update/urn:li:activity:..."
  puts post.social_counts.num_likes
end
```

### Profile Posts

Requires an `fsd_profile` URN ID (the fragment after `urn:li:fsd_profile:`).

```ruby
posts = client.profile_posts(urn_id: "ACoAAA123...", post_count: 5)

posts.each do |post|
  puts "#{post.author.name}: #{post.text}"
end
```

### Company Updates

```ruby
posts = client.company_updates(public_id: "linkedin", max_results: 10)

posts.each do |post|
  puts "#{post.author.name}: #{post.text}"
  puts "#{post.social_counts.num_likes} likes, #{post.social_counts.num_comments} comments"
end
```

### Company Data

```ruby
company = client.get_company("linkedin")
puts company["name"]           # "LinkedIn"
puts company["staffCount"]     # 16000
```

## Data Classes

All feed methods return `FeedPost` objects:

| Field | Type | Description |
|-------|------|-------------|
| `text` | `String?` | Post content |
| `author` | `Author?` | Author info |
| `activity_urn` | `String?` | Activity URN |
| `share_urn` | `String?` | Share/UGC post URN |
| `permalink` | `String?` | Direct link to the post |
| `social_counts` | `SocialCounts?` | Likes, comments, shares |
| `raw` | `Hash` | Full original API response |

`Author` fields: `name`, `urn`, `description`, `profile_url`

`SocialCounts` fields: `num_likes`, `num_comments`, `num_shares`, `reaction_counts`

## Error Handling

```ruby
begin
  client.home_feed
rescue LinkedIn::VoyagerApi::AuthenticationError
  # 401/403 — cookies expired or invalid
rescue LinkedIn::VoyagerApi::RateLimitError
  # 429 — too many requests
rescue LinkedIn::VoyagerApi::NotFoundError
  # 404
rescue LinkedIn::VoyagerApi::ServerError
  # 5xx
rescue LinkedIn::VoyagerApi::Error => e
  # anything else
  puts e.status  # HTTP status code
  puts e.body    # response body
end
```

## Rate Limiting

The client sleeps 2-5 seconds (random) before each request to avoid detection, matching the behavior of the Python linkedin-api library this gem is ported from.

## Disclaimer

This gem uses LinkedIn's internal API, which is undocumented and unsupported. LinkedIn may change or disable these endpoints at any time. Use at your own risk. Using this gem may violate LinkedIn's Terms of Service.

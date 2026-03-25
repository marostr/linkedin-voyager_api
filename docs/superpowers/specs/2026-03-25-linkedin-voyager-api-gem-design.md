# LinkedIn Voyager API Ruby Gem — Design Spec

## Goal

Port the core functionality of the Python [linkedin-api](https://github.com/nsandman/linkedin-api) library to a standalone Ruby gem. The gem provides cookie-based access to LinkedIn's internal Voyager API for reading feeds, profiles, and company data.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Auth model | Cookie-based (no login flow) | Caller provides `li_at` + `JSESSIONID`; simpler, avoids storing credentials |
| HTTP library | `net/http` (stdlib) | Zero external dependencies |
| Return types | Ruby `Data` classes | Immutable, self-documenting; raw hashes until real responses are captured |
| Architecture | Layered client with domain modules | Single entry point, clean DX, internal separation of concerns |
| Rate limiting | Built-in random 2–5s sleep | Matches Python lib behavior |
| Test framework | Minitest (stdlib) | Zero-dep, ships with Ruby |
| Ruby version | 4.0.2 via mise | Latest available |
| Logging | Ruby stdlib `Logger`, silent by default | Configurable via `Client.new(logger:)` |
| SSL | Always verify, no debug bypass | Python lib disables verification in debug mode; we won't |

## Scope

### In Scope

- **Authentication** — accept pre-obtained session cookies, construct headers (user-agent, CSRF token, etc.) matching the Python lib exactly
- **Home feed** — retrieve the authenticated user's main feed (**experimental**: not in the Python lib, requires live API discovery to find the correct endpoint/params)
- **Profile feed** — retrieve posts by a specific person
- **Company feed** — retrieve posts by a specific company
- **Profile data** — full profile, contact info, skills, current user (`/me`)
- **Company data** — company details lookup
- **Error handling** — typed exceptions for auth (401/403), rate limiting (429), not found (404), and server errors (5xx)

### Out of Scope

- Login flow (username/password authentication)
- Messaging, connections, invitations
- Search
- Job listings
- School lookups
- Cookie persistence or refresh

## Gem Structure

```
linkedin-voyager_api/
  lib/
    linkedin/
      voyager_api.rb                    # Module definition, version, requires
      voyager_api/
        client.rb                       # Auth, HTTP transport, includes domain modules
        feed.rb                         # Feed module (home, profile, company)
        profile.rb                      # Profile module
        company.rb                      # Company module
        errors.rb                       # Typed error classes
        utils.rb                        # URN parsing, header helpers
  test/
    linkedin/
      voyager_api/
        client_test.rb
        feed_test.rb
        profile_test.rb
        company_test.rb
        utils_test.rb
    fixtures/                           # Captured & sanitized JSON responses
  linkedin-voyager_api.gemspec
  Gemfile
  Rakefile
  .ruby-version
  .mise.toml
```

## Component Design

### Client (`client.rb`)

The `Client` class handles authentication and HTTP transport. Domain modules are mixed in to provide the public API.

```ruby
client = LinkedIn::VoyagerApi::Client.new(
  cookies: { li_at: "AQJ...", jsessionid: "ajax:123..." }
)
```

**Responsibilities:**

- Store cookies; derive CSRF token from `JSESSIONID` (strip surrounding `"` quotes, matching the Python lib's `strip('"')`)
- Set request headers matching the Python lib exactly: user-agent string, `accept-language`, `x-li-lang`, `x-restli-protocol-version`, `csrf-token`
- Base URL: `https://www.linkedin.com/voyager/api`
- Private `#get(uri, params: {}, headers: {})` method (no `#post` — no POST endpoints in scope; add when needed)
- Random 2–5 second sleep before each request (rate-limit evasion)
- Check HTTP response status; raise typed errors for failures
- Parse and return JSON response body
- Accept optional `logger:` argument (Ruby stdlib `Logger`); silent by default
- Always verify SSL certificates

### Errors (`errors.rb`)

```ruby
module LinkedIn
  module VoyagerApi
    class Error < StandardError
      attr_reader :status, :body
    end
    class AuthenticationError < Error; end  # 401, 403
    class RateLimitError < Error; end       # 429
    class NotFoundError < Error; end        # 404
    class ServerError < Error; end          # 5xx
  end
end
```

**Body-status check policy:** Some Voyager responses return HTTP 200 but include a `"status"` key in the JSON body indicating failure (the Python lib checks for this inconsistently). Our policy: single-resource methods (`get_profile`, `get_company`) return `nil` when the body status indicates failure. List methods (`profile_updates`, `company_updates`) return an empty array. This is consistent regardless of which endpoint.

### Feed Module (`feed.rb`)

Mixed into `Client`. All methods return raw hashes initially; `Data` classes added after capturing real responses.

- `#home_feed(count: 100, start: 0)` — user's home feed (**experimental**: endpoint TBD, requires live API testing)
- `#profile_updates(public_id: nil, urn_id: nil, max_results: nil)` — posts by a specific person
- `#company_updates(public_id: nil, urn_id: nil, max_results: nil)` — posts by a specific company

**Pagination:** Recursive calls accumulating `elements` until the page is empty, `max_results` is reached, or the safety limit is hit. Unlike the Python lib (which has a logic error — it divides result count by `max_results` instead of counting requests), the Ruby port uses a proper request counter capped at 200.

**Bug fix from Python lib:** The Python `get_company_updates` and `get_profile_updates` pass `{public_id or urn_id}` (a Python set literal) as a param value. This is a bug. The Ruby port passes the string directly.

### Profile Module (`profile.rb`)

Mixed into `Client`.

- `#get_profile(public_id: nil, urn_id: nil)` — full profile with response transformations (see below)
- `#get_profile_contact_info(public_id: nil, urn_id: nil)` — email, phone, websites, twitter
- `#get_profile_skills(public_id: nil, urn_id: nil)` — skills list
- `#get_user_profile` — current authenticated user via `/me`

**`get_profile` parsing detail:** This method performs significant response transformation, matching the Python lib:

- Extract `displayPictureUrl` from `miniProfile.picture["com.linkedin.common.VectorImage"]["rootUrl"]`
- Extract `profile_id` from `miniProfile.entityUrn` via `id_from_urn`
- Remove `miniProfile`, `defaultLocale`, `supportedLocales`, `versionTag`, `showEducationOnProfileTopCard` keys
- Restructure experience entries: extract `companyLogoUrl` from nested `company.miniCompany.logo`, remove `miniCompany`
- Restructure education entries: extract `logoUrl` from `school.logo`, remove `logo`
- Call `get_profile_skills` internally — this means each `get_profile` call makes **two HTTP requests** (with two sleep delays)

**`get_profile_contact_info` bug fix:** The Python lib has a dead branch (`elif "" in item["type"]`) for `CustomWebsite` that never executes because an empty string is never a dict key. The Ruby port will fix this by checking for the `CustomWebsite` type key correctly.

### Company Module (`company.rb`)

Mixed into `Client`.

- `#get_company(public_id)` — company details via `/organization/companies`

Uses the same `decorationId` parameter and response parsing as the Python lib.

### Utils (`utils.rb`)

- `LinkedIn::VoyagerApi::Utils.id_from_urn(urn)` — extract ID from a LinkedIn URN (e.g., `urn:li:fs_miniProfile:abc` → `abc`)

## Testing Strategy

- **Unit tests for parsing:** Each domain module tested against fixture files containing captured JSON responses. Profile and company fixtures reverse-engineered from the response shapes visible in the Python lib's parsing code. These fixtures may need updating once real responses are captured.
- **Unit tests for pagination:** Synthetic fixture sequences testing all termination conditions: empty page, `max_results` reached, safety limit hit.
- **Unit tests for client internals:** Header construction, CSRF token extraction, cookie handling, URL building, error raising by status code.
- **Unit tests for utils:** URN parsing.
- **No HTTP mocking in integration tests.** Parsing tests use fixture data directly — no HTTP involved.
- **Manual verification:** Marcin tests against real LinkedIn with his credentials.

## Phasing

1. **Client + errors + utils** — auth, HTTP transport, error handling, URN parsing
2. **Profile + company** — full visibility into response parsing from the Python lib
3. **Feed (raw)** — transport layer returning raw hashes; `home_feed` endpoint discovered via live testing
4. **Feed (parsed)** — capture real responses, define `Data` classes, add parsing and fixtures

# Phase 2: LinkedIn Voyager API Client

## Goal

Port the Python [linkedin-api](https://github.com/nsandman/linkedin-api) library to Ruby. The result is a standalone `LinkedIn::VoyagerApi` module in `lib/linkedin/` that can later be extracted as a gem.

## Reference

- Python source: https://github.com/nsandman/linkedin-api
- Namespace: `LinkedIn::VoyagerApi`
- Location: `lib/linkedin/`

## Structure

```
lib/
  linkedin/
    voyager_api.rb          # Main entry point, module definition
    voyager_api/
      client.rb             # Authenticated client (cookie-based auth)
      feed.rb               # Feed fetching (posts from connections/network)
      profile.rb            # Profile data retrieval
      search.rb             # Search functionality (if needed)
      utils.rb              # Shared helpers (headers, parsing)
```

Gem-extractable: own README in `lib/linkedin/`, isolated from Rails dependencies. No ActiveRecord, no Rails helpers — pure Ruby + HTTP.

## What to Port

Study the Python library and port the core functionality we need for Distillery's Ingest pipeline:

1. **Authentication** — cookie-based session auth against LinkedIn's Voyager API. Accept session cookies from the user (stored in Distillery's Source config). Handle auth failures gracefully (expired/invalid cookies).

2. **Feed fetching** — retrieve posts from the user's LinkedIn feed. This is the primary use case. Parse the Voyager API response into clean Ruby objects (author, content, URL, timestamp).

3. **Profile data** — retrieve basic profile info (name, profile URL) for signal authors.

4. **Error handling** — distinguish auth errors (expired cookies) from rate limiting from other failures. Return clear error types the caller can act on.

## What NOT to Port

- Messaging features
- Connection management
- Job search
- Anything not needed for reading feed signals

## Testing

- Unit tests for response parsing using real response fixtures (capture actual Voyager API responses, sanitize PII, use as test data)
- Unit tests for header construction, URL building, cookie handling
- No mocking of the HTTP client in integration-level tests
- Marcin will manually test against real LinkedIn with his credentials

## How to Work

1. Read through the Python library's source code thoroughly
2. Understand the Voyager API endpoints, headers, and auth mechanism
3. Port module by module, starting with auth/client, then feed
4. Use `net/http` or `httpx` for HTTP — no heavy dependencies
5. Write tests alongside each module using captured response fixtures

## Definition of Done

- [ ] `LinkedIn::VoyagerApi::Client` authenticates with session cookies
- [ ] Feed fetching returns parsed post data (author, content, URL, timestamp)
- [ ] Auth errors are distinguishable from other errors
- [ ] All parsing/utility code has unit tests with real response fixtures
- [ ] Code lives in `lib/linkedin/` with no Rails dependencies
- [ ] Marcin has manually verified it works against real LinkedIn

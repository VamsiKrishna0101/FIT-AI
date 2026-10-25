# Exercise library

Male and Female are explicit demonstration filters, independent of exercise eligibility and difficulty. Each filter returns only exercises with a verified matching video variant; counts and pages use the same database predicate. All retains the profile presentation and existing fallback behavior. An explicit selection stays attached when opening details, and detail caches are separated by demo choice. No media or exercise records are deleted by filtering.

Search waits for a short pause in typing, ignores cursor/composing-only changes, and keeps the current list mounted while results load. Pending rows cannot be opened or added until the new results arrive. Request revisions prevent delayed searches from replacing newer results. Account, locale and demo choice are included in request/cache scoping.

Validation: exercise_localization_test.dart covers debounce, cursor-only edits, stale responses, counts, combined filters, reset and detail-cache separation; backend/scripts/test_exercise_pagination.ts checks the active database using read-only requests.

Cache audit: existing PostgreSQL trigram search and browse indexes were checked using read-only EXPLAIN ANALYZE queries. The paginated route now uses a shared Redis cache for 120 seconds, with a catalog revision tag, locale/demo/query/projection keys and concurrent-request deduplication. Redis has a 500 ms no-retry deadline; outages fall back to PostgreSQL. Catalog admin mutations advance the revision so an in-flight old read cannot become a fresh cache hit. Flutter keeps up to 50 page responses for 5 minutes and scopes them to account, language and demo choice. Posters decode at display size; MP4s use the existing 30-day disk cache and a small controller pool.

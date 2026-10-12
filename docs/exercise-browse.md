Exercise browsing uses the existing authenticated `/api/workout/exercises` route
with `page`, `pageSize` (24 by default, capped at 50), `search`, `bodyPart`, and
`equipment`. Requests without pagination retain the existing catalogue response.

The response contains only the requested page, real filtered totals, and distinct
filter options from PostgreSQL. Canonical names and IDs define stable page order;
display names and filter labels follow the selected app language. Search accepts
canonical or translated names and exact translated anatomy/equipment labels.
Search characters are parameterized and SQL wildcard characters remain literal.

Apply backend migration `20261010160000_exercise_browse_indexes` when deploying.
It adds a pg_trgm search index and indexes for page ordering and common filters.
No exercise or user records are removed or replaced.

Train has a labeled Explore exercises card, and adding/replacing an exercise uses
the same paginated library. The library caches up to 50 pages for five minutes,
debounces typing, rejects stale search responses, and resets to page one when a
filter changes. Pull to refresh bypasses its page cache. Posters are loaded only
for rendered rows; animated media stays on the form guide.

Validation: backend `scripts/test_exercise_pagination.ts` reads the real catalogue
without writing records. Flutter `exercise_localization_test.dart` checks paging,
dropdown filters, reset, retry, stale responses, translated names, and small
screens with enlarged text. `training_session_test.dart` checks Train navigation
and all supported translations. Rebuild/restart the backend and hot restart the
Flutter app together when moving from the previous API to this version.

# Equipment

- Guest catalog is a demo of at most 10 items. `loadMore` is a no-op; `count` is the page length so `hasMore` is false.
- Client search paginates with `page` + `itemsPerPage`. Prefer backend `count` for `hasMore`.
- Empty `query` / `city` / `categoryId` (`""` or whitespace) is unset. Search/map init must not refetch when filters already match; map uses `refreshIfStale`. Do not `loadMore` while `isRefreshing`.
- First catalog page uses `locationProvider.city`. Do not load every city when the header already has one (cold start and guest→auth).
- Search screen favorites sit in `FavoritesOverlay` above the nav, not in the catalog list.
- Tapping the already-selected search category clears it: highlight off, spec filters hide, list is unfiltered.
- Spec filters: label is `name, unit`. NUMBER is min/max fields; STRING is text; SELECT/BOOLEAN open a city-style sheet; MULTI_SELECT uses checkboxes + Apply. Search refetches `spec` after 500ms.
- Owner list sends `itemsPerPage: 100`. Spec writes go to `PUT /equipment/:id/spec-values`.
- Owner detail order: photos → general info → category (read-only on edit) → registration → specs → Save all / Submit → delete (`DRAFT` only). Documents and VIN/serial are not in the API — do not stub them.
- General info (`name`, rent/comment, city, prices; after accept also online + AVAILABLE/BOOKED/MAINTENANCE) stays editable. Registration (`model`, `plateNumber`), specs, and the photo camera are only while `isDraft`. After `isModerated` those blocks are read-only (no focus).
- `PATCH /equipment/:id` is not partial — always send current name/model/plate/comment together. The editor merges both info blocks before that PATCH.
- Save-all runs dirty blocks (general, registration, specs). Submit (`PATCH .../status` → `CREATED`) shows when `isDraft` and nothing is dirty. Completeness is persisted data: image, category, name, model, plate, city, price > 0, required specs.

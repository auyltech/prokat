# Equipment

- Guest catalog is a demo of at most 10 items. `loadMore` is a no-op; `count` is the page length so `hasMore` is false.
- Client search paginates with `page` + `itemsPerPage`. Prefer backend `count` for `hasMore`.
- Empty `query` / `city` / `categoryId` (`""` or whitespace) is unset. Search/map init must not refetch when filters already match; map uses `refreshIfStale`. Do not `loadMore` while `isRefreshing`.
- First catalog page uses `locationProvider.city`. Do not load every city when the header already has one (cold start and guest→auth).
- Search screen favorites sit in `FavoritesOverlay` above the nav, not in the catalog list.
- Tapping the already-selected search category clears it: highlight off, spec filters hide, list is unfiltered.
- Spec filters: label is `name, unit`. NUMBER is min/max fields; STRING is text; SELECT/BOOLEAN open a city-style sheet; MULTI_SELECT uses checkboxes + Apply. Search refetches `spec` after 500ms.
- Owner list sends `itemsPerPage: 100`. Spec writes go to `PUT /equipment/:id/spec-values`.
- Owner detail order: photos → category (read-only on edit) → pending/rejected banner → general info → registration → specs → Save all / Submit / Resubmit → delete (`DRAFT` only). Documents and VIN/serial are not in the API — do not stub them.
- `CREATED` is pending review: the whole card is view-only (no photo camera, no field edits, no submit/resubmit).
- `REJECTED` shows a status card under the category row and **Resubmit**, enabled only after at least one field differs from the values loaded at rejection (unsaved dirty or already saved). Resubmit saves dirty blocks then `PATCH .../status` → `CREATED`.
- Submit (`PATCH .../status` → `CREATED`) shows when status is `DRAFT` and nothing is dirty. Completeness is persisted data: image (required), category, name, model, plate, city, price > 0, required specs. Without a photo the button stays disabled.
- General info (`name`, rent/comment, city, prices; after accept also online + AVAILABLE/BOOKED/MAINTENANCE) stays editable except while pending. Registration (`model`, `plateNumber`), specs, and the photo camera are only while `DRAFT` or `REJECTED`. After `isModerated` those blocks are read-only (no focus) and Resubmit never appears.
- `PATCH /equipment/:id` is not partial — always send current name/model/plate/comment together. The editor merges both info blocks before that PATCH.
- Save-all runs dirty blocks (general, registration, specs) for draft and approved cards. Rejected uses Resubmit instead of Save-all.

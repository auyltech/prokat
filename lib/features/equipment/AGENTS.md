# Equipment

- Guest catalog is a demo of at most 10 items. `loadMore` is a no-op; `count` is the page length so `hasMore` is false.
- Client search paginates with `page` + `itemsPerPage`. Prefer backend `count` for `hasMore`.
- Search screen favorites sit in `FavoritesOverlay` above the nav, not in the catalog list.
- Owner list sends `itemsPerPage: 100`. Spec writes go to `PUT /equipment/:id/spec-values`.

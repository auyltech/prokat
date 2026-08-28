# Locations

- Geocoding goes through `GET /locations/search` and `GET /locations/reverse` (auth). The app does not call Mapbox. Backend uses Geocoding v5, `language=ru,kk,en` in one request, `types` `address,place` (search) / `address` (reverse). Stay on v5.
- Pin flow: reverse after camera idle (~600ms), not while dragging. On leave, cancel the debounce and ignore in-flight reverse (`deactivate`); do not `ref.read` / `setState` after that. `autocomplete=true` stays on the search API for later; do not wire `searchLocations` or `AddressSearchSuggestions`.
- Persist `houseNumber` (scalar) and `streetNames` / `cityNames` / `countryNames` (`LocalizedNames`). Canonical `street` / `city` / `country` are typically ru. `comment` is building/entrance, not the house number.
- Display: pick names locally (`locale → ru → en`). Do not refetch on locale change. City: catalog label if the city is in `ServiceCity`, otherwise names from the location.
- Active address: `PATCH /user/profile/address`. 2xx is success even if `data` is null; do not `fromJson(null)`. My Addresses awaits this; the picker sheet does not.
- My Addresses: tap a row to select. Trailing trash deletes (confirm first). No edit button yet. `DELETE /locations/:id` unlinks the profile if that address was primary.
- Proximity: camera coords, or Atyrau from `MapConstants`.

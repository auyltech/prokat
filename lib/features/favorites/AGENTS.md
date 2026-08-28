# Favorites

- `favoritesProvider` holds ids + equipment. Refresh via `getFavorites()`; heart toggles call `toggleFavorite`.
- Catalog Search (`SearchEquipmentScreen`) pins `FavoritesOverlay` to the bottom of the body, above the nav. Do not put this section inside the catalog `ListView` — pagination would hide it.
- Hidden when `favorites` is empty. Otherwise a collapsed header strip; header tap expands just enough for the horizontal card row plus paddings.
- Horizontal card-row scroll does not collapse. Catalog pointer-down, user-drag scroll, search, and category interaction collapse it.
- Header: chevron, title (`titleLarge` like Search), heart count, spacer, `viewAll` (opens `AppRoutes.favorites` and must not toggle the drawer). Heart shows `9+` when count is greater than 9.

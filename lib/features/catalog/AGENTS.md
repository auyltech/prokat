# Catalog

- Channel: `GET /catalog` (bundle + ETag / 304). Facets: `GET /catalog/facets?categoryId=`. Do not refetch on locale change.
- Bundle: `cities`, `categories`, `units`, `specs`, `specOptions`, `categorySpecs`. Links use **id**; filters use **slug**.
- Disk cache: app support via `path_provider` (`catalog/catalog_bundle.json`). Not secure storage. First launch uses `assets/catalog/catalog_bundle.json`.
- Category `imageUrl` values are `/media/user-content/category/...` keys (not Flutter assets, not supabase public URLs). Load them through `OptimizedNetworkImage` / the account media cache.
- `catalogProvider` does not watch `localeProvider`. Names are picked locally from `names` / `symbols`.
- `categoriesProvider` reads this bundle (no extra category HTTP). City pickers use catalog cities only.
- Visible city text uses catalog `names` via `catalogCityLabel` / `catalogCityLabelOf`. Do not show slugs.
- Unknown `Spec.type`: do not render a field and do not drop the stored value.
- Owner spec writes go to `PUT /equipment/:id/spec-values`. Search filters include NUMBER, SELECT, MULTI_SELECT, BOOLEAN and use facets for min/max/options.

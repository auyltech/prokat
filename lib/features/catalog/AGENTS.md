# Catalog

- Channel: `GET /catalog` (bundle + ETag / 304). Do not refetch on locale change.
- Bundle: `cities`, `categories`, `units`, `specs`, `specOptions`, `categorySpecs`. Links use **id**; filters use **slug**.
- Disk cache: app support via `path_provider` (`catalog/catalog_bundle.json`). Not secure storage. First launch uses `assets/catalog/catalog_bundle.json`.
- `catalogProvider` does not watch `localeProvider`. Names are picked locally from `names` / `symbols`.
- `categoriesProvider` reads this bundle (no extra category HTTP). City pickers use catalog cities, with `cities.dart` only if the bundle has none.
- Unknown `Spec.type`: do not render a field and do not drop the stored value.
- Do not delete `cities.dart` or ARB `cityName*` here.

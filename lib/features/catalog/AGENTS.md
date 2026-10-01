# Catalog

- Channel: `GET /catalog` (bundle + ETag / 304). Facets: `GET /catalog/facets?categoryId=`. Do not refetch on locale change.
- Bundle: `cities`, `categories`, `units`, `specs`, `specOptions`, `categorySpecs`. Links use **id**; filters use **slug**.
- Category has `catalogGroup` (`MACHINERY` | `EQUIPMENT`). Absent/unknown → `MACHINERY`. Server ETag is bucket-scoped (`LEGACY:` / `TWO_GROUPS:`).
- Category has localized `descriptions` (ru/en/kk) alongside `names`. Missing/empty → empty string; pick locally like names.
- Disk cache: app support via `path_provider` (`catalog/catalog_bundle.json`). Not secure storage. First launch uses `assets/catalog/catalog_bundle.json`.
- Category `imageUrl` values are `/media/user-content/category/...` keys (not Flutter assets, not supabase public URLs). Load them through `OptimizedNetworkImage` / the account media cache.
- After a catalog bundle is available (`build` / `refresh`), `CatalogNotifier` fire-and-forgets `MediaImagePrefetcher` to warm those URLs in `mediaCacheManager` (disk only, concurrency 3, skip hits). Prefetch must never block or fail catalog load.
- Browse header: `CategoryHeaderCard` (image + name + description + filter stub + expandable search). All-categories uses `AppImages.machineryStd` / `equipmentStd` and l10n description. Picker sheet resets search/filters on pick.
- `catalogProvider` does not watch `localeProvider`. Names/descriptions are picked locally from `names` / `descriptions` / `symbols`.
- `categoriesProvider` reads this bundle (no extra category HTTP). City pickers use catalog cities only.
- Browse selection is **per group** (`browseCatalogGroupProvider` + `selectedBrowseCategoryProvider`). Search UI/query is per group via `browseGroupSessionsProvider` (lazy until first open, sticky after). Client catalog lists are `clientEquipmentProvider(CatalogGroup)`: one request and one state per group. A category or search change reloads only that group. A tab switch does not: `selectedBrowseCategoryProvider` republishes the opened group's category, and that must not call `search` or `GET /favorites`. A city change reloads every group the UI has opened.
- Mutation flows reset category on group switch (`mutationCatalogGroupProvider`).
- Search browse: `AppTabs` under the app bar only when both groups are visible. Title stays «Каталог», tabs «техники» / «оборудования». One group — no tabs, title «Каталог техники» or «Каталог оборудования». Each tab watches only `clientEquipmentProvider(its group)`. Hide a group when that audience has no visible categories (`userVisibleCatalogGroups` / `ownerVisibleCatalogGroups`). Owner fleet tabs use `GET /equipment/owner/catalog-groups`.
- Visible city text uses catalog `names` via `catalogCityLabel` / `catalogCityLabelOf`. Do not show slugs.
- Unknown `Spec.type`: do not render a field and do not drop the stored value.
- Owner spec writes go to `PUT /equipment/:id/spec-values`. Search filters include NUMBER, SELECT, MULTI_SELECT, BOOLEAN and use facets for min/max/options.

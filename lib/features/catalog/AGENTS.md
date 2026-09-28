# Catalog

- Channel: `GET /catalog` (bundle + ETag / 304). Facets: `GET /catalog/facets?categoryId=`. Do not refetch on locale change.
- Bundle: `cities`, `categories`, `units`, `specs`, `specOptions`, `categorySpecs`. Links use **id**; filters use **slug**.
- Category has `catalogGroup` (`MACHINERY` | `EQUIPMENT`). Absent/unknown → `MACHINERY`. Server ETag is bucket-scoped (`LEGACY:` / `TWO_GROUPS:`).
- Category has localized `descriptions` (ru/en/kk) alongside `names`. Missing/empty → empty string; pick locally like names.
- Disk cache: app support via `path_provider` (`catalog/catalog_bundle.json`). Not secure storage. First launch uses `assets/catalog/catalog_bundle.json`.
- Category `imageUrl` values are `/media/user-content/category/...` keys (not Flutter assets, not supabase public URLs). Load them through `OptimizedNetworkImage` / the account media cache.
- Browse header: `CategoryHeaderCard` (image + name + description + filter stub + expandable search). All-categories uses `AppImages.machineryStd` / `equipmentStd` and l10n description. Picker sheet resets search/filters on pick.
- `catalogProvider` does not watch `localeProvider`. Names/descriptions are picked locally from `names` / `descriptions` / `symbols`.
- `categoriesProvider` reads this bundle (no extra category HTTP). City pickers use catalog cities only.
- Browse selection is **per group** (`browseCatalogGroupProvider` + `selectedBrowseCategoryProvider`). Search UI/query is per group via `browseGroupSessionsProvider` (lazy until first open, sticky after). Equipment list notifiers keep a per-group snapshot cache so tab switches restore content without refetch when filters match.
- Mutation flows reset category on group switch (`mutationCatalogGroupProvider`).
- Hide group tabs when the audience has no visible categories in that group (`userVisibleCatalogGroups` / `ownerVisibleCatalogGroups`). Owner fleet tabs use `GET /equipment/owner/catalog-groups`.
- Visible city text uses catalog `names` via `catalogCityLabel` / `catalogCityLabelOf`. Do not show slugs.
- Unknown `Spec.type`: do not render a field and do not drop the stored value.
- Owner spec writes go to `PUT /equipment/:id/spec-values`. Search filters include NUMBER, SELECT, MULTI_SELECT, BOOLEAN and use facets for min/max/options.

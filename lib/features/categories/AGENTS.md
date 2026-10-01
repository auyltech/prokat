# Categories

- Search browse: `AppTabs` under the app bar (same pattern as owner requests) + `CategoryHeaderCard` per group. Guest home still uses `CatalogGroupTabs`. Not the old horizontal `UserCategorySelector` row.
- Header shows selected category or all-categories (hardcoded `machinery_std` / `equipment_std` + l10n title/description).
- Category images are **4:3**; header/selector placeholders use that ratio so load does not bump layout.
- Category image + title + description is core `AppCategoryInfo` (browse header, owner equipment detail card). Fallback image: `CatalogGroup.stdImage` (`catalog_group_image.dart`).
- Tap on header body opens `CategoryPickerSheet` via `AppBottomSheet.showScrollable` (initial 0.4 / min 0.2 / max 0.85); same tiles for MACHINERY and EQUIPMENT (all-row uses group std image + l10n). Pick clears search query and (future) filters **for the active group only**.
- Create-request uses the same `CategoryPickerSheet` with `includeAllOption: false` (no group tabs in the sheet — group is chosen on the form; no “all categories”; prior pick is highlighted, or none).
- Filter button opens stub sheet only for now; active state stays off until real filters exist.
- Search button expands an `AppTextField` under the card; query/expand live in `browseGroupSessionsProvider` (per group).
- Group tabs are **lazy + sticky**: a group session / list cache is created on first open and kept when switching away. Do not clear the other group's query, and do not refetch either list, on tab change.
- `UserCategorySelector` remains for mutation flows that still use the horizontal row.

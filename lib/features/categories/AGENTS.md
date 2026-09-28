# Categories

- Browse UI: `CatalogGroupTabs` + `CategoryHeaderCard` (not the old horizontal `UserCategorySelector` row on search/guest).
- Header shows selected category or all-categories (hardcoded `machinery_std` / `equipment_std` + l10n title/description).
- Tap on header body opens `CategoryPickerSheet`; pick clears search query and (future) filters **for the active group only**.
- Filter button opens stub sheet only for now; active state stays off until real filters exist.
- Search button expands an `AppTextField` under the card; query/expand live in `browseGroupSessionsProvider` (per group).
- Group tabs are **lazy + sticky**: a group session / list cache is created on first open and kept when switching away. Do not clear the other group's query on tab change.
- `UserCategorySelector` remains for mutation flows (`create_request`).

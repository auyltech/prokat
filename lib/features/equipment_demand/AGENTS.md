# Equipment demand survey

- Config: `GET /equipment-demand/config` → `demandConfigProvider` (`DemandConfig`).
  Backend also gates on `X-App-Build` ≥ `DEMAND_SURVEY_INTENTS_MIN_BUILD` (shared iOS/Android build from `pubspec.yaml`).
- Show entry UI only when `DemandConfig.shouldShow` (`enabled && campaignId && !hasResponded`). Hide while config is loading or after submit (`markResponded` / refresh).
- Open survey with `campaignId` from that config → `AppRoutes.equipmentDemandPath`. Route guard awaits config; mount the form only when `enabled`, `config.campaignId == routeCampaignId`, and `!hasResponded`. Otherwise toast + pop (do not toast from a null `valueOrNull` while still loading).
- Form: `demandFormProvider(campaignId)` → `GET /equipment-demand/options`.
- UI: `PageView` with `padEnds: true` and `viewportFraction` derived from width so first/last card outer edges align with «Готово» (`s20$lg`); neighbors still peek. Page dots show a success check when that card has intent/Other text; active dot uses `text.main`, inactive dots are lighter.
- «Готово» enabled only with meaningful intent (any rent/provide or non-empty Other text after trim). Opens `DemandCityMultiSheet` (multi-select visible `ServiceCity` by id; does **not** change `locationProvider`). Submit disabled without a city.
- Submit → `POST /equipment-demand/responses` with `{ clientSubmissionId, campaignId, selections[{optionId,provide,rent}], other?, cityIds }`. On success: `markResponded` **before** leaving the screen, then toast. On error: keep screen, intents, Other, and cities for retry. Block double-submit while in flight.

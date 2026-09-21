# Equipment demand survey

- Config: `GET /equipment-demand/config` → `demandConfigProvider` (`DemandConfig`).
- Show entry UI only when `DemandConfig.shouldShow` (`enabled && campaignId && !hasResponded`). Hide while config is loading or after submit (`markResponded` / refresh).
- Open survey with `campaignId` from that config → `AppRoutes.equipmentDemandPath`. Do not toast "unavailable" from a null `valueOrNull` while the provider is still loading; await `demandConfigProvider.future` (or only offer the entry after `shouldShow`).
- Form: `demandFormProvider(campaignId)` → `GET /equipment-demand/options` returns `{ allowOther, other?, options[{id,code,name,description?,imageUrl?}] }`.
- Multi-select cards for options; optional «Другое» card can be selected together with options. Submit → `POST /equipment-demand/responses` with `optionIds` + optional `otherText` only when Other is selected and non-empty, then `markResponded`.
- Missing option/other images: placeholder icon; long titles/descriptions must wrap without breaking the list.

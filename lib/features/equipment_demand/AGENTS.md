# Equipment demand survey

- Config: `GET /equipment-demand/config` → `demandConfigProvider` (`DemandConfig`).
- Show entry UI only when `DemandConfig.shouldShow` (`enabled && campaignId && !hasResponded`). Hide while config is loading or after submit (`markResponded` / refresh).
- Open survey with `campaignId` from that config → `AppRoutes.equipmentDemandPath`. Do not toast "unavailable" from a null `valueOrNull` while the provider is still loading; await `demandConfigProvider.future` (or only offer the entry after `shouldShow`).
- Form: `demandFormProvider(campaignId)` → `GET /equipment-demand/options`. Submit → `POST /equipment-demand/responses`, then `markResponded`.

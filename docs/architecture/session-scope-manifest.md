# Session scope manifest

Baseline: `feat/prokat-plans-refactoring@b3f2bcc` (2026-08-14).

This manifest records the current logout boundary used by
`AppStartupController.forceSignedOut`. It is evidence for RF-08 tactical
session isolation, not a target session architecture.

## User-scoped state currently reset

| Provider or resource | Data scope | PII / user-owned data | Current reset trigger | Owner |
|---|---|---:|---|---|
| `clientProfileProvider`, `clientProfileMutationProvider` | user | yes | forced sign-out | user/profile |
| `ownerProfileProvider`, `ownerRegistrationRequestProvider`, `ownerRegistrationMutationProvider` | user | yes | forced sign-out | owner/profile |
| `locationProvider` | user | yes | forced sign-out | locations |
| `selectedCategoryProvider`, `searchEquipmentProvider` | session-derived | possible | forced sign-out | categories/equipment |
| `clientEquipmentProvider` | user/session-derived | possible | forced sign-out | equipment |
| `ownerEquipmentProvider`, `ownerEquipmentDetailsProvider`, `equipmentMutationProvider` | user | yes | forced sign-out | equipment |
| `favoritesProvider` | user | yes | forced sign-out | favorites |
| `billingProvider` | user | yes | forced sign-out | billing |
| `clientActiveBookingsProvider`, `clientHistoryBookingsProvider` | user | yes | forced sign-out | bookings |
| `ownerActiveBookingsProvider`, `ownerHistoryBookingsProvider` | user | yes | forced sign-out | bookings |
| `bookingProvider`, `bookingMutationProvider` | user | yes | forced sign-out | bookings |
| `clientActiveRequestsProvider`, `clientHistoryRequestsProvider` | user | yes | forced sign-out | requests |
| `ownerActiveRequestsProvider`, `requestMutationProvider` | user | yes | forced sign-out | requests |
| `clientOffersProvider`, `ownerOffersProvider`, `offerMutationProvider` | user | yes | forced sign-out | offers |
| `priceNegotiationsProvider`, `priceNegotiationMutationProvider` | user | yes | forced sign-out | price negotiations |
| `clientChatsProvider`, `ownerChatsProvider`, `currentChatProvider`, `chatMessagesProvider`, `chatResolverProvider` | user | yes | forced sign-out | chat |
| `reviewByBookingProvider` | user | yes | forced sign-out | reviews |
| `supportProvider` | user/session-derived | possible | forced sign-out | support |
| `notificationProvider` | user | yes | `clearOnLogout` | notifications |

Family-provider invalidation in the table means all currently cached family
instances are invalidated through the provider family boundary.

## User-owned external resources currently reset

| Resource | External resource | Current action | Ordering evidence |
|---|---:|---|---|
| `chatSocketServiceProvider` | yes | provider invalidation | after chat-state invalidation |
| `appSocketProvider` | yes | `disconnectSocket` | after notification-state reset |
| `notificationLocalStorageProvider` pending route | persisted local state | `clearPendingRoute` | requested after socket disconnect; completion is currently not awaited |
| `pushNotificationServiceProvider` device token | backend/device state | `deactivateCurrentDevice` | attempted before auth logout; failure is best-effort |

## Preserved global state

The current forced sign-out path does not invalidate these app-wide settings:

- `localeProvider`;
- `themeModeProvider`;
- category reference data;
- environment and app-level configuration;
- persisted `AppMode` behavior.

This is current behavior to preserve during the tactical RF-08 slices. It is
not a decision about the future target topology.

## Explicit unresolved or incomplete scope

| Provider or resource | Classification | Current behavior | RF-08 rule |
|---|---|---|---|
| `demandConfigProvider`, `demandFormProvider` | `unresolved_unmapped` | not reset | do not change before RF-D10/GAP mapping |
| `equipmentMapProvider` | user/session-derived candidate | not reset; invalidation is commented out | prove A-to-B exposure before changing |
| `mapControllerProvider` | external/session-derived candidate | not reset; invalidation is commented out | characterize ownership and disposal before changing |

The demand survey is not assumed to be the TO-BE Questionnaire. Its
`hasResponded` authority may be installation-, anonymous-session-, user-, or
campaign-scoped; the current architecture evidence does not decide this.

## Characterization harness

`test/features/appstartup/app_startup_unauthorized_lifecycle_test.dart`
instantiates the real `AppStartupController` listener with a controllable
forced-sign-out boundary. It proves that one unauthorized signal starts one
unauthorized sign-out and can hold that operation open for the next
concurrency slice.

The next RF-08 production change is allowed only after this harness first
reproduces concurrent unauthorized signals starting duplicate sign-outs.

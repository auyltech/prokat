# Realtime resource ownership

Baseline: `feat/prokat-plans-refactoring` after A-11 (`731c51d`).

This is RF-09 A-12 evidence: a map of current mobile-owned socket, listener,
timer, and global-handler resources. It does not choose target Chat/outbox
semantics and does not authorize a production change.

Test seam for socket mechanics: `test/support/fake_app_socket_service.dart`.
Notification adapter fakes and Crashlytics handler fakes stay out of this
document's implementation PR.

## Ownership map

| Resource | Creator | Owner | Start trigger | Stop trigger | Reconnect owner | Test fake |
|---|---|---|---|---|---|---|
| App socket connection | `AppSocketService.connect` | `AppSocketService` | `ChatSocketService.joinChat` / `connect`; `notificationBootstrapProvider.startIfReady` | `disconnectSocket` from `AppStartupController` logout; bootstrap background/dispose | `ChatSocketService._handleSocketConnected`; bootstrap `startIfReady` on resume | `FakeAppSocketService` |
| Chat room membership | `ChatSocketService._joinChat` | `ChatSocketService` | `ChatMessagesNotifier._activateChatSession` | `leaveChat` on cancel/dispose; `disposeChatSession` | desired chat is re-joined on app-socket connect | `FakeAppSocketService` emit counts |
| `chat:message:new` handler | `ChatSocketService._attachActiveMessageListener` | `ChatSocketService` | `onNewMessage` | `off` when listener list is empty; `dispose` | handler map is re-attached only on new `on()` | `FakeAppSocketService.on/off` |
| `notification:new` handler | `notificationBootstrapProvider.attachSocketNotificationListener` | `notificationBootstrapProvider` | authenticated `startIfReady` | `off` on logout/background/dispose | `startIfReady` after resume | `FakeAppSocketService` |
| Optimistic confirmation timers | `ChatMessagesNotifier` | `ChatMessagesNotifier` | `sendMessage` after socket send | cancel on confirm, failure, scope change, `onDispose` | none | FakeAsync / controllable clock in a later slice |
| Incoming message buffer | `ChatMessagesNotifier._incomingBuffer` | `ChatMessagesNotifier` | socket event before REST page lands | flushed after initial fetch; cleared on dispose | none | delayed chat REST fake |
| `WidgetsBindingObserver` | `notificationBootstrapProvider` | `notificationBootstrapProvider` | provider creation | `ref.onDispose` | n/a | `testWidgets` |
| FCM / local-notification callbacks | `PushNotificationService.initialize` | `PushNotificationService` | bootstrap `startIfReady` when push enabled | `dispose` on logout and provider dispose | `initialize` after resume if `pushStarted` was reset | deferred notification fake |
| Pending notification route | `NotificationLocalStorage.savePendingRoute` | navigation service + `AppStartupController` | notification tap while logged out | awaited `clearPendingRoute` on logout; `flushPendingRouteIfAny` on start | n/a | A-11 gated storage fake |
| `FlutterError.onError` / `PlatformDispatcher.instance.onError` | `CrashReportingService.initialize` | `CrashReportingService` | Firebase-enabled, supported platform, non-debug | none; previous handlers are replaced, not chained | n/a | deferred Crashlytics fake (RF-D11) |

## Conflicting or overlapping owners

These are inventory facts for later RF-09 slices. A-12 does not change them.

| Resource | Overlap | Current observable effect |
|---|---|---|
| App socket disconnect on logout | `AppStartupController._clearUserScopedProviders` owns session disconnect; bootstrap auth listener only detaches `notification:new` and push callbacks | One `disconnectSocket` per `forceSignedOut`. Background/dispose still disconnect from bootstrap. |
| Chat message listeners | `ChatSocketService.onNewMessage` fans out to every registration over one socket handler | Removing a listener leaves others attached; the socket `on` is registered once until the last listener is gone. |
| Chat connect listener | `connect()` synchronously notifies `ChatSocketService`, which enqueues another `_joinChat` | Join is emitted once; `connect()` is invoked a second time as a no-op. Candidate for a later join-dedup slice. |
| Notification vs chat handlers | Both use the same `AppSocketService` event map | Distinct event names (`notification:new` vs `chat:message:new`); `on(event)` still replaces any previous handler for that name. |
| Crashlytics global handlers | `CrashReportingService` assigns `FlutterError.onError` and `PlatformDispatcher.instance.onError` directly | Previous handlers are dropped. No test fake yet; RF-D11 remains unresolved. |

## Explicit non-owners

- `ChatSocketNotifier` is not referenced outside its file. It is not an active resource owner.
- `equipment_demand` has no socket/listener/timer resources.
- Target Chat authorization, client message ids, durable outbox, and notification audience are deferred until Gap Analysis.

## Fake contract (socket)

`FakeAppSocketService` must let a test:

- count `connect` / `disconnectSocket` / `on` / `off` / `emit` / `emitWithAck`;
- complete or delay `connect`;
- emit inbound events in a chosen order, including duplicates;
- bump `connectionGeneration` to simulate reconnect without a real Socket.IO server.

It must not open a network connection or touch Firebase.

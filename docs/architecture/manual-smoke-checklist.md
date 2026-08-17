# Manual smoke checklist (Track A)

Use this after high-risk PRs on `feat/prokat-plans-refactoring`: session lifecycle (RF-08), realtime/chat/notifications (RF-09), and adjacent parser/provider fixes.

**Setup**

- Local backend running (`prokatBackend`) with the same API/socket URLs as the app `.env`.
- Two test accounts ready: **client A** and **owner B** (or client B).
- Prefer a real device/emulator with network; desktop is fine for session/parser checks, but chat/push behave differently on mobile.
- Optional: second device or browser tab logged in as the chat counterparty.

**Pass criteria**

- No crash, no infinite loading spinner, no stale data from the previous user.
- Each step should finish in under ~1 minute unless noted.

---

## 1. Session restore and rating (RF-05 / auth)

| Step | Action | Expected |
|---|---|---|
| 1.1 | Log in as any user whose profile shows a rating. | Home/profile loads; rating visible. |
| 1.2 | Kill the app completely (swipe away / stop process). | — |
| 1.3 | Cold start the app. | Still logged in; **same rating** still visible (not 0 / empty). |
| 1.4 | Log out manually. | Login/guest screen; no owner/client data on UI. |

---

## 2. Account isolation A → logout → B (RF-08)

| Step | Action | Expected |
|---|---|---|
| 2.1 | Log in as **user A** (client). Open equipment list or profile with identifiable data. | Data belongs to A. |
| 2.2 | Log out. | Guest/unauth state; lists cleared or guest content only. |
| 2.3 | Log in as **user B** without restarting the app. | **No** equipment/profile/chat data from A. |
| 2.4 | Repeat 2.1–2.3 with **owner** account if A was client. | Same isolation for owner equipment/bookings. |

---

## 3. Chat socket (RF-09)

| Step | Action | Expected |
|---|---|---|
| 3.1 | Log in; open an existing chat. | Message history loads. |
| 3.2 | Send a text message. | Message appears (optimistic + confirmed). |
| 3.3 | From counterparty (second account/device), send a reply. | Reply appears **without** reopening the chat. |
| 3.4 | Navigate away from chat, then open the **same** chat again. | History intact; new messages still arrive. |
| 3.5 | Open chat → put app in background ~10 s → resume. | Still connected; send/receive works (may need one sent message to verify). |

---

## 4. Logout and socket cleanup (RF-08 / RF-09)

| Step | Action | Expected |
|---|---|---|
| 4.1 | While logged in with chat/notifications active, log out once. | Single smooth logout; no error snackbar loop. |
| 4.2 | Log in again; open chat. | Messages work (socket reconnected). |
| 4.3 | *(Optional)* Tap overlapping logout triggers quickly (if UI allows). | Still one clean logout; no double-freeze. |

---

## 5. In-app notifications (RF-09)

| Step | Action | Expected |
|---|---|---|
| 5.1 | Log in as user who receives socket notifications. | Unread badge/count syncs. |
| 5.2 | Trigger an in-app `notification:new` event (backend action or test notification). | Notification appears in app list/badge updates. |
| 5.3 | Log out. | Notification list cleared for that session. |
| 5.4 | Background → resume while logged in. | Notifications still work; **no duplicate** toasts for one event. |

---

## 6. Pending route after notification tap (RF-08 / A-11)

| Step | Action | Expected |
|---|---|---|
| 6.1 | While **logged out**, tap a notification that stores a deep link (or simulate saved pending route). | Prompted to log in. |
| 6.2 | Log in. | App navigates to the intended screen **once**. |
| 6.3 | Log out before navigation completes (if possible). | Pending route cleared; next user does **not** land on A's route. |

---

## 7. Equipment and categories (RF-04 / RF-06)

| Step | Action | Expected |
|---|---|---|
| 7.1 | Guest or client: open equipment search; change filters twice quickly. | Latest filters win; no flash of stale results. |
| 7.2 | Open category selector (home, create equipment, or create request). | Categories load; selection applies. |
| 7.3 | Owner: open equipment list and one equipment detail. | Loads without provider/override errors. |

---

## 8. Billing / transactions (RF-05)

| Step | Action | Expected |
|---|---|---|
| 8.1 | Log in as **owner**; open balance / transaction history. | List loads. |
| 8.2 | If DB has `ADJUSTMENT` rows, confirm they render (not skipped silently). | Row visible; no parse crash. |
| 8.3 | If no adjustment exists, note *"ADJUSTMENT not exercised"* — parser covered by unit test only. | TOPUP/CONSUMPTION still display normally. |

---

## 9. Mapbox (Android only, if build includes `b5f61ee`)

| Step | Action | Expected |
|---|---|---|
| 9.1 | Open a screen with map (equipment map / location picker). | Map tiles render; no token error in log. |

---

## When to run what

| After PR type | Minimum steps |
|---|---|
| Session / logout only | 1, 2, 4 |
| Chat / socket only | 3, 4 |
| Notification bootstrap | 4, 5 |
| Parser / provider rewiring | Relevant section only (7 or 8) + quick 1.3 if auth touched |
| Full wave merge | All sections 1–8; 9 if Android map changed |

---

## Red flags (stop and file an issue)

- Chat messages only work after force-kill app.
- User B sees chats/bookings/equipment from user A.
- Duplicate notifications for a single backend event after resume.
- Logout leaves spinner forever or requires second tap.
- Transaction screen empty/crash when backend returns `ADJUSTMENT`.

Unit/fake suite (`flutter test`) does **not** replace steps 3–5 and 6 — keep this checklist for releases that touch realtime or session boundaries.

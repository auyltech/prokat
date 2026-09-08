# Billing

- Balance is `OwnerBalance.secondsRemaining` (seconds). UI minutes = `floor(seconds / 60)`.
- Welcome gift: one `FREECREDIT` with `referenceType: WELCOME_OWNER_MINUTES` (10 000 minutes) on first become-owner approval. Do not grant from the client.
- Later credits without payment: admin `FREECREDIT` / `ADMIN_GRANT` only.
- `POST /billing` must not credit the wallet while payments are disconnected. The top-up screen keeps packages; submit shows `paymentFeatureComingSoon` and does not call the API.
- Burn is visible equipment only (`isVisible`). `burnRateMinutesPerHour` from `GET /billing` is already minutes/hour. Exhaustion clock is `estimatedExhaustionAt` formatted as date + time. `BalanceTile` silently refreshes balance every 60s while on screen.

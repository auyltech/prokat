# App Startup Notes

- `AppStartupController` is responsible for the app bootstrap cycle.
- It restores auth-related local state, loads shared app data, then exposes router-facing startup state.
- It now also owns the persisted app mode for owner accounts:
  - `clientMode`
  - `ownerMode`
- Owner users can switch modes and the last selected mode is stored locally.
- Router behavior should continue to depend on `AppStartupState`, while mode-specific decisions should be resolved inside the startup controller.
- Catalog bundle (`catalogProvider`) is loaded on first use and refreshed from guest/client pull-to-refresh, not from locale changes.

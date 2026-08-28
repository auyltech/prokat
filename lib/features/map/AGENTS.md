# Map

- `MapController` lives in `mapControllerProvider`. Capture it while `ref` is valid (`didChangeDependencies` / `build`). In `dispose`, call `detach` on that instance — never `ref.read`.
- After `deactivate`, ignore Mapbox camera/tap/style callbacks. Pin screens own reverse-geocode debounce and must stop it on leave.

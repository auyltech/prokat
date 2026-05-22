# Prokat Work Report - 2026-05-15

## Goal

Improve image performance and upload handling in the Flutter app to reduce decoded bitmap memory usage, prevent list scrolling jank, and avoid oversized uploads.

## Work Done

### Added Shared Optimized Image Widget

Created:

- `lib/core/widgets/optimized_network_image.dart`

This widget wraps `CachedNetworkImage` and adds:

- device-pixel-ratio-aware `memCacheWidth` / `memCacheHeight`
- shimmer placeholder using the existing `shimmer` package
- consistent error fallback icon/background
- support for fixed or constraint-based image sizing
- optional max cache width/height caps for larger images

Purpose: existing server images can remain large, but Flutter now decodes them closer to their actual on-screen size.

### Updated Equipment/List Images

Replaced direct `Image.network` / scattered `CachedNetworkImage` usage with `OptimizedNetworkImage` in equipment-heavy surfaces:

- `lib/features/equipment/widgets/list/client_equipment_card.dart`
- `lib/features/equipment/widgets/list/equipment_list_tile.dart`
- `lib/features/equipment/widgets/list/guest_equipment_card.dart`
- `lib/features/equipment/widgets/owner/owner_equipment_card.dart`
- `lib/features/equipment/widgets/owner/owner_equipment_image_header.dart`
- `lib/features/map/widgets/equipment_details_drawer.dart`

These are the most important areas because they show equipment photos in lists/cards/detail previews.

### Updated Booking/Favorites/Request Image Previews

Also applied optimized image decoding to related thumbnail surfaces:

- `lib/features/bookings/widgets/client_dashboard_booking_tile.dart`
- `lib/features/bookings/widgets/equipment_image_header.dart`
- `lib/features/bookings/widgets/owner_booking_card.dart`
- `lib/features/bookings/widgets/owner_booking_tile.dart`
- `lib/features/bookings/widgets/owner_dashboard_booking_tile.dart`
- `lib/features/favorites/screens/favorites_screen.dart`
- `lib/features/favorites/widgets/favorite_item_horizontal.dart`
- `lib/features/favorites/widgets/favorite_item_tile.dart`
- `lib/features/requests/widgets.dart/client_request_tile.dart`
- `lib/features/requests/widgets.dart/owner_request_tile.dart`
- `lib/features/user/widgets/client_booking_tile.dart`
- `lib/features/user/widgets/owner_equipment_section.dart`
- `lib/features/user/widgets/user_equipment_tile.dart`

This should make repeated scrolling screens safer on mid-range phones.

### Improved Upload Compression

Updated owner equipment image upload in:

- `lib/features/equipment/widgets/owner/owner_equipment_image_header.dart`

Changes:

- picker now uses `maxWidth: 1920`
- picker now uses `maxHeight: 1920`
- picker now uses `imageQuality: 85`
- added `ImageCropper`
- equipment photos are cropped to 4:3
- cropper uses `compressQuality: 85`

This reduces upload size before files reach the backend and standardizes cover/gallery layout for equipment photos.

Updated profile image picker in:

- `lib/features/user/widgets/profile_image_picker.dart`

Changes:

- picker now uses `imageQuality: 85`
- cropper now uses `compressQuality: 85`

Profile photos already used square crop and `1080x1080` max dimensions.

## Existing Server Images

No server-side image migration was done today.

The app-side `memCacheWidth` / `memCacheHeight` changes help with decoded bitmap memory even for existing large server images. However, existing 4K images may still cost extra bandwidth until the backend has generated thumbnails.

## Verification Status

### Completed

- `git diff --check` passed.
- Confirmed equipment-heavy image surfaces now use `OptimizedNetworkImage`.

### Not Completed

Could not complete:

- `dart format .`
- `flutter analyze`

Reason: local Dart/Flutter commands hung in the sandbox and timed out repeatedly. An escalated `dart format .` run was requested, but the user declined.

Important: run these locally before merging:

```powershell
dart format .
flutter analyze
flutter test
```

## Known Follow-Up Checks

1. Confirm `ImageCropper` API compatibility on both Android and iOS.
2. Confirm owner equipment image upload flow still works after adding mandatory 4:3 crop.
3. Confirm shimmer colors look good in both light and dark themes.
4. Confirm list images do not appear blurry on high-density screens.
5. Check whether detail/gallery images should use a higher `maxCacheHeight` or allow zoom/full-resolution mode.

## Next Steps

1. Run `dart format .`.
2. Run `flutter analyze` and fix any compile/lint issues.
3. Run `flutter test`.
4. Manually test these screens:
   - equipment search/list
   - guest equipment cards
   - owner equipment list
   - owner equipment detail image upload
   - booking tiles
   - favorites screen
   - map equipment drawer
   - client/owner request tiles
5. If the client-side result is good, plan backend thumbnail support:
   - store original image
   - generate medium image around `1280px`
   - generate thumbnail around `400-600px`
   - return thumbnail URL for lists and medium/original for detail/gallery

## Notes For Tomorrow

Main file to understand first:

- `lib/core/widgets/optimized_network_image.dart`

Main risk:

- analyzer may reveal small API or formatting issues because Dart/Flutter verification could not run today.

Most important product decision still open:

- whether 4:3 cropping should apply to every owner equipment photo, or only to cover/listing photos while gallery photos remain flexible.

# Prokat Mobile PRD

**Document type:** Product Requirements Document  
**Project:** Prokat Mobile  
**Primary platforms:** Flutter mobile app, Node/Express backend, Prisma/PostgreSQL database, Next.js admin dashboard  
**Primary market:** Kazakhstan, with early focus on Atyrau  
**Status:** Working product reference draft  
**Audience:** Project owner, developers, and future AI coding agents

---

## 1. Product Summary

Prokat is a mobile-first marketplace for renting heavy equipment and related industrial services in Kazakhstan.

The product connects two main sides:

1. **Renters / clients** who need equipment or services.
2. **Equipment owners / providers** who list equipment, respond to requests, accept bookings, and perform work.

The early service categories include septic/vacuum trucks, forklifts, cranes, manipulators, tow trucks, excavators, and similar heavy equipment services.

The product is designed around real operational workflows, not only simple listings. A renter may browse equipment, create a booking, create a request, chat with an owner, select a location, and track the work. An owner may manage equipment, prices, availability, images, specs, bookings, requests, offers, and profile verification.

The long-term system includes:

- Flutter mobile app for renters and owners.
- Node/Express backend API.
- Prisma/PostgreSQL database.
- Supabase Storage for images and documents.
- Mapbox for map, pins, geocoding, and address flows.
- Next.js admin dashboard for business operations, content, categories, specs, dictionary, bookings, requests, offers, and owner management.

---

## 2. Product Goals

### 2.1 Business Goals

- Make it easy for renters to find and book heavy equipment services.
- Give equipment owners a simple mobile tool to manage their fleet and respond to work opportunities.
- Support local market needs in Kazakhstan, especially Atyrau.
- Build enough admin visibility to review owners, manage content, and monitor transactions.
- Create a scalable foundation for future owner/admin web workflows.

### 2.2 Product Goals

- Support both direct equipment booking and request/offer workflows.
- Support map-based discovery and location selection.
- Support owner-managed equipment listings with prices, locations, images, and specs.
- Support role-aware routing and navigation.
- Support multi-language static data through a dictionary/localization system.
- Keep UI consistent with an industrial dark theme.

### 2.3 Technical Goals

- Keep Flutter code modular by feature.
- Keep backend business rules centralized in services.
- Keep frontend status handling tolerant of backend enum changes by using strings in Flutter where appropriate.
- Use Prisma schema as the source of truth for data relations.
- Use DTOs to avoid leaking raw database models directly to the mobile app.
- Use reusable admin patterns for CRUD, table views, forms, validation, import, and export.

---

## 3. Target Users

## 3.1 Renters / Clients

Renters are users who need equipment or industrial services.

Typical renter needs:

- Find nearby equipment.
- Browse by category.
- View prices and service details.
- Select or create a service location.
- Book equipment.
- Create a request if they do not know which provider to choose.
- Chat with owners.
- Track booking status.

## 3.2 Equipment Owners / Providers

Owners are users or companies who provide equipment services.

Typical owner needs:

- Register as an owner/provider.
- Create and manage an owner profile.
- Add equipment.
- Add equipment prices.
- Add equipment location.
- Add equipment images.
- Fill equipment technical specs.
- Set equipment visibility and availability.
- Accept or reject bookings.
- Respond to requests with offers.
- Chat with renters.
- Manage active work status.

## 3.3 Admins

Admins manage the business and platform content.

Typical admin needs:

- Review owner registration/profile information.
- Manage categories.
- Manage category specs.
- Manage dictionary/static data.
- View bookings, requests, and offers.
- Review owners, equipment, and operational activity.
- Use import/export tools for content management.

## 3.4 Future Support Role

[Future] The schema includes a `SUPPORT` user role. This role may later be used for customer support, moderation, or operational assistance.

---

## 4. User Roles

The current user role enum is:

```txt
USER
OWNER
SUPPORT
ADMIN
```

### USER

Default renter/client account.

Can:

- Browse equipment.
- Save addresses.
- Create bookings.
- Create requests.
- Send/receive chat messages.
- Favorite equipment.

### OWNER

Equipment provider account.

Can:

- Use renter features where applicable.
- Manage equipment.
- Manage owner profile.
- Respond to requests.
- Accept/reject bookings.
- Update work status.
- Chat with renters.

[Confirmed] One account may act as both renter and owner in the product direction, even if backend role handling may need careful implementation.

### ADMIN

Admin dashboard user.

Can:

- Manage content and operational workflows.
- Review owners.
- Manage categories, specs, dictionary, bookings, requests, and offers.

### SUPPORT

[Future] Support role exists in schema but the exact permissions are not finalized.

---

## 5. Core Problems Solved

1. **Equipment discovery problem**  
   Renters need a simple way to find available heavy equipment by location/category.

2. **Trust and verification problem**  
   Owners need profile verification, documents, ratings, and badges to increase trust.

3. **Operational coordination problem**  
   Renters and owners need booking statuses, work statuses, chat, and location instructions.

4. **Pricing clarity problem**  
   Equipment may have different pricing modes: per hour, per day, per trip, or per cubic meter.

5. **Equipment detail quality problem**  
   Owners need to provide category-specific specs such as tank capacity, hose length, lifting capacity, and boom length.

6. **Admin control problem**  
   The platform needs admin tools for categories, specs, dictionary, owners, bookings, requests, and offers.

---

## 6. Product Scope

## 6.1 In Scope

- Mobile app for renters and owners.
- Auth via username/password and phone OTP.
- Role-aware startup and navigation.
- Equipment list and detail flows.
- Owner equipment management.
- Equipment pricing.
- Equipment location.
- Equipment images.
- Category specs and equipment specs.
- Booking workflow.
- Request/offer workflow.
- Chat workflow.
- Map/location flows.
- Admin dashboard for business workflows and content management.
- Supabase image/document upload strategy.
- Dictionary/localization system.

## 6.2 Out of Scope for Now

- In-app payment storage.
- Full payment processing.
- Advanced analytics.
- Full public web marketplace.
- Dedicated support dashboard.
- Automated dispatch optimization.
- Full accounting/invoicing system.

[Confirmed] Payment information should not be stored in the app at this stage.

---

## 7. Platform Overview

## 7.1 Mobile App

Technology:

- Flutter.
- Riverpod for state management.
- Dio for HTTP.
- GoRouter for routing.
- Mapbox via `mapbox_maps_flutter`.
- `cached_network_image` for images.
- Secure storage for sessions.

Expected modular structure:

```txt
lib/
  core/
    api/
    router/
    storage/
    widgets/
  features/
    auth/
    categories/
    equipment/
    owner/
      equipment/
      bookings/
      requests/
    locations/
    map/
    chat/
```

The mobile app serves both renter and owner flows. Navigation should be role-aware.

## 7.2 Backend API

Technology:

- Node.js.
- Express.
- TypeScript.
- Prisma.
- PostgreSQL.
- Zod for validation.
- Supabase Storage integration.

Backend responsibilities:

- Auth and session handling.
- Validation and normalization.
- Business rules.
- Ownership checks.
- File upload handling.
- DTO creation.
- Prisma persistence.
- Error response standardization.

## 7.3 Admin Dashboard

Technology:

- Next.js.
- Server-rendered admin pages where possible.
- Server actions for CRUD.
- Zod validation.
- Reusable table/form/import/export patterns.

Admin areas:

- Categories.
- Category specs.
- Dictionary.
- Owners.
- Bookings.
- Requests.
- Offers.
- Activity/logs later.

## 7.4 Storage

Technology:

- Supabase Storage.

Storage types:

- Profile images.
- Equipment images.
- Category images.
- Owner registration/verification documents.
- Future work completion/review images.

---

## 8. Feature Map

| Feature | Mobile | Backend | Admin |
|---|---:|---:|---:|
| Auth | Yes | Yes | Partial |
| Startup/role routing | Yes | Partial | No |
| User profile | Yes | Yes | Future |
| Owner registration | Yes | Yes | Yes |
| Owner profile | Yes | Yes | Yes |
| Equipment management | Yes | Yes | Yes/Future |
| Equipment prices | Yes | Yes | Yes/Future |
| Equipment locations | Yes | Yes | Yes/Future |
| Equipment images | Yes | Yes | Yes/Future |
| Categories | Read | Yes | Yes |
| Category specs | Read/fill values | Yes | Yes |
| Bookings | Yes | Yes | Yes |
| Requests | Yes | Yes | Yes |
| Offers | Yes | Yes | Yes |
| Chat | Yes | Yes | Future/Admin view |
| Map/location | Yes | Yes | No |
| Dictionary/localization | Read | Yes | Yes |
| Import/export | No | Yes | Yes |

---

# 9. Mobile App Requirements

## 9.1 Auth and Startup

### Login Methods

The mobile app should support:

- Username/password login.
- Phone number + OTP login.

Phone login should be Kazakhstan-oriented and should ideally use E.164 formatting.

### Session Storage

[Confirmed] Store the full `AuthSession` JSON in secure storage, not only the token.

The session should include at least:

- Session token.
- User data.
- Role data.
- Expiration if available.

### OTP Session Persistence

[Confirmed] OTP request state should be persisted so the app can resume OTP verification if reopened.

Persist:

- Phone number.
- Request timestamp.
- Any required OTP flow metadata.

### Authorization Header

[Confirmed] Dio should send:

```txt
Authorization: Bearer <sessionToken>
```

Known pitfall:

- Do not decode the token as JSON.
- Use `session.sessionToken` directly.
- Avoid `Bearer null` by validating session loading carefully.

### Startup Flow

The startup controller should decide app state:

```txt
loading
session guest
renter
owner
error
```

Expected startup logic:

1. Load secure storage session.
2. If session exists, refresh/load profile and required startup data.
3. Route by role:
   - renter/user to renter dashboard or main renter flow.
   - owner to owner dashboard/owner section.
4. If no session but OTP session exists, route to login/OTP continuation.
5. Otherwise route to guest/main/landing flow.

Known pitfall:

- Avoid calling startup provider initialization inside router creation in a way that causes GoRouter refresh loops.
- Guard startup initialization with `_initialized` or `_isInitializing`.

---

## 9.2 Routing and Navigation

The app uses GoRouter.

Common routes include:

```txt
/dashboard
/search/list
/requests/create
/orders
/chats
/owner/equipment
/owner/bookings
/owner/requests
/owner/addresses
/owner/addresses/create
/owner/addresses/map
/equipment/:id/book
```

[Confirmed] Map fallback should redirect non-mobile contexts to `/search/list` where applicable.

Navigation should be role-aware:

- Guest sees public/landing/search options.
- Renter sees renter dashboard, search, requests, orders, chats.
- Owner sees owner equipment, owner bookings, owner requests, owner profile tools.
- Admin uses admin dashboard, likely outside Flutter app.

---

## 9.3 UI and Theme

The product uses an industrial dark style.

Theme preferences:

- Use `Theme.of(context)` and `ColorScheme`.
- Avoid hardcoded colors inside components.
- Use theme primary/accent for brand highlights.
- Existing visual identity includes PROKAT header stylization.

Known color references:

```txt
accentOrange: #F57C00
darkBackground: #121417
darkCard: #1E2125
```

Guidelines:

- Use large cards/tiles with clear contrast.
- Avoid tiny alpha blends that render poorly on Android.
- Use consistent section cards such as `EquipmentSectionCard`.
- Use reusable bottom sheets like `EditSheet`.
- Use compact but readable booking/request tiles.
- Format prices in KZT as integers with space thousand separators and no decimals.
- Use skeleton loaders that match actual tile layout.

---

# 10. Backend Requirements

## 10.1 API Pattern

Backend should prefer a consistent response wrapper:

```json
{
  "success": true,
  "data": {},
  "message": "Optional success message",
  "error": null
}
```

For errors:

```json
{
  "success": false,
  "data": null,
  "message": "Optional user-facing message",
  "error": "Detailed error or validation result"
}
```

[Confirmed] Frontend should surface useful backend error messages for validation and conflicts.

## 10.2 Validation

Use Zod schemas for:

- Request body validation.
- Query validation where appropriate.
- Status parsing and transformation.
- Friendly error messages.

Use `safeParse`, not unsafe parsing.

## 10.3 Error Handling

Backend should return meaningful HTTP statuses:

- `400` validation error.
- `401` unauthenticated.
- `403` unauthorized.
- `404` not found.
- `409` conflict.
- `500` unexpected server error.

Flutter Dio should not swallow backend error bodies.

Recommended frontend approach:

- Configure Dio to let non-2xx responses be inspected, or catch `DioException` and parse `response.data`.
- Show backend `message` or `error` when available.

## 10.4 DTO Strategy

Backend should use DTO functions for model responses.

Goal:

- Avoid returning raw Prisma models directly.
- Hide sensitive fields.
- Normalize nested relations.
- Keep mobile model parsing stable.

Expected DTO layering:

- `UserDTO`.
- `EquipmentDTO` includes owner DTO/category/prices/images/location/specs as needed.
- `BookingDTO` includes equipment DTO, renter DTO, location DTO.
- `ChatDTO` includes last message and participants.

[Confirmed] DTOs should compose smaller DTOs rather than duplicate mapping logic.

## 10.5 Transaction Pattern

Use Prisma transactions for operations where partial success would create inconsistent data.

Examples:

- Register user + create profile.
- Approve owner + update related status.
- Create booking + update offer/request/equipment state if applicable.
- Create equipment + initial related records if that approach is chosen.

---

# 11. Admin Dashboard Requirements

## 11.1 Admin Architecture

The admin dashboard should use server-rendered pages where practical.

Preferred pattern:

- Page fetches data server-side.
- Table renders records.
- Form handles create/edit.
- Server actions handle CRUD.
- Zod validates form data.
- Import/export components use API routes.

## 11.2 Existing Pattern to Reuse

[Confirmed] New admin modules should copy the structure used in `admin/categories` where relevant.

This applies to:

- Category specs.
- Dictionary.
- Bookings.
- Requests.
- Offers.
- Owner-related pages.

## 11.3 Admin Modules

### Categories

Admin can manage equipment/service categories.

Fields include:

- Name.
- Slug.
- Capacity unit.
- Sort index.
- User visibility.
- Owner visibility.
- Image/icon.

### Category Specs

Admin can manage specs per category.

Examples:

- Tank capacity.
- Hose length.
- Lifting capacity.
- Boom length.
- Forklift capacity.

The category specs page should support:

- List/table.
- Create/edit/delete.
- Category relationship.
- Sort index.
- Input type.
- Client visibility.
- Import/export.

### Dictionary

Admin can manage static data and localized values.

Used for:

- Forms.
- Pages.
- Emails.
- Static options.
- Multi-language labels.

### Bookings

Admin can view and manage booking records.

Should include:

- Status.
- User.
- Equipment.
- Location.
- Price.
- Booking time.
- Work status.
- Pagination.

### Requests

Admin can view renter requests.

Should include:

- Category.
- Capacity.
- Required date/time.
- Offered rate.
- Status.
- Location.
- User.
- Offers count.

### Offers

Admin can view owner offers.

Should include:

- Request.
- Equipment.
- Price.
- Rate.
- Status.
- Comment.

### Owners

Admin should eventually manage:

- Owner registration requests.
- Owner profiles.
- Verification state.
- Documents.
- Admin comments.
- Badges/verification.

---

# 12. Data Model Overview

This section summarizes important Prisma concepts. It should not replace `schema.prisma`.

## 12.1 User

Purpose:

- Core authentication and identity model.

Key fields:

- `id`.
- `phoneCountryCode`.
- `phoneNumber`.
- `phoneVerifiedAt`.
- `username`.
- `password`.
- `role`.
- `isActive`.

Important relations:

- Sessions.
- Bookings.
- Equipment.
- Images.
- Locations.
- Requests.
- Favorites.
- User profiles.
- Organization relations.

Business rules:

- Username and phone number are unique where present.
- Role controls app routing and permissions.
- User may act as renter and owner depending on role/profile flow.

## 12.2 UserProfile

Purpose:

- User-facing profile details separate from authentication identity.

Key fields:

- Name.
- Phone.
- Profile image URL.
- Bio.
- Selected category.
- Primary address.
- City/region.
- Rating/rating count.
- Theme/language.

Business rules:

- Linked one-to-one to `User` through `userId`.
- Used for renter/client profile display.

## 12.3 UserSettings

Purpose:

- User preference settings.

Key fields:

- Theme.
- Search radius.
- Notification preferences.
- Language.

## 12.4 PhoneOtp

Purpose:

- OTP verification records.

Key fields:

- Phone number.
- Code hash and salt.
- Attempts.
- Expiration.
- Used/verified timestamps.

Business rules:

- Store hashes, not raw OTP codes where possible.
- Track attempts and expiration.

## 12.5 Session

Purpose:

- Auth session token storage.

Key fields:

- `sessionToken`.
- `isActive`.
- `expires`.
- `ipAddress`.
- `userAgent`.

Business rules:

- Token is used for bearer authentication.
- Sessions belong to users.
- Sessions may optionally be organization-scoped.

## 12.6 Category

Purpose:

- Equipment/service category managed by admin.

Key fields:

- `slug`.
- `name`.
- `capacityUnit`.
- `sortIndex`.
- `isUserVisible`.
- `isOwnerVisible`.
- `iconName`.
- `imageId`.

Relations:

- Requests.
- Equipment.
- User profiles.
- Equipment models.
- Category specs.

Business rules:

- Categories drive browsing, filtering, equipment creation, and request creation.
- Visibility may differ between renters and owners.

## 12.7 CategorySpec

Purpose:

- Admin-defined technical spec template for a category.

Key fields:

- `name`.
- `unit`.
- `iconName`.
- `visibletoClient`.
- `inputType`.
- `sortIndex`.
- `categoryId`.

Relations:

- Category.
- Equipment specs.

Business rules:

- Specs are defined once per category.
- Equipment owners fill values through `EquipmentSpec`.
- Visible specs can be displayed to renters.

[Open Question] Recent discussion referenced fields like `key`, `iconLibrary`, and `isRequired`, but the uploaded schema currently shows `name`, `unit`, `iconName`, `visibletoClient`, `inputType`, and `sortIndex`. Decide whether schema should be updated to include `key`, `iconLibrary`, and `isRequired`.

## 12.8 EquipmentModel

Purpose:

- Optional catalog-like model for known equipment models.

Key fields:

- Name.
- Capacity unit.
- Capacity.
- Visibility.
- Category relation.
- Image/icon relation.

Business rules:

- May be used later to help owners select predefined models.

## 12.9 Equipment

Purpose:

- Owner-owned rentable equipment listing.

Key fields:

- `name`.
- `model`.
- `plateNumber`.
- `capacity`.
- `city`.
- `ownerComment`.
- `rentCondition`.
- `status`.
- `isVisible`.

Relations:

- Prices.
- Images.
- Bookings.
- Offers.
- Owner.
- Location.
- Category.
- Favorites.
- Equipment model.
- Equipment specs.

Business rules:

- Equipment belongs to an owner.
- Equipment may have multiple prices.
- Equipment may have multiple images.
- Equipment may have one active/base location for now.
- `capacity` and `model` may eventually be replaced or reduced because specs handle more detailed technical data.

## 12.10 EquipmentStatus

Current enum values:

```txt
DRAFT
CREATED
ACCEPTED
REJECTED
AVAILABLE
BOOKED
MAINTENANCE
DISABLED
ARCHIVED
```

Mobile guidance:

- Flutter may store status as string to avoid enum mismatch.
- Compare status case-insensitively where needed.

## 12.11 EquipmentSpec

Purpose:

- Actual spec value for one equipment item.

Key fields:

- `equipmentId`.
- `categorySpecId`.
- `value`.

Business rules:

- Unique pair: `equipmentId + categorySpecId`.
- Owner fills values in mobile equipment detail screen.
- Values should be updated in one batch where possible.

[Open Question] Decide whether equipment spec rows are created automatically when equipment is created, or lazily when the owner opens/edits specs.

Recommended direction:

- Backend should own reconciliation between category specs and equipment specs.
- Mobile should not be responsible for deciding which database rows are missing.
- Mobile should receive a normalized list of specs with current values and submit changed values in one request.

## 12.12 Location

Purpose:

- Address or equipment location.

Key fields:

- `service`.
- `street`.
- `city`.
- `country`.
- `comment`.
- `instructions`.
- `longitude`.
- `latitude`.

Service enum:

```txt
EQUIPMENT
ADDRESS
```

Business rules:

- `ADDRESS` is used for renter/user saved addresses.
- `EQUIPMENT` is used for equipment base location.
- Coordinate ordering must be handled carefully with Mapbox: `Position(longitude, latitude)`.

## 12.13 PriceEntry

Purpose:

- Equipment pricing option.

Key fields:

- `equipmentId`.
- `price`.
- `priceRate`.
- `serviceTime`.

Price rate values:

```txt
PER_HOUR
PER_DAY
PER_TRIP
PER_CUBIC_METER
```

Business rules:

- Price is stored as integer KZT.
- Display with space thousand separators and no fractions.

## 12.14 Request

Purpose:

- Renter-created service request, usually before choosing a specific owner/equipment.

Key fields:

- `capacity`.
- `requiredOn`.
- `requiredAt`.
- `comment`.
- `offeredRate`.
- `status`.

Relations:

- Category.
- Location.
- Offers.
- User.
- Request views.

Request status values:

```txt
CREATED
RESPONDED
ACCEPTED
CANCELLED
EXPIRED
```

Business rules:

- Owners can view relevant requests.
- Owners may submit offers.
- UI maps request + offer state into friendly owner states.

## 12.15 RequestView

Purpose:

- Tracks owner views of a request.

Key fields:

- `requestId`.
- `userId`.
- `status`.

Business rules:

- Helps distinguish new vs viewed requests in owner UI.

## 12.16 Offer

Purpose:

- Owner response to a renter request.

Key fields:

- `status`.
- `price`.
- `priceRate`.
- `comment`.

Relations:

- Request.
- Equipment.
- Bookings.

Offer status values:

```txt
CREATED
ACCEPTED
REJECTED
CANCELLED
EXPIRED
```

Business rules:

- [Confirmed] Owner should have one active offer per request at a time.
- Accepted offer may lead to booking creation.

## 12.17 Booking

Purpose:

- Confirmed reservation/work order.

Key fields:

- `status`.
- `workStatus`.
- `bookedOn`.
- `bookedAt`.
- `price`.
- `priceRate`.
- `comment`.
- `instructions`.
- Cancel comments.

Relations:

- User.
- Equipment.
- Location.
- Ratings.
- Offer.

Booking status values:

```txt
DRAFT
CREATED
CONFIRMED
REJECTED
CANCELLED
FAILED
COMPLETED
```

Business rules:

- Client creates booking.
- Owner accepts or rejects.
- Work status tracks operational progress.
- Final statuses include completed, rejected, cancelled, failed.

## 12.18 Favorite

Purpose:

- User saves equipment.

Business rules:

- Unique pair: `userId + equipmentId`.

## 12.19 Image

Purpose:

- Stores uploaded image metadata/URL.

Key fields:

- `name`.
- `imageUrl`.
- `service`.
- `isPublic`.
- `userId`.
- `equipmentId`.

Business rules:

- `service` distinguishes image purpose: application, category, equipment, user, workCompletion, etc.
- Equipment images link through `equipmentId`.
- Category image can link through `imageId` on category.

## 12.20 Rating

Purpose:

- Stores review/rating after a booking.

Key fields:

- `ratingStars`.
- `review`.
- `bookingId`.

Business rules:

- Owner/equipment profile may show rating average/count derived from ratings.

## 12.21 OwnerRegistrationRequest

Purpose:

- Initial owner registration request.

Current uploaded schema fields:

- `companyName`.
- `firstName`.
- `lastName`.
- `iin`.

[Open Question] Earlier project discussion included a richer `OwnerProfile` model with owner type, legal name, BIN/IIN, verification fields, service description, service cities, admin comment, rating, completed order count, and status. The current uploaded schema does not include that full model. Decide whether to add `OwnerProfile` or extend existing organization models.

## 12.22 Organization Models

Models:

- `Organization`.
- `OrganizationUser`.
- `OrganizationRequest`.
- `OrganizationInvite`.

Purpose:

- Manage business/organization accounts, membership, and invitations.

Business rules:

- May overlap with owner profile/business owner flows.
- Needs decision on whether owner companies should use `OwnerProfile`, `Organization`, or both.

## 12.23 Chat

Purpose:

- Conversation between client and owner.

Key fields:

- `bookingId`.
- `requestId`.
- `clientId`.
- `ownerId`.
- `lastMessageAt`.

Business rules:

- Chat may link to either booking or request.
- Client and owner are participant IDs.
- Chat list should sort by `lastMessageAt` / updated time.

## 12.24 ChatMessage

Purpose:

- Individual chat message.

Fields:

- `chatId`.
- `senderId`.
- `type`.
- `content`.
- `meta`.
- `createdAt`.

Message types:

```txt
TEXT
IMAGE
LOCATION
SYSTEM
```

Business rules:

- `meta` can store flexible data such as image URLs or location coordinates.
- Need unread tracking strategy; current schema does not show read receipts.

[Open Question] Add read receipt / participant state model for unread counts, or compute unread from last read timestamp stored elsewhere.

---

# 13. Core Workflows

## 13.1 Renter Booking Workflow

Expected flow:

1. Renter searches or browses equipment.
2. Renter opens equipment details.
3. Renter selects price/rate if multiple options exist.
4. Renter selects or creates service location.
5. Renter selects date/time.
6. Renter adds comment/instructions.
7. Renter creates booking.
8. Booking status starts as `CREATED`.
9. Owner accepts or rejects.
10. If accepted, booking becomes `CONFIRMED`.
11. Work progresses through work statuses.
12. Booking completes or is cancelled/failed.

Status path:

```txt
CREATED -> CONFIRMED -> COMPLETED
CREATED -> REJECTED
CREATED/CONFIRMED -> CANCELLED
CONFIRMED -> FAILED
```

[Assumption] `DRAFT` may be used internally before final booking creation.

## 13.2 Owner Booking Workflow

Owner can:

- View incoming bookings.
- Accept booking.
- Reject booking.
- Update work progress.
- Cancel with reason where allowed.
- Mark completed.

Work status levels discussed:

```txt
onMyWay: 1
onSite: 2
started: 3
postponed: 3
stopped: 4
completed: 5
cancelled: 5
```

Rules:

- Owner should not move work status backwards.
- Owner may skip forward where practical.
- Final states should block further normal actions.

[Open Question] Decide exact `workStatus` values to store in DB: uppercase enum-like strings, lowercase strings, or a separate enum/model.

## 13.3 Request and Offer Workflow

Expected request flow:

1. Renter creates request.
2. Request status starts as `CREATED`.
3. Owners see relevant request.
4. Owner views request; `RequestView` can track this.
5. Owner submits offer with equipment, price, rate, and comment.
6. Request may become `RESPONDED`.
7. Renter accepts an offer.
8. Offer becomes `ACCEPTED`.
9. Request becomes `ACCEPTED`.
10. Booking may be created from accepted offer.

Owner UI state mapping:

```txt
newRequest: request CREATED and no offer/view
viewed: request viewed and no offer
offerSent: offer exists and is active
accepted: request or offer accepted
```

[Confirmed] Status comparisons in Flutter should be case-insensitive where data may vary.

## 13.4 Equipment Creation and Management Workflow

Expected flow:

1. Owner creates equipment with minimal required data.
2. Owner opens equipment detail screen.
3. Owner edits details.
4. Owner adds prices.
5. Owner adds or confirms location.
6. Owner uploads images.
7. Owner fills category-specific specs.
8. Owner sets status/visibility.
9. Equipment becomes visible to renters when valid and visible.

Important components:

- `OwnerEquipmentDetailScreen`.
- `EditEquipmentDetailsForm`.
- `OwnerEquipmentSpecs` planned component.
- `OwnerEquipmentImageHeader`.
- Reusable edit sheets.

## 13.5 Equipment Specs Workflow

Goal:

- Owner fills spec values for equipment based on admin-defined category specs.

Planned mobile component:

```txt
OwnerEquipmentSpecs
```

Expected behavior:

- Receives equipment from main screen.
- Uses `Equipment` and `EquipmentSpec` models.
- Displays `equipment.specs`.
- Highlights required specs where supported.
- Lets owner enter values.
- Tracks `isDirty` similar to `EditEquipmentDetailsForm`.
- Enables Save only when changed.
- Sends update in one batch:

```json
{
  "equipmentId": "...",
  "specs": [
    { "specId": "...", "value": "..." }
  ]
}
```

Backend should:

- Validate owner owns equipment.
- Validate category specs belong to equipment category.
- Upsert/update spec values.
- Return updated equipment/spec DTO.

## 13.6 Equipment Image Workflow

Goal:

- Owners upload multiple images for each equipment item.

Expected mobile flow:

1. Owner opens `OwnerEquipmentDetailScreen`.
2. `OwnerEquipmentImageHeader` displays current images.
3. Owner taps camera icon.
4. Bottom sheet/drawer opens.
5. Owner chooses gallery or camera.
6. Mobile sends image file to backend.
7. Backend validates ownership and image count.
8. Backend uploads to Supabase.
9. Backend creates `Image` record linked to equipment.
10. Mobile refreshes equipment/image state.

Rules:

- [Assumption] Limit is initially 5 images per equipment.
- Header should support 0 images, 1 image, and multiple images.
- Multiple images should be swipeable/carousel-style.
- Backend should own upload and DB write.
- Mobile should not directly decide final public URL format.

Recommended Supabase path pattern:

```txt
user-content/equipment/{equipmentId}/{imageId-or-fileName}.jpg
```

[Open Question] Decide whether first image is explicitly marked primary, or first by sort order/created date is used as cover.

## 13.7 Map and Location Workflow

Map modes discussed:

```txt
browseEquipment
pickLocation
ownerPlaceEquipment
```

Expected renter map flow:

- Show equipment pins.
- Use Mapbox map on mobile.
- Tap marker to open equipment preview/details.
- Use fallback list on non-mobile.

Expected owner equipment location flow:

- Owner places equipment base pin.
- Map pin creates/updates location with service `EQUIPMENT`.
- Backend reverse geocodes if needed.

Expected address flow:

- User can create saved addresses manually or via map.
- Address location uses service `ADDRESS`.
- Booking/request uses selected location.

Known map technical notes:

- Use `Position(longitude, latitude)` with Mapbox.
- Do not confuse longitude and latitude ordering.
- `MapController` should be a class, while `mapControllerProvider` should be the Riverpod provider instance.
- Avoid reading a class type as a Riverpod provider.
- Dispose map annotation manager/controller correctly.

## 13.8 Chat Workflow

Expected flow:

1. User opens chat list.
2. App loads chat summaries.
3. User opens chat.
4. App fetches chat details by ID.
5. App loads last 50 messages.
6. Notifier checks if chat exists in state.
7. If exists, replace/update it.
8. If not, add it.
9. Messages send/receive using `socket_io_client`.
10. Last message and unread counts update chat list.

Backend requirements:

- `getChats` returns summary list.
- `getChatById` returns full chat detail and recent messages.
- Socket events should update `lastMessageAt`.

[Open Question] Decide unread count storage model.

---

# 14. Status and Workflow Rules

## 14.1 Flutter Status Handling

[Confirmed] Flutter should generally store important backend statuses as strings rather than strict enums, especially where backend enums are still changing.

Rules:

- Compare case-insensitively.
- Display user-friendly labels separately.
- Avoid crashing on unknown status.
- Add fallback style/label for unknown status.

## 14.2 Booking Statuses

Current schema values:

```txt
DRAFT
CREATED
CONFIRMED
REJECTED
CANCELLED
FAILED
COMPLETED
```

Earlier mobile discussions also referenced `INPROGRESS`.

[Open Question] Decide whether `INPROGRESS` should be added to `BookingStatus` or represented only by `workStatus`.

Recommended direction:

- Keep booking lifecycle in `status`.
- Keep operational progress in `workStatus`.
- Avoid adding too many overlapping booking statuses.

## 14.3 Request Statuses

```txt
CREATED
RESPONDED
ACCEPTED
CANCELLED
EXPIRED
```

## 14.4 Offer Statuses

```txt
CREATED
ACCEPTED
REJECTED
CANCELLED
EXPIRED
```

## 14.5 Equipment Statuses

```txt
DRAFT
CREATED
ACCEPTED
REJECTED
AVAILABLE
BOOKED
MAINTENANCE
DISABLED
ARCHIVED
```

[Open Question] Some equipment statuses look like moderation workflow states (`CREATED`, `ACCEPTED`, `REJECTED`) while others are operational availability states (`AVAILABLE`, `BOOKED`, `MAINTENANCE`). Decide whether to split moderation status and availability status later.

---

# 15. File Storage Strategy

## 15.1 Storage Provider

Use Supabase Storage for uploaded images and documents.

## 15.2 Upload Responsibility

[Confirmed] Backend should handle upload and saving URL to database for important app flows.

Mobile should:

- Select file/image.
- Send multipart upload to backend.
- Show progress/loading/error.
- Refresh state from backend response.

Backend should:

- Validate authenticated actor.
- Validate ownership/permission.
- Validate file type and size.
- Upload to Supabase.
- Save `Image` or `Document` record.
- Return DTO.

## 15.3 Buckets and Paths

Recommended bucket:

```txt
user-content
```

Recommended path examples:

```txt
profiles/{userId}/avatar.jpg
equipment/{equipmentId}/{imageId}.jpg
categories/{categoryId}/{imageId}.jpg
owner-documents/{ownerId}/{documentId}.pdf
work-completion/{bookingId}/{imageId}.jpg
```

## 15.4 Allowed Image Types

Expected allowed types:

```txt
png
jpg
jpeg
```

[Future] Add WebP if image pipeline supports it.

---

# 16. Dictionary and Localization System

## 16.1 Purpose

The dictionary system manages static data and localized text/options for the app.

Target languages:

- English.
- Russian.
- Kazakh.

## 16.2 Use Cases

Dictionary may support:

- Form labels.
- Page labels.
- Email text.
- Static select options.
- Category-related display values.
- Status labels.
- Admin-managed text.

## 16.3 Admin Management

Admin should be able to:

- Create dictionary entries.
- Edit entries.
- Activate/deactivate entries.
- Sort entries.
- Import/export using Excel.

## 16.4 Guidance

[Confirmed] Avoid hardcoding static options in mobile where dictionary-driven data is appropriate.

[Open Question] Decide final dictionary schema shape and whether dictionary options are separate records or embedded JSON/array fields.

---

# 17. Non-Functional Requirements

## 17.1 Reliability

- Avoid partial writes for critical workflows.
- Use transactions where needed.
- Return clear error messages.
- Handle null/invalid backend data safely in Flutter.

## 17.2 Performance

- Paginate admin tables and mobile lists where needed.
- Use cached images for remote images.
- Avoid loading full chat history by default; load last 50 messages initially.
- Avoid rendering very heavy map overlays without clustering/filtering later.

## 17.3 Security

- Use bearer session token.
- Validate ownership on backend.
- Do not let owners edit equipment they do not own.
- Do not expose sensitive user/session/password fields in DTOs.
- Store OTP hashes instead of raw codes where possible.
- Do not store payment data in app.

## 17.4 Maintainability

- Keep feature folders modular.
- Reuse provider/notifier/service patterns.
- Reuse admin table/form/import/export patterns.
- Use DTO functions for nested response shape.
- Mark assumptions before implementing unclear logic.

## 17.5 Localization

- Plan for English, Russian, and Kazakh.
- Avoid hardcoded visible user text where dictionary/localization should own it.
- Keep status internal values separate from translated labels.

---

# 18. Known Technical Decisions

## Confirmed Decisions

- [Confirmed] Flutter uses Riverpod, Dio, and GoRouter.
- [Confirmed] Backend uses Node/Express, Prisma, and PostgreSQL.
- [Confirmed] Supabase Storage is used for images/documents.
- [Confirmed] Mapbox is used for maps/geocoding/location flows.
- [Confirmed] Mobile should store full `AuthSession` JSON in secure storage.
- [Confirmed] Backend error messages should be propagated to Flutter UI.
- [Confirmed] Flutter should avoid hardcoded component colors and use theme/color scheme.
- [Confirmed] Price display should use integer KZT formatting with space thousand separators and no fractions.
- [Confirmed] Owner equipment images should be uploaded through backend, with backend saving URL to DB.
- [Confirmed] Admin pages should reuse categories page structure where practical.
- [Confirmed] Future AI agents should read project docs and schema before coding.

## Current Assumptions

- [Assumption] Equipment image limit is initially 5 images per equipment.
- [Assumption] Equipment has one active/base location for now, despite possible future location history.
- [Assumption] `workStatus` will handle booking progress instead of adding many booking statuses.
- [Assumption] Category specs will eventually include `isRequired` even if current uploaded schema does not show it.
- [Assumption] Owner profile model will become richer than current `OwnerRegistrationRequest` schema.
- [Assumption] Organization models may support business owners later, but the exact relationship to owner profile is not finalized.

## Open Questions

- [Open Question] Should owner companies be represented through `OwnerProfile`, `Organization`, or both?
- [Open Question] Should `CategorySpec` include `key`, `iconLibrary`, and `isRequired`?
- [Open Question] Should equipment specs be created when equipment is created, or generated lazily when editing specs?
- [Open Question] Should equipment images support explicit primary image and sort order?
- [Open Question] Should equipment moderation status and availability status be split?
- [Open Question] Should booking include `INPROGRESS` status, or should progress remain only in `workStatus`?
- [Open Question] How should unread chat counts be persisted?
- [Open Question] What is the final owner cancellation grace period?
- [Open Question] Which admin actions require audit logging in Phase 1?

## Future Ideas

- [Future] Support dashboard role.
- [Future] Advanced admin reports.
- [Future] Work completion image uploads.
- [Future] Full owner/admin web tools.
- [Future] Better map marker clustering.
- [Future] Push notifications.
- [Future] Payment integration.
- [Future] Public web listing pages.

---

# 19. Known Bugs and Pitfalls

## Auth Pitfalls

- `Authorization: Bearer null` can happen if secure storage parsing or session token extraction is wrong.
- Do not `jsonDecode` the token itself.
- Dio interceptor should not swallow useful backend error bodies.

## Router Pitfalls

- Avoid triggering provider mutations inside router creation.
- Avoid startup redirect loops.
- Initialize startup controller once.

## Flutter Parsing Pitfalls

- Backend may return unexpected nulls or non-list data.
- Guard `fromJson` parsing.
- Ensure `categoryId` is parsed on equipment models.
- Handle `int` vs `double` safely.

## Status Pitfalls

- Backend enum strings may change.
- Flutter should avoid strict enum crashes.
- Compare case-insensitively.

## Map Pitfalls

- Mapbox uses longitude, latitude order in `Position`.
- Do not read a controller class type as a Riverpod provider.
- Create a provider instance, e.g. `mapControllerProvider`.
- Dispose map-related managers safely.

## Admin Pitfalls

- Revalidate calls must match the expected Next.js function signature.
- Avoid mixing dictionary fields with nested relation fields incorrectly.
- Keep server-rendered pages server-rendered where intended.

## Upload Pitfalls

- Validate file exists before upload.
- Validate owner owns equipment before upload.
- Check equipment image count before upload.
- Ensure Supabase path is valid.
- Save DB image record only after successful upload, or handle cleanup if DB write fails.

---

# 20. AI Agent Notes

Future AI agents should follow these rules before coding:

1. Read this PRD first.
2. Read `schema.prisma` before touching backend or admin pages.
3. Search existing feature folders before creating new patterns.
4. Reuse existing service/provider/notifier structure in Flutter.
5. Reuse existing admin categories pattern for admin CRUD modules.
6. Keep business rules in backend services where possible.
7. Do not hardcode colors; use Flutter theme/color scheme.
8. Do not hardcode statuses without checking backend schema.
9. Treat Flutter statuses as strings unless the project owner explicitly asks for enums.
10. Mark assumptions before implementing unclear business logic.
11. Do not implement broad unrelated refactors while working on one feature.
12. Keep mobile, backend, and admin responsibilities separate.
13. For upload features, backend should validate, upload, save DB record, and return DTO.
14. For complex features, create a plan first before coding.
15. If a model or field differs between chat history and `schema.prisma`, mention the mismatch clearly.

---

# 21. Suggested Supporting Docs

This PRD should remain broad and product-focused. Detailed technical docs can be split later.

Recommended docs:

```txt
/docs/PRD.md
/docs/ARCHITECTURE.md
/docs/DATA_MODEL.md
/docs/API_GUIDE.md
/docs/AI_AGENT_GUIDE.md
/docs/FEATURES/auth.md
/docs/FEATURES/booking.md
/docs/FEATURES/equipment.md
/docs/FEATURES/equipment-images.md
/docs/FEATURES/category-specs.md
/docs/FEATURES/requests-offers.md
/docs/FEATURES/map.md
/docs/FEATURES/chat.md
/docs/FEATURES/admin.md
/docs/FEATURES/dictionary.md
```

## What stays in PRD

- Product goals.
- Roles.
- Workflows.
- High-level architecture.
- Business rules.
- Feature map.
- Decisions, assumptions, open questions.

## What moves to architecture docs

- Folder structures.
- Provider patterns.
- DTO examples.
- Service layering.
- Router design.
- Deployment details.

## What moves to feature docs

- Booking status machine.
- Equipment image upload implementation.
- Mapbox controller/annotation details.
- Chat socket events.
- Admin CRUD/import/export implementation.

---

# 22. Glossary

## Renter / Client

A user who needs equipment or services.

## Owner / Provider

A user or company that provides equipment services.

## Equipment

A rentable machine or service vehicle listed by an owner.

## Category

Admin-defined service/equipment type such as vacuum truck, crane, forklift, tow truck, or excavator.

## Category Spec

Admin-defined technical attribute template for a category.

## Equipment Spec

Actual value filled by an owner for a category spec on one equipment item.

## Booking

A confirmed or pending reservation/work order for a specific equipment item.

## Request

A renter-created demand that owners can respond to with offers.

## Offer

Owner response to a request, including equipment and price.

## Work Status

Operational progress inside a booking, such as on my way, on site, started, completed, or cancelled.

## Dictionary

Admin-managed static data/localization system for labels, options, and text.

---

# 23. Execution Checklist for Updating This PRD

Use this checklist whenever this PRD is updated:

- [ ] Read latest `schema.prisma`.
- [ ] Check recent project chats for changed decisions.
- [ ] Update status values if backend enum changed.
- [ ] Update open questions if decisions were made.
- [ ] Move resolved assumptions into confirmed decisions.
- [ ] Add new known bugs/pitfalls.
- [ ] Add new admin modules if planned.
- [ ] Add new mobile feature flows if planned.
- [ ] Keep business logic separate from implementation code.
- [ ] Keep the document readable for AI agents.


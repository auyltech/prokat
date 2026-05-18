---
type: project-map
project: Prokat
tags:
  - prokat
  - project-map
  - screens
  - obsidian-graph
---

# Prokat Screens Graph Map

#prokat #screens #project-map

This file maps the main screens of [[Prokat Mobile App]] and [[Prokat Web Admin]] using Obsidian internal links.

---

## Main User Roles

- [[Guest User]]
- [[Client User]]
- [[Owner User]]
- [[Admin User]]
- [[Support User]]

---

# Mobile App

## [[Prokat Mobile App]]

The mobile app is used by [[Client User]] and [[Owner User]].

Connected areas:

- [[Authentication Module]]
- [[Client Module]]
- [[Owner Module]]
- [[Equipment Module]]
- [[Booking Module]]
- [[Request Module]]
- [[Offer Module]]
- [[Chat Module]]
- [[Map Module]]
- [[Notification Module]]
- [[Review Module]]

---

# Authentication Screens

## [[Authentication Module]]

Related screens:

- [[Login Screen]]

---

## [[Launch Screen]]

#screen #mobile #auth

The startup screen that decides where the user should go after app launch.

Links:

- belongs to [[Authentication Module]]
- redirects to [[Client Dashboard]]
- redirects to [[Owner Dashboard]]
- redirects to [[Main Search Screen]]
- checks [[Auth Session]]
- checks [[App Startup Provider]]

Purpose:

- restore saved session
- load startup data
- check user role
- redirect client, owner, or guest

---

## [[Register Screen]]

#screen #mobile #auth

Allows new users to create an account.

Links:

- belongs to [[Authentication Module]]
- related to [[Client User]]
- related to [[Owner Registration Flow]]
- may open [[OTP Screen]]

Purpose:

- create new user account
- begin client or owner onboarding

---

## [[OTP Screen]]

#screen #mobile #auth

Used for phone verification.

Links:

- belongs to [[Authentication Module]]
- related to [[Phone OTP Flow]]
- creates [[Auth Session]]

Purpose:

- verify OTP code
- continue interrupted OTP login
- create or restore session

---

# Client Screens

## [[Client Module]]

Related screens:

- [[Client Dashboard]]
- [[Main Search Screen]]
- [[Equipment List Screen]]
- [[Equipment Map Screen]]
- [[Equipment Booking Screen]]
- [[Client Requests Screen]]
- [[Create Request Screen]]
- [[Client Orders Screen]]
- [[Client Booking Detail Screen]]
- [[Favorites Screen]]

Related modules:

- [[Equipment Module]]
- [[Booking Module]]
- [[Request Module]]
- [[Offer Module]]
- [[Chat Module]]
- [[Review Module]]

---

## [[Client Dashboard]]

#screen #mobile #client

Main home screen for the client.

Links:

- belongs to [[Client Module]]
- opens [[Equipment List Screen]]
- opens [[Equipment Map Screen]]
- opens [[Create Request Screen]]
- opens [[Client Orders Screen]]
- opens [[Chats Screen]]

Purpose:

- client landing page
- quick access to search, requests, bookings, and chats

---

## [[Main Search Screen]]

#screen #mobile #client #equipment

Guest/client entry point for browsing equipment.

Links:

- belongs to [[Client Module]]
- related to [[Equipment Module]]
- opens [[Equipment List Screen]]
- opens [[Equipment Map Screen]]
- opens [[Equipment Preview Sheet]]

Purpose:

- browse available equipment
- search and filter equipment
- open equipment preview or booking

---

## [[Equipment List Screen]]

#screen #mobile #client #equipment

List-based equipment browsing screen.

Links:

- belongs to [[Equipment Module]]
- used by [[Client User]]
- used by [[Guest User]]
- alternative to [[Equipment Map Screen]]
- opens [[Equipment Booking Screen]]
- opens [[Equipment Preview Sheet]]

Purpose:

- show equipment as cards/list
- support filters
- fallback when map is unavailable

---

## [[Equipment Map Screen]]

#screen #mobile #client #map #equipment

Map-based equipment browsing screen.

Links:

- belongs to [[Map Module]]
- belongs to [[Equipment Module]]
- uses [[MyMapView]]
- uses [[Map Controller]]
- shows [[Equipment Marker]]
- opens [[Equipment Preview Sheet]]
- alternative to [[Equipment List Screen]]

Purpose:

- show equipment geographically
- display equipment markers
- open preview sheet when equipment is selected

---

## [[Equipment Preview Sheet]]

#component #mobile #client #equipment

Bottom sheet or drawer showing quick equipment information.

Links:

- belongs to [[Equipment Module]]
- opened from [[Equipment Map Screen]]
- opened from [[Equipment List Screen]]
- opens [[Equipment Booking Screen]]
- related to [[Favorites Screen]]

Purpose:

- show image, name, model, capacity, location, and price
- allow favorite toggle
- allow booking CTA

---

## [[Equipment Booking Screen]]

#screen #mobile #client #booking

Screen where a client creates a booking.

Links:

- belongs to [[Booking Module]]
- opened from [[Equipment Preview Sheet]]
- opened from [[Equipment List Screen]]
- creates [[Booking]]
- may create [[Booking Chat]]
- related to [[Price Negotiation Flow]]

Purpose:

- choose date and time
- choose price/rate
- choose service location
- add instructions
- submit booking in `CREATED` status

---

## [[Create Request Screen]]

#screen #mobile #client #request

Screen where a client creates a request for equipment/service.

Links:

- belongs to [[Request Module]]
- opened from [[Client Dashboard]]
- creates [[Request]]
- can receive [[Offer]]
- related to [[Offer Negotiation Flow]]

Purpose:

- create a service request
- define category, specs, location, date/time, and offered price
- allow owners to send offers

---

## [[Client Requests Screen]]

#screen #mobile #client #request

Shows requests created by the client.

Links:

- belongs to [[Request Module]]
- shows [[Request]]
- shows [[Offer]]
- related to [[Offer Negotiation Flow]]
- may lead to [[Booking]]

Purpose:

- view active and past requests
- accept or reject owner offers
- negotiate offer price

---

## [[Client Orders Screen]]

#screen #mobile #client #booking

Shows client bookings/orders.

Links:

- belongs to [[Booking Module]]
- opens [[Client Booking Detail Screen]]
- related to [[Booking Flow]]
- related to [[Work Status Flow]]
- related to [[Review Flow]]

Purpose:

- list client bookings
- show status
- open booking details
- continue booking lifecycle

---

## [[Client Booking Detail Screen]]

#screen #mobile #client #booking

Detailed client view of one booking.

Links:

- belongs to [[Booking Module]]
- related to [[Booking Action Controller]]
- related to [[Price Negotiation Flow]]
- related to [[Work Status Flow]]
- related to [[Review Flow]]
- opens [[Chat Detail Screen]]

Purpose:

- view equipment, owner, location, price, and booking status
- accept/reject counter offer
- confirm completed work
- submit review

---

## [[Favorites Screen]]

#screen #mobile #client #equipment

Shows client’s saved equipment.

Links:

- belongs to [[Client Module]]
- related to [[Equipment Module]]
- opened from [[Client Dashboard]]
- opens [[Equipment Preview Sheet]]
- opens [[Equipment Booking Screen]]

Purpose:

- list favorite equipment
- remove favorites
- open equipment details or booking

---

# Owner Screens

## [[Owner Module]]

Related screens:

- [[Owner Dashboard]]
- [[Owner Equipment List Screen]]
- [[Owner Equipment Detail Screen]]
- [[Owner Bookings Screen]]
- [[Owner Booking Detail Screen]]
- [[Owner Requests Screen]]
- [[Owner Profile Screen]]
- [[Owner Payments Screen]]
- [[Owner Addresses Screen]]
- [[Owner Pin Location Map Screen]]

Related modules:

- [[Equipment Module]]
- [[Booking Module]]
- [[Request Module]]
- [[Offer Module]]
- [[Owner Registration Flow]]
- [[Review Module]]

---

## [[Owner Dashboard]]

#screen #mobile #owner

Main home screen for the owner.

Links:

- belongs to [[Owner Module]]
- opens [[Owner Equipment List Screen]]
- opens [[Owner Bookings Screen]]
- opens [[Owner Requests Screen]]
- opens [[Owner Profile Screen]]
- opens [[Owner Payments Screen]]
- opens [[Chats Screen]]

Purpose:

- owner landing page
- show important owner shortcuts
- show pending actions

---

## [[Owner Equipment List Screen]]

#screen #mobile #owner #equipment

Shows equipment owned by the logged-in owner.

Links:

- belongs to [[Owner Module]]
- belongs to [[Equipment Module]]
- opens [[Owner Equipment Detail Screen]]
- related to [[Equipment Visibility]]
- related to [[Equipment Status]]

Purpose:

- list owner equipment
- show status and visibility
- open detail management screen
- create new equipment

---

## [[Owner Equipment Detail Screen]]

#screen #mobile #owner #equipment

Main management screen for one equipment item.

Links:

- belongs to [[Owner Module]]
- belongs to [[Equipment Module]]
- contains [[Owner Equipment Image Header]]
- contains [[Owner Equipment Info Section]]
- contains [[Owner Equipment Specs Section]]
- contains [[Owner Equipment Pricing Section]]
- contains [[Owner Equipment Location Section]]
- contains [[Owner Equipment Visibility Section]]
- contains [[Delete Equipment Section]]

Purpose:

- manage equipment details
- manage images
- manage prices
- manage location
- manage specs
- manage visibility/status

---

## [[Owner Equipment Image Header]]

#component #mobile #owner #equipment #media

Image header for owner equipment.

Links:

- belongs to [[Owner Equipment Detail Screen]]
- related to [[Equipment Images]]
- related to [[Media Settings]]
- related to [[Supabase Storage]]

Purpose:

- show equipment images
- upload images
- support gallery/camera upload
- later support multiple images/swipeable header

---

## [[Owner Equipment Info Section]]

#component #mobile #owner #equipment

Editable basic equipment info section.

Links:

- belongs to [[Owner Equipment Detail Screen]]
- related to [[Equipment Model]]

Purpose:

- edit name
- edit model
- edit capacity
- edit rent condition
- edit owner comment
- track dirty state before save

---

## [[Owner Equipment Specs Section]]

#component #mobile #owner #equipment #specs

Technical specs editor for owner equipment.

Links:

- belongs to [[Owner Equipment Detail Screen]]
- related to [[Category Spec]]
- related to [[Equipment Spec]]
- related to [[Equipment Module]]

Purpose:

- show category-driven specs
- allow owner to fill values
- validate required specs
- save specs in one update

---

## [[Owner Equipment Pricing Section]]

#component #mobile #owner #equipment #pricing

Price management section for equipment.

Links:

- belongs to [[Owner Equipment Detail Screen]]
- related to [[Price Entry]]
- related to [[Booking Pricing]]

Purpose:

- add price rate
- edit price rate
- delete price rate
- limit number of price entries

---

## [[Owner Equipment Location Section]]

#component #mobile #owner #equipment #map

Location management section for equipment.

Links:

- belongs to [[Owner Equipment Detail Screen]]
- opens [[Owner Addresses Screen]]
- opens [[Owner Pin Location Map Screen]]
- related to [[Map Module]]
- related to [[Equipment Location]]

Purpose:

- assign saved location
- pin equipment on map
- update equipment location

---

## [[Owner Equipment Visibility Section]]

#component #mobile #owner #equipment

Controls equipment visibility and status.

Links:

- belongs to [[Owner Equipment Detail Screen]]
- related to [[Equipment Visibility]]
- related to [[Equipment Status]]
- related to [[Owner Payments Screen]]

Purpose:

- toggle visible/hidden
- set available/unavailable
- eventually connect visibility to paid online status

---

## [[Delete Equipment Section]]

#component #mobile #owner #equipment

Danger zone for equipment deletion.

Links:

- belongs to [[Owner Equipment Detail Screen]]
- related to [[Equipment Module]]

Purpose:

- delete equipment
- confirm destructive action

---

## [[Owner Addresses Screen]]

#screen #mobile #owner #map

Shows saved owner addresses.

Links:

- belongs to [[Owner Module]]
- related to [[Map Module]]
- opens [[Create Owner Address Screen]]
- opens [[Owner Pin Location Map Screen]]
- used by [[Owner Equipment Location Section]]

Purpose:

- manage saved owner locations
- reuse addresses for equipment

---

## [[Create Owner Address Screen]]

#screen #mobile #owner #map

Creates a new saved owner address.

Links:

- belongs to [[Owner Addresses Screen]]
- related to [[Equipment Location]]

Purpose:

- enter city/region/address label
- save location for later use

---

## [[Owner Pin Location Map Screen]]

#screen #mobile #owner #map

Map screen for selecting a pin location.

Links:

- belongs to [[Map Module]]
- used by [[Owner Addresses Screen]]
- used by [[Owner Equipment Location Section]]
- uses [[MyMapView]]

Purpose:

- select coordinates on map
- save pinned location
- optionally reverse geocode selected point

---

## [[Owner Bookings Screen]]

#screen #mobile #owner #booking

Shows bookings received by owner.

Links:

- belongs to [[Owner Module]]
- belongs to [[Booking Module]]
- opens [[Owner Booking Detail Screen]]
- related to [[Booking Flow]]
- related to [[Price Negotiation Flow]]
- related to [[Work Status Flow]]

Purpose:

- view owner bookings
- accept/reject bookings
- send counter offers
- update work status

---

## [[Owner Booking Detail Screen]]

#screen #mobile #owner #booking

Detailed owner view of one booking.

Links:

- belongs to [[Booking Module]]
- contains [[Booking Action Controller]]
- opens [[Chat Detail Screen]]
- related to [[Price Negotiation Flow]]
- related to [[Work Status Flow]]
- related to [[Review Flow]]

Purpose:

- view booking details
- accept/reject booking
- counter offer
- start/update/complete work
- review client after completion

---

## [[Booking Action Controller]]

#component #mobile #booking #chat

Shortcut action controller shown from booking or chat.

Links:

- belongs to [[Booking Module]]
- belongs to [[Chat Module]]
- used by [[Client Booking Detail Screen]]
- used by [[Owner Booking Detail Screen]]
- used by [[Chat Detail Screen]]
- related to [[Price Negotiation Flow]]
- related to [[Work Status Flow]]
- related to [[Review Flow]]

Purpose:

- owner accepts/rejects/counters booking
- client accepts/rejects counter offer
- owner updates work status
- client confirms completion
- both sides can access booking actions from chat

---

## [[Owner Requests Screen]]

#screen #mobile #owner #request

Shows client requests available to owner.

Links:

- belongs to [[Owner Module]]
- belongs to [[Request Module]]
- opens [[Owner Send Offer Sheet]]
- related to [[Offer Module]]
- related to [[Offer Negotiation Flow]]

Purpose:

- view client requests
- send offer
- hide/view request
- track request state

---

## [[Owner Send Offer Sheet]]

#component #mobile #owner #offer

Sheet/modal used by owner to send offer on a request.

Links:

- belongs to [[Offer Module]]
- opened from [[Owner Requests Screen]]
- creates [[Offer]]
- related to [[Offer Negotiation Flow]]

Purpose:

- select equipment
- enter price and rate
- send offer to client

---

## [[Owner Profile Screen]]

#screen #mobile #owner #profile

Owner profile and registration screen.

Links:

- belongs to [[Owner Module]]
- related to [[Owner Profile]]
- related to [[Owner Registration Flow]]
- contains [[Owner Documents Section]]

Purpose:

- edit owner profile
- show registration status
- show verification/admin comments
- manage owner business/contact info

---

## [[Owner Documents Section]]

#component #mobile #owner #documents

Document upload section for owner verification.

Links:

- belongs to [[Owner Profile Screen]]
- related to [[Owner Registration Flow]]
- related to [[Document Settings]]
- related to [[Supabase Storage]]

Purpose:

- upload required documents
- upload optional documents
- follow admin document settings

---

## [[Owner Payments Screen]]

#screen #mobile #owner #payments

Owner balance and visibility payment screen.

Links:

- belongs to [[Owner Module]]
- related to [[Equipment Visibility]]
- related to [[Business Settings]]
- related to [[Payment Module]]

Purpose:

- show balance
- show remaining visibility time
- future payment/top-up management

---

# Shared Mobile Screens

## [[Chats Screen]]

#screen #mobile #chat

Shows user conversations.

Links:

- belongs to [[Chat Module]]
- opens [[Chat Detail Screen]]
- related to [[Booking Chat]]
- related to [[Request Chat]]

Purpose:

- list conversations
- open chat thread

---

## [[Chat Detail Screen]]

#screen #mobile #chat

Conversation screen between client and owner.

Links:

- belongs to [[Chat Module]]
- contains [[Booking Action Controller]]
- related to [[Booking Module]]
- related to [[Request Module]]
- related to [[Offer Module]]
- related to [[Socket.IO]]

Purpose:

- send and receive messages
- show booking/request context
- show booking event messages
- allow booking shortcuts from chat

---

## [[Notifications Screen]]

#screen #mobile #notifications

Shows user notifications.

Links:

- belongs to [[Notification Module]]
- related to [[Booking Module]]
- related to [[Request Module]]
- related to [[Offer Module]]
- related to [[Chat Module]]

Purpose:

- show booking updates
- show request/offer updates
- show chat notifications
- later connect push notifications

---

## [[Settings Screen]]

#screen #mobile #settings

User settings screen.

Links:

- belongs to [[Settings Module]]
- related to [[Theme Settings]]
- related to [[Language Settings]]
- related to [[Notification Settings]]

Purpose:

- manage language
- manage theme
- manage account/session settings
- manage notification preferences

---

# Web Admin Screens

## [[Prokat Web Admin]]

The web admin app is used by [[Admin User]] and partly by [[Support User]].

Connected areas:

- [[Admin Dashboard]]
- [[Admin Users Module]]
- [[Admin Equipment Module]]
- [[Admin Booking Module]]
- [[Admin Request Module]]
- [[Admin Offer Module]]
- [[Admin Review Module]]
- [[Admin Settings Module]]
- [[Admin Cities Module]]
- [[Admin Logs Module]]

---

## [[Admin Dashboard]]

#screen #web #admin

Main admin overview page.

Links:

- belongs to [[Prokat Web Admin]]
- related to [[Admin Users Module]]
- related to [[Admin Equipment Module]]
- related to [[Admin Booking Module]]
- related to [[System Health]]

Purpose:

- show system summary
- show counts
- show important admin shortcuts
- future analytics/logs overview

---

## [[Admin Clients Page]]

#screen #web #admin #users

Admin page for managing client users.

Links:

- belongs to [[Admin Users Module]]
- related to [[Client User]]
- related to [[Booking Module]]
- related to [[Request Module]]

Purpose:

- list clients
- view/edit client accounts
- inspect client activity

---

## [[Admin Owners Page]]

#screen #web #admin #owners

Admin page for managing owners.

Links:

- belongs to [[Admin Users Module]]
- related to [[Owner User]]
- opens [[Admin Owner Detail Page]]
- related to [[Owner Registration Flow]]

Purpose:

- list owners
- approve/reject/suspend owners
- view owner profile status

---

## [[Admin Owner Detail Page]]

#screen #web #admin #owners

Detailed admin page for one owner.

Links:

- belongs to [[Admin Users Module]]
- opened from [[Admin Owners Page]]
- related to [[Owner Profile]]
- related to [[Owner Documents Section]]
- related to [[Owner Equipment List Screen]]

Purpose:

- inspect owner profile
- review documents
- view owner equipment
- apply admin actions

---

## [[Admin Fleet Page]]

#screen #web #admin #equipment

Admin page for all equipment.

Links:

- belongs to [[Admin Equipment Module]]
- opens [[Admin Equipment Detail Page]]
- related to [[Equipment Module]]
- related to [[Owner User]]

Purpose:

- list all equipment
- filter/search equipment
- open equipment detail
- admin edit/override equipment data

---

## [[Admin Equipment Detail Page]]

#screen #web #admin #equipment

Admin detail page for one equipment item.

Links:

- belongs to [[Admin Equipment Module]]
- opened from [[Admin Fleet Page]]
- related to [[Equipment Images]]
- related to [[Equipment Spec]]
- related to [[Price Entry]]
- related to [[Equipment Location]]

Purpose:

- view equipment details
- manage equipment info
- inspect images, prices, specs, and location
- override data if required

---

## [[Admin Categories Page]]

#screen #web #admin #categories

Admin page for equipment categories.

Links:

- belongs to [[Admin Equipment Module]]
- related to [[Category]]
- opens [[Admin Category Specs Page]]
- related to [[Category Image]]
- related to [[Excel Import Export]]

Purpose:

- create/edit/delete categories
- manage category images
- import/export category data

---

## [[Admin Category Specs Page]]

#screen #web #admin #specs

Admin page for category technical specs.

Links:

- belongs to [[Admin Equipment Module]]
- related to [[Category Spec]]
- related to [[Equipment Spec]]
- related to [[Owner Equipment Specs Section]]
- related to [[Excel Import Export]]

Purpose:

- define specs per category
- set required fields
- set input type
- set units/icons/order
- control visibility to client

---

## [[Admin Bookings Page]]

#screen #web #admin #booking

Admin page for all bookings.

Links:

- belongs to [[Admin Booking Module]]
- opens [[Admin Booking Detail Page]]
- related to [[Booking Flow]]
- related to [[Price Negotiation Flow]]
- related to [[Work Status Flow]]

Purpose:

- list bookings
- filter by status/client/owner/equipment/date
- inspect booking lifecycle
- allow admin override

---

## [[Admin Booking Detail Page]]

#screen #web #admin #booking

Admin detail page for one booking.

Links:

- belongs to [[Admin Booking Module]]
- opened from [[Admin Bookings Page]]
- related to [[Booking]]
- related to [[Review]]
- related to [[Price Negotiation Flow]]
- related to [[Chat Module]]

Purpose:

- view full booking details
- inspect negotiation history
- inspect reviews
- intervene if needed

---

## [[Admin Requests Page]]

#screen #web #admin #request

Admin page for client requests.

Links:

- belongs to [[Admin Request Module]]
- related to [[Request]]
- related to [[Offer]]
- related to [[Client User]]

Purpose:

- list client requests
- inspect request status
- admin override if needed

---

## [[Admin Offers Page]]

#screen #web #admin #offer

Admin page for owner offers.

Links:

- belongs to [[Admin Offer Module]]
- related to [[Offer]]
- related to [[Request]]
- related to [[Owner User]]
- related to [[Offer Negotiation Flow]]

Purpose:

- list offers
- inspect price/rate/status
- track owner response to client requests

---

## [[Admin Reviews Page]]

#screen #web #admin #reviews

Admin page for reviews.

Links:

- belongs to [[Admin Review Module]]
- related to [[Review]]
- related to [[Review Flow]]
- related to [[Rating Average Calculation]]

Purpose:

- list submitted reviews
- inspect booking reviews
- moderate later if required
- trigger rating recalculation

---

## [[Admin Settings Page]]

#screen #web #admin #settings

Admin page for configurable project settings.

Links:

- belongs to [[Admin Settings Module]]
- related to [[Media Settings]]
- related to [[Document Settings]]
- related to [[Theme Settings]]
- related to [[Business Settings]]
- related to [[Negotiation Settings]]

Purpose:

- control image limits
- control allowed file formats
- control required documents
- control business rules
- control theme behavior
- control negotiation limits

---

## [[Admin Cities Page]]

#screen #web #admin #cities

Admin page for service cities and regions.

Links:

- belongs to [[Admin Cities Module]]
- related to [[City]]
- related to [[Service Area]]
- related to [[Equipment Location]]
- related to [[Search Filters]]

Purpose:

- manage supported cities
- start with Atyrau
- expand to regions/cities later
- control city visibility

---

## [[Admin Audit Logs Page]]

#screen #web #admin #logs

Admin page for audit logs.

Links:

- belongs to [[Admin Logs Module]]
- related to [[Audit Log]]
- related to [[Admin User]]
- related to [[Admin Override]]

Purpose:

- track sensitive actions
- track admin overrides
- track important status changes
- phase 2 feature

---

## [[Admin Backend Health Page]]

#screen #web #admin #system

Admin page for backend/system health.

Links:

- belongs to [[Admin Logs Module]]
- related to [[System Health]]
- related to [[Backend API]]
- related to [[Logger]]

Purpose:

- ping backend
- check API status
- later show database/storage health

---

# Support Screens

## [[Prokat Support Portal]]

Used by [[Support User]] with limited access.

Related screens:

- [[Support Dashboard]]
- [[Support Tickets Page]]

---

## [[Support Dashboard]]

#screen #web #support

Support landing page.

Links:

- belongs to [[Prokat Support Portal]]
- related to [[Support User]]
- related to [[Client User]]
- related to [[Owner User]]
- related to [[Booking Module]]

Purpose:

- limited operational support
- view user/booking/request issues
- avoid dangerous admin actions

---

## [[Support Tickets Page]]

#screen #web #support

Future support ticket management page.

Links:

- belongs to [[Prokat Support Portal]]
- related to [[Support Ticket]]
- related to [[Client User]]
- related to [[Owner User]]
- related to [[Booking]]

Purpose:

- manage support tickets
- link tickets to users/bookings/equipment
- phase 2 feature

---

# Business Flows

## [[Booking Flow]]

#flow #booking

Links:

- uses [[Booking Module]]
- starts from [[Equipment Booking Screen]]
- visible in [[Client Orders Screen]]
- visible in [[Owner Bookings Screen]]
- controlled by [[Booking Action Controller]]
- can create [[Booking Chat]]

Flow:

1. Client creates booking.
2. Booking starts as `CREATED`.
3. Owner accepts, rejects, or counters.
4. If both sides accept, booking becomes confirmed.
5. Owner updates work status.
6. Client confirms completion.
7. Reviews become available.

---

## [[Price Negotiation Flow]]

#flow #booking #negotiation

Links:

- belongs to [[Booking Module]]
- uses [[Price Negotiation]]
- controlled by [[Booking Action Controller]]
- visible in [[Chat Detail Screen]]
- related to [[Negotiation Settings]]

Flow:

1. Client creates booking with selected price.
2. Owner sends counter offer if needed.
3. Client accepts or rejects.
4. Either side may create another offer if allowed.
5. Backend enforces max counter offers.
6. Final accepted price is saved on booking.

---

## [[Offer Negotiation Flow]]

#flow #offer #request #negotiation

Links:

- belongs to [[Offer Module]]
- belongs to [[Request Module]]
- starts from [[Owner Send Offer Sheet]]
- visible in [[Client Requests Screen]]
- related to [[Negotiation Settings]]

Flow:

1. Client creates request.
2. Owner sends offer.
3. Client accepts, rejects, or negotiates.
4. Accepted offer can create or confirm booking.

---

## [[Work Status Flow]]

#flow #booking #work-status

Links:

- belongs to [[Booking Module]]
- controlled by [[Owner Booking Detail Screen]]
- visible in [[Client Booking Detail Screen]]
- related to [[Booking Action Controller]]

Statuses:

- [[Work Status - On My Way]]
- [[Work Status - On Site]]
- [[Work Status - Started]]
- [[Work Status - Paused]]
- [[Work Status - Completed]]
- [[Work Status - Failed]]
- [[Work Status - Cancelled]]

Rules:

- owner updates status
- status should usually move forward
- failed status requires reason
- completed status requires client confirmation

---

## [[Review Flow]]

#flow #review

Links:

- belongs to [[Review Module]]
- starts after [[Work Status Flow]]
- visible in [[Client Booking Detail Screen]]
- visible in [[Owner Booking Detail Screen]]
- managed in [[Admin Reviews Page]]
- updates [[Rating Average Calculation]]

Rules:

- client reviews owner/service
- owner reviews client
- each side should not see the other review before submitting
- average rating is recalculated after reviews or by admin trigger

---

# Backend / Data Concepts

## [[Equipment Module]]

#module #backend #mobile #web

Connected screens:

- [[Equipment List Screen]]
- [[Equipment Map Screen]]
- [[Equipment Booking Screen]]
- [[Owner Equipment List Screen]]
- [[Owner Equipment Detail Screen]]
- [[Admin Fleet Page]]
- [[Admin Equipment Detail Page]]

Connected data:

- [[Equipment]]
- [[Equipment Images]]
- [[Equipment Location]]
- [[Price Entry]]
- [[Category]]
- [[Category Spec]]
- [[Equipment Spec]]

---

## [[Booking Module]]

#module #backend #mobile #web

Connected screens:

- [[Equipment Booking Screen]]
- [[Client Orders Screen]]
- [[Client Booking Detail Screen]]
- [[Owner Bookings Screen]]
- [[Owner Booking Detail Screen]]
- [[Admin Bookings Page]]
- [[Admin Booking Detail Page]]
- [[Booking Action Controller]]

Connected flows:

- [[Booking Flow]]
- [[Price Negotiation Flow]]
- [[Work Status Flow]]
- [[Review Flow]]

---

## [[Request Module]]

#module #backend #mobile #web

Connected screens:

- [[Create Request Screen]]
- [[Client Requests Screen]]
- [[Owner Requests Screen]]
- [[Admin Requests Page]]

Connected data:

- [[Request]]
- [[Offer]]

---

## [[Offer Module]]

#module #backend #mobile #web

Connected screens:

- [[Owner Send Offer Sheet]]
- [[Client Requests Screen]]
- [[Admin Offers Page]]

Connected flows:

- [[Offer Negotiation Flow]]

---

## [[Chat Module]]

#module #backend #mobile

Connected screens:

- [[Chats Screen]]
- [[Chat Detail Screen]]
- [[Booking Action Controller]]

Connected systems:

- [[Socket.IO]]
- [[Booking Chat]]
- [[Booking Event Messages]]

---

## [[Map Module]]

#module #mobile #map

Connected screens:

- [[Equipment Map Screen]]
- [[Owner Pin Location Map Screen]]

Connected components:

- [[MyMapView]]
- [[Map Controller]]
- [[Equipment Marker]]

Connected data:

- [[Equipment Location]]
- [[City]]
- [[Service Area]]

---

## [[Review Module]]

#module #backend #mobile #web

Connected screens:

- [[Client Booking Detail Screen]]
- [[Owner Booking Detail Screen]]
- [[Admin Reviews Page]]

Connected flows:

- [[Review Flow]]
- [[Rating Average Calculation]]

---

## [[Settings Module]]

#module #mobile #web

Connected screens:

- [[Settings Screen]]
- [[Admin Settings Page]]

Connected settings:

- [[Media Settings]]
- [[Document Settings]]
- [[Theme Settings]]
- [[Business Settings]]
- [[Negotiation Settings]]

---

# Data Nodes

## [[Equipment]]

#data

Related to:

- [[Equipment Module]]
- [[Owner Equipment Detail Screen]]
- [[Admin Equipment Detail Page]]
- [[Equipment Booking Screen]]

---

## [[Booking]]

#data

Related to:

- [[Booking Module]]
- [[Booking Flow]]
- [[Client Booking Detail Screen]]
- [[Owner Booking Detail Screen]]
- [[Admin Booking Detail Page]]

---

## [[Request]]

#data

Related to:

- [[Request Module]]
- [[Create Request Screen]]
- [[Client Requests Screen]]
- [[Owner Requests Screen]]
- [[Admin Requests Page]]

---

## [[Offer]]

#data

Related to:

- [[Offer Module]]
- [[Owner Send Offer Sheet]]
- [[Client Requests Screen]]
- [[Admin Offers Page]]

---

## [[Review]]

#data

Related to:

- [[Review Module]]
- [[Review Flow]]
- [[Admin Reviews Page]]

---

## [[Owner Profile]]

#data

Related to:

- [[Owner Profile Screen]]
- [[Admin Owner Detail Page]]
- [[Owner Registration Flow]]

---

## [[Category]]

#data

Related to:

- [[Admin Categories Page]]
- [[Equipment Module]]
- [[Category Spec]]

---

## [[Category Spec]]

#data

Related to:

- [[Admin Category Specs Page]]
- [[Owner Equipment Specs Section]]
- [[Equipment Spec]]

---

## [[Equipment Spec]]

#data

Related to:

- [[Owner Equipment Specs Section]]
- [[Admin Equipment Detail Page]]
- [[Category Spec]]

---

## [[Price Entry]]

#data

Related to:

- [[Owner Equipment Pricing Section]]
- [[Equipment Booking Screen]]
- [[Booking Pricing]]

---

## [[Equipment Location]]

#data

Related to:

- [[Owner Equipment Location Section]]
- [[Equipment Map Screen]]
- [[Owner Pin Location Map Screen]]
- [[Admin Cities Page]]

---

# Settings Nodes

## [[Media Settings]]

#settings

Related to:

- [[Admin Settings Page]]
- [[Owner Equipment Image Header]]
- [[Equipment Images]]
- [[Supabase Storage]]

Controls:

- max equipment images
- allowed image formats
- profile image formats

---

## [[Document Settings]]

#settings

Related to:

- [[Admin Settings Page]]
- [[Owner Documents Section]]
- [[Owner Registration Flow]]

Controls:

- required owner documents
- optional document count
- allowed document formats

---

## [[Theme Settings]]

#settings

Related to:

- [[Admin Settings Page]]
- [[Settings Screen]]

Controls:

- force dark theme
- allow system theme
- allow user theme selection

---

## [[Business Settings]]

#settings

Related to:

- [[Admin Settings Page]]
- [[Booking Flow]]
- [[Owner Payments Screen]]

Controls:

- owner visibility rules
- booking limits
- request limits
- owner self-booking prevention

---

## [[Negotiation Settings]]

#settings

Related to:

- [[Admin Settings Page]]
- [[Price Negotiation Flow]]
- [[Offer Negotiation Flow]]

Controls:

- max counter offers
- negotiation availability
- price negotiation rules

---

# Role Connections

## [[Guest User]]

Can access:

- [[Launch Screen]]
- [[Login Screen]]
- [[Register Screen]]
- [[Main Search Screen]]
- [[Equipment List Screen]]
- [[Equipment Map Screen]]

---

## [[Client User]]

Can access:

- [[Client Dashboard]]
- [[Main Search Screen]]
- [[Equipment List Screen]]
- [[Equipment Map Screen]]
- [[Equipment Booking Screen]]
- [[Create Request Screen]]
- [[Client Requests Screen]]
- [[Client Orders Screen]]
- [[Client Booking Detail Screen]]
- [[Chats Screen]]
- [[Chat Detail Screen]]
- [[Favorites Screen]]
- [[Notifications Screen]]
- [[Settings Screen]]

---

## [[Owner User]]

Can access:

- [[Owner Dashboard]]
- [[Owner Equipment List Screen]]
- [[Owner Equipment Detail Screen]]
- [[Owner Bookings Screen]]
- [[Owner Booking Detail Screen]]
- [[Owner Requests Screen]]
- [[Owner Profile Screen]]
- [[Owner Payments Screen]]
- [[Owner Addresses Screen]]
- [[Owner Pin Location Map Screen]]
- [[Chats Screen]]
- [[Chat Detail Screen]]
- [[Notifications Screen]]
- [[Settings Screen]]

---

## [[Admin User]]

Can access:

- [[Admin Dashboard]]
- [[Admin Clients Page]]
- [[Admin Owners Page]]
- [[Admin Owner Detail Page]]
- [[Admin Fleet Page]]
- [[Admin Equipment Detail Page]]
- [[Admin Categories Page]]
- [[Admin Category Specs Page]]
- [[Admin Bookings Page]]
- [[Admin Booking Detail Page]]
- [[Admin Requests Page]]
- [[Admin Offers Page]]
- [[Admin Reviews Page]]
- [[Admin Settings Page]]
- [[Admin Cities Page]]
- [[Admin Audit Logs Page]]
- [[Admin Backend Health Page]]

---

## [[Support User]]

Can access:

- [[Support Dashboard]]
- [[Support Tickets Page]]
- limited views of [[Client User]]
- limited views of [[Owner User]]
- limited views of [[Booking]]
- limited views of [[Request]]

---

# Graph Hub Nodes

Use these as main graph centers:

- [[Prokat Mobile App]]
- [[Prokat Web Admin]]
- [[Client Module]]
- [[Owner Module]]
- [[Admin Dashboard]]
- [[Equipment Module]]
- [[Booking Module]]
- [[Request Module]]
- [[Offer Module]]
- [[Chat Module]]
- [[Map Module]]
- [[Review Module]]
- [[Admin Settings Page]]

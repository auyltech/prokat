# Prokat Mobile – Data Fetching & State Management Audit (Analysis Only)

## Objective

Perform a complete audit of the application's data fetching architecture.

DO NOT implement any code changes.
DO NOT create providers, repositories, hooks, services, or new files.
DO NOT modify existing code.

Your task is analysis only.

The goal is to understand the current state of:

* Data fetching
* Data caching
* Loading states
* Submission states
* Error states
* Refetch strategies
* Cross-module refresh dependencies
* UX behavior during initial loads and updates

---

## Context

The application currently follows a mostly screen-driven fetching pattern.

Typical flow:

1. User navigates to a screen.
2. Screen triggers a fetch in initState.
3. Data loads into provider/state.
4. Pull-to-refresh can manually trigger a refetch.

Several modules now also support:

* isLoading
* isSubmitting
* actionId

Example:

* Accept booking
* Reject booking
* Toggle equipment visibility
* Approve request

Only the affected action button shows loading while other actions remain disabled.

For many create/update/delete operations:

* API returns success/failure only
* No updated DTO is returned
* A manual refetch is triggered after success

This pattern exists in some modules but not consistently across the project.

---

## Current UX Problems

### Initial Loading

Users may see:

* Empty states
* Error states
* No data states

before a successful fetch has ever completed.

This creates confusion because:

* There may simply be no successful fetch yet
* Network may be slow
* Backend may be temporarily unavailable

---

### Refresh Inconsistency

Some modules refresh after mutations.

Some do not.

Examples:

* Booking accepted but booking list not refreshed
* Equipment visibility changed but equipment list stale
* Profile updated but other screens unaware
* Chat changes affecting booking/request states

---

### Cross-Module Staleness

Changes in one module may affect another module.

Examples:

* Booking actions affecting chats
* Requests affecting equipment availability
* Equipment updates affecting search results
* Profile updates affecting owner views
* Notifications affecting unread counters

Currently many of these updates require:

* Manual pull-to-refresh
* Leaving and re-entering a screen

---

### Existing Improvement

Screens were recently improved:

If cached data exists:

* Show existing content immediately
* Show top loading indicator or refresh state

If no cached data exists:

* Show shimmer skeleton

Review how consistently this pattern is applied.

---

## Analysis Tasks

### 1. Inventory Every Data Module

Identify all modules that fetch remote data.

Examples may include:

* Equipment
* Equipment Details
* Categories
* Locations
* Bookings
* Requests
* Chats
* Messages
* Notifications
* Owner Profile
* User Profile
* Balances
* Transactions
* Reviews
* Favorites
* Search Results

List every discovered module.

---

### 2. Map Current Fetch Flow

For every module identify:

* Where fetching starts
* initState
* Provider initialization
* Manual trigger
* Pull-to-refresh
* Navigation event
* Other

Document the exact flow.

---

### 3. Analyze Loading State Strategy

For each module identify:

* Initial loading state
* Refresh loading state
* Action submission loading state

Determine:

* Consistency
* Missing states
* Duplicate states
* Conflicting states

---

### 4. Analyze Error State Strategy

For each module identify:

* How errors are stored
* How errors are displayed
* Whether errors replace content
* Whether stale content remains visible

Determine:

* Which modules can incorrectly show empty/error states before first successful load
* Which modules have better UX

---

### 5. Analyze Refetch Strategy

For every module determine:

* What triggers a refetch
* When refetch occurs
* Whether CRUD operations trigger refetch
* Whether pull-to-refresh is required

Create a matrix showing:

Module → Fetch Trigger → Refetch Trigger

---

### 6. Analyze Mutation Strategy

For every create/update/delete action identify:

* Action type
* Loading handling
* Success handling
* Failure handling
* Refetch behavior

Examples:

* Accept booking
* Reject booking
* Cancel booking
* Toggle visibility
* Update profile
* Send message
* Mark notification read

Document the current pattern.

---

### 7. Analyze Cross-Module Dependencies

Identify places where one module changes data owned by another module.

Examples:

Booking -> Chat

Request -> Booking

Equipment -> Search Results

Profile -> Owner Dashboard

Notification -> Unread Counter

Build a dependency map.

---

### 8. Analyze Cache Behavior

For every module determine:

* Is data retained after leaving screen?
* Is data retained after app backgrounding?
* Is data reused when reopening screen?
* Is stale data displayed while refreshing?

Document current behavior.

---

### 9. Analyze User Experience

Evaluate:

* First load experience
* Slow network experience
* Offline experience
* Returning user experience
* Pull-to-refresh experience
* Post-mutation experience

Identify the biggest UX pain points.

---

### 10. Produce Architecture Findings

Create:

#### Current Strengths

What is already working well.

#### Current Weaknesses

What is causing stale data, unnecessary refetches, duplicate requests, or poor UX.

#### Risk Areas

Which modules are most likely to become problematic as the application grows.

#### Recommended Future Direction

NO IMPLEMENTATION.

Only architectural recommendations.

Examples:

* Centralized refresh orchestration
* Stale-while-revalidate approach
* Event-driven invalidation
* Query-based caching
* Module dependency invalidation
* Optimistic updates
* Background refresh patterns

Do not implement any of these.

Only explain where they would help.

---

## Deliverable

Produce a detailed report.

No code.
No refactors.
No file modifications.
No implementation.

Only analysis, diagrams, dependency maps, findings, and recommendations.

A few things I would specifically expect the audit to uncover in Prokat:

1. **No distinction between "never loaded" and "empty result"**

   * This is usually why users see "No Data" too early.

2. **No distinction between "refreshing" and "loading"**

   * You're already improving this with cached data + spinner.

3. **Mutation ownership is unclear**

   * Example: booking accepted → who refreshes bookings? chats? notifications?

4. **Screen-driven fetching**

   * Data freshness depends on navigation rather than domain events.

5. **Refetch storms**

   * As you add more modules, one action may trigger multiple independent refetches.

6. **No invalidation graph**

   * The app doesn't know which modules became stale after a mutation.

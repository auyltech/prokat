# Task: Create a Plan for Building a Project PRD from Chat History

You are working on the **Prokat Mobile** project.

Your task is to create a **plan only**. Do not write the PRD yet. Do not implement code. Do not modify files.

The goal is to analyze the available project chats, summaries, uploaded notes, and project memory, then produce a clear plan for creating a long-term reference document:

`docs/PRD.md`

This PRD will be used by me and future AI agents to understand the product, business logic, technical structure, feature decisions, open questions, and implementation direction of the Prokat project.

---

## Main Objective

Create a structured plan for reading and summarizing the project history into a professional PRD document.

The final PRD should help answer:

- What is Prokat?
- Who are the users?
- What problems does it solve?
- What features exist or are planned?
- What are the core workflows?
- What is the current architecture?
- What models and backend concepts are important?
- What mobile features are already discussed?
- What admin/web features are planned?
- What decisions have already been made?
- What open questions remain?
- What should future AI agents know before making changes?

---

## Important Rule

For now, generate the **plan only**.

Do not create the actual PRD content yet.

The plan should explain:

1. What sources to read
2. What information to extract
3. How to organize the PRD
4. What sections the PRD should contain
5. How to distinguish confirmed decisions from assumptions
6. How to track open questions
7. How to make the document useful for future AI coding agents

---

## Sources to Review

Review all available project context, including:

- Recent project chats
- Project memory
- Uploaded files
- Existing schema information
- Feature discussions
- Backend model discussions
- Flutter app architecture discussions
- Admin dashboard discussions
- Booking/request/offer workflow discussions
- Equipment, owner, renter, map, image upload, category specs, dictionary, and chat feature discussions
- Any existing planning files, including map-related refactor plans if available

The project has existing planning content such as a map feature refactor discussion, which should be considered as part of the wider project context. :contentReference[oaicite:0]{index=0}

---

## Required Output

Produce a markdown plan with the following structure:

```md
# PRD Creation Plan for Prokat Mobile

## 1. Goal of the PRD

Explain what the PRD should achieve and who will use it.

## 2. Sources to Analyze

List all project sources that should be reviewed.

For each source type, explain what kind of information should be extracted.

Example:

- Chat history: product decisions, feature requirements, architecture discussions
- schema.prisma: data model, relations, statuses, enums, ownership logic
- uploaded planning files: feature-specific implementation decisions
- admin page discussions: web dashboard structure and workflows
- Flutter discussions: app architecture, providers, screens, routing, UI conventions

## 3. Information Extraction Checklist

Create a checklist of information to extract from the chats.

Include at minimum:

- Product overview
- User roles
- Core business workflows
- Mobile app features
- Backend features
- Admin dashboard features
- Data models
- Status flows
- API patterns
- Storage/image upload strategy
- Map/location strategy
- Auth/session strategy
- UI/theme conventions
- Known bugs and recurring issues
- Future roadmap
- Open questions

## 4. Proposed PRD Structure

Propose the exact section structure for `docs/PRD.md`.

The structure should be detailed and production-grade.

Include sections such as:

- Product Summary
- Target Users
- User Roles
- Core Use Cases
- Feature Map
- Mobile App Requirements
- Backend Requirements
- Admin Dashboard Requirements
- Data Model Overview
- Booking Workflow
- Request and Offer Workflow
- Owner Equipment Workflow
- Equipment Image Upload Workflow
- Category Specs Workflow
- Dictionary / Localization System
- Chat System
- Map and Location System
- Auth and Startup Flow
- File Storage Strategy
- UI/UX Guidelines
- Non-Functional Requirements
- Known Technical Decisions
- Open Questions
- Future Roadmap
- AI Agent Notes

## 5. Feature Areas to Summarize

Create a feature-by-feature plan for summarizing the project.

At minimum include:

### Auth and Startup
- Login methods
- OTP flow
- Secure session storage
- Startup redirect logic
- Role-based routing

### Users and Roles
- Renter/client
- Equipment owner/provider
- Admin
- Future support role if relevant

### Owner Registration and Profile
- Owner registration request
- Owner profile
- Verification flow
- Documents
- Ratings and badges

### Equipment Management
- Equipment creation
- Equipment details
- Prices
- Locations
- Category specs
- Status and visibility
- Owner equipment list sorting

### Equipment Images
- Multiple equipment images
- Upload limit
- Image header carousel/swiper
- Backend upload responsibility
- Supabase storage strategy

### Categories and Category Specs
- Admin-defined categories
- Admin-defined specs per category
- Equipment-specific spec values
- Import/export support
- Visibility to client

### Booking Workflow
- Client creates booking
- Owner accepts/rejects
- Work status levels
- Completion/cancellation logic
- Admin visibility

### Requests and Offers
- Client creates request
- Owner sends offer
- Offer states
- Request states
- Owner request UI state mapping

### Chat
- Chat list
- Chat details
- Last 50 messages
- Socket-based send/receive
- Unread counts
- State replacement/add logic

### Map and Location
- Renter equipment map
- Owner equipment pin placement
- Address creation
- Mapbox integration
- Reverse geocoding
- Mobile-only map fallback

### Admin Dashboard
- Categories
- Category specs
- Dictionary
- Owners
- Bookings
- Requests
- Offers
- Import/export patterns
- CRUD server actions
- Server-rendered pages

### Dictionary and Localization
- Static data dictionary
- Multi-language values
- Admin editing
- Excel import/export
- Use for forms/pages/static options

## 6. Data Model Summary Plan

Explain how to summarize the schema without rewriting the entire schema.

The plan should identify important models and describe:

- Purpose of each model
- Key fields
- Important relations
- Important status fields
- Business rules
- Mobile/backend/admin usage

Include likely models such as:

- User
- UserProfile
- OwnerProfile
- OwnerRegistrationRequest
- Equipment
- EquipmentImage / Image
- Category
- CategorySpec
- EquipmentSpec
- PriceEntry
- Location
- Booking
- Request
- Offer
- Chat
- Message
- Dictionary
- Document
- Review / Rating if present

## 7. Decision Tracking

The PRD should separate:

### Confirmed Decisions
Things clearly decided in the chats.

### Current Assumptions
Things that seem likely but were not fully confirmed.

### Open Questions
Things that still need the project owner to decide.

### Future Ideas
Things mentioned but not required immediately.

Explain how each category should be marked in the PRD.

Use labels like:

- `[Confirmed]`
- `[Assumption]`
- `[Open Question]`
- `[Future]`

## 8. AI Agent Usability Requirements

The PRD should be written so future AI agents can use it effectively.

The plan should recommend:

- Clear headings
- Stable terminology
- No vague feature names
- Separate mobile/backend/admin responsibilities
- Include status values exactly as used
- Include file/folder conventions
- Include common bugs and pitfalls
- Include “before coding, read this” notes
- Include implementation boundaries

## 9. Suggested Supporting Docs

Recommend additional docs that may be created later, such as:

```txt
/docs/PRD.md
/docs/ARCHITECTURE.md
/docs/DATA_MODEL.md
/docs/API_GUIDE.md
/docs/FEATURES/booking.md
/docs/FEATURES/equipment.md
/docs/FEATURES/map.md
/docs/FEATURES/chat.md
/docs/FEATURES/admin.md
/docs/AI_AGENT_GUIDE.md

Explain which information belongs in the PRD and which should be split into separate docs later.

## 10. Final Deliverable Format

The plan should end with a proposed execution checklist for the next AI agent.

Example:

## Execution Checklist

- [ ] Read project memory
- [ ] Read recent chats
- [ ] Read uploaded planning files
- [ ] Read schema.prisma
- [ ] Extract core product goals
- [ ] Extract user roles
- [ ] Extract workflows
- [ ] Extract feature requirements
- [ ] Extract technical architecture
- [ ] Extract open questions
- [ ] Draft docs/PRD.md
- [ ] Review for duplicate or outdated decisions
- [ ] Mark assumptions clearly

Quality Requirements

The plan must be:

Clear
Structured
Detailed
Production-grade
Useful for AI agents
Focused on Prokat specifically
Written in markdown
Not too generic
Not code-focused
Not implementation yet

The plan should avoid vague instructions like “summarize everything.”

Instead, it should tell the AI exactly what to look for, how to classify information, and how the final PRD should be structured.

Reminder

Do not write the actual PRD yet.

Only create the plan for how to create the PRD.
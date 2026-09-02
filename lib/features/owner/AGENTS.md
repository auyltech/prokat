# Owner

- Business profile (`PATCH /owner/profile`) is individual contact fields only. Company / BUSINESS type stays hidden.
- Saving a real field change sends `submitForReview: true` with `PATCH /owner/profile`. The API then sets `PENDING_REVIEW` even if trimmed values look unchanged (spaces, same city key). Unchanged saves without that flag keep the current status.
- Update button is shown only while visible fields differ from the last saved profile; it hides after the PATCH finishes.
- `PENDING_REVIEW` locks the form until an admin accepts or rejects — no further edits (anti-spam).
- Banner: pending / rejected / suspended only. Approved and incomplete show no plaque; documents are not collected.
- Become-owner (`POST /owner/become-owner`) is a separate client-mode screen. After submit it pops back to the client profile CTA (`pending`). Pending/approved applications are read-only; rejected can resubmit.

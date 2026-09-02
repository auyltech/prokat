# Owner

- Business profile (`PATCH /owner/profile`) is individual contact fields only. Company / BUSINESS type stays hidden.
- Saving a real field change sends `submitForReview: true` with `PATCH /owner/profile`. The API then sets `PENDING_REVIEW` even if trimmed values look unchanged (spaces, same city key). Unchanged saves without that flag keep the current status.
- Banner: pending / rejected / suspended only. Approved and incomplete show no plaque; documents are not collected.

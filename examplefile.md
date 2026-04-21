---
title: Markiiup V2 Sample
summary: Desktop-first Markdown workspace sample
tags:
  - desktop
  - markdown
  - review
---

# Markiiup V2 Sample Document

This file is meant to show the current desktop direction for **markiiup**.

The key idea is simple: you edit a document canvas that feels more like a writing surface, but the saved file is still Markdown.

## Current Workflow

- Open a Markdown document directly from macOS.
- Choose a workspace folder to browse related files.
- Write in `Document` mode for the formatted canvas.
- Switch to `Markdown` mode when you need exact source control.
- Save the same `.md` file back to disk.

## Why This Exists

Split preview is usually extra work when the real goal is just to update a document quickly.

The app is moving toward a single-pane writing and review workflow:

- headings should read like headings
- emphasis should look emphasized
- links should be easy to scan
- tasks should be visible as tasks
- front matter should stay available without taking over the writing surface

## Formatting Check

### Emphasis

This line includes **bold text**, *italic text*, `inline code`, and a [Markdown link](https://example.com).

### Quote

> The document canvas should feel closer to a native editor than a raw source file, while still saving Markdown.

### Checklist

- [ ] Review the current document canvas
- [ ] Open related files from the workspace
- [x] Confirm the app saves back to Markdown

### Wiki Links And Tags

Try these links:

- [[Document Name]]
- [[User Guide]]

Useful tags for testing: #markiiup #desktop #markdown #review

### Review Table

| Area | Current State | Next Step | Test column |
| --- | --- | --- | --- |
| Document Canvas | Live styled Markdown | Improve tables and image layout | 1 |
| Workspace Browser | Working | Add backlinks and smarter search | 2 |
| Formatting Commands | Working | Expand round-trip coverage | 3 |

### Tech Spec Change Table

| Component | Change | Risk | Reviewer Note |
| --- | --- | --- | --- |
| `orders` table | Add `approved_at` timestamp | Medium | Confirm backfill plan before launch |
| `analytics.order_summary` view | Include approval status | Low | Validate downstream dashboard fields |
| API contract | Return `approvalState` | Medium | Coordinate with mobile clients |

### SQL Block

```sql
SELECT
    o.order_id,
    o.approved_at,
    CASE
        WHEN o.approved_at IS NULL THEN 'pending'
        ELSE 'approved'
    END AS approval_state
FROM analytics.orders AS o
WHERE o.updated_at >= CURRENT_DATE - INTERVAL '14 day';
```

### Code Block

```swift
struct ChangeReview {
    let title: String
    let isMarkdownBacked: Bool
}
```

## Workspace Testing

After opening this file:

1. Choose the repo root as the workspace folder.
2. Open `Document Name.md` from the sidebar.
3. Switch between `Document` and `Markdown` modes.
4. Capture a review baseline from the sidebar.
5. Apply formatting from the toolbar or modify a table cell.
6. Save and confirm the file remains clean Markdown while the baseline summary reflects the changes.

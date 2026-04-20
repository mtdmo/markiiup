# markiiup User Guide

`markiiup` is a native macOS Markdown editor. The file on disk stays plain Markdown, while the app gives you a richer document canvas for editing.

## Getting Started

1. Run `./script/build_and_run.sh --sample` from the repo root, or open the app bundle after building
2. Open a `.md` file directly, or use the bundled sample document
3. Stay in `Document` mode for normal editing
4. Switch to `Markdown` when you need exact source control

## Interface Overview

- `Document Canvas`: the main editing surface
- `Markdown`: raw source mode for the same file
- `Sidebar`: workspace files, related files, outline, tasks, links, tags, tables, SQL blocks, and front matter
- `Toolbar`: formatting, table insertion, workspace controls

## Writing In The Document Canvas

The canvas live-styles Markdown so headings, emphasis, lists, links, tables, and code blocks read more like a document while still saving back to `.md`.

Available formatting actions:

- bold
- italic
- inline code
- headings
- quote blocks
- checklists
- links
- table insertion

## Working With Tables

Tables are now edited directly from the document canvas flow.

### Insert A Table

- Use the `tablecells` toolbar menu
- Or use the command menu action for a 3 x 3 table

### Edit A Table

1. Put the cursor inside a Markdown table while in `Document` mode
2. The inline table editor appears above the text view
3. Edit cells directly in the grid
4. Use `Add Row`, `Delete Row`, `Add Column`, and `Delete Column`
5. Save the document as normal

The Markdown table block is rewritten underneath the editor, so the file remains portable.

## Workspace Navigation

Use `Choose Folder` to point the sidebar at a Markdown workspace.

The sidebar can then help you:

- open related files from Markdown links and `[[wiki links]]`
- jump through headings and tasks
- inspect detected links, tags, tables, and SQL blocks
- filter sidebar sections from the inline search field

## Saving Files

This is a document-based macOS app, so save behavior follows the normal system document flow.

- Open a Markdown file and edit it directly
- Save writes back to the same `.md` file
- Use the system document actions when you want a new file or a copy

## Suggested Test Files

- [[examplefile]]
- [[Document Name]]

## Validation Checklist

- [ ] Open a real `.md` file
- [ ] Edit content in `Document` mode
- [ ] Switch to `Markdown` mode and confirm the source stays readable
- [ ] Put the cursor inside a table and edit rows, columns, and cells
- [ ] Save and reopen the file successfully

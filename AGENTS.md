# AGENTS.md

This repository is a native macOS app.

## Project Overview

**markiiup** is a SwiftUI/AppKit Markdown editor for macOS. The product goal is a formatted document-writing experience that still saves clean `.md` files.

The file is the source of truth. The app can style and edit the document like a richer canvas, but saves back to Markdown.

## Current Architecture

- `Package.swift` - SwiftPM package definition
- `Sources/markiiupMac/App/` - app entrypoint and scene setup
- `Sources/markiiupMac/Views/` - SwiftUI views and AppKit editor bridge
- `Sources/markiiupMac/Models/` - document/workspace analysis models
- `Sources/markiiupMac/Stores/` - persistent workspace state
- `Sources/markiiupMac/Services/` - Markdown parsing, workspace scanning, document opening
- `Sources/markiiupMac/Support/` - editor commands, logging, text styling helpers
- `examplefile.md` - current sample document for manual testing
- `Document Name.md`, `User Guide.md` - additional workspace docs for navigation tests

## Product Direction

- Desktop-only v2. Do not rebuild the old website path.
- Prefer a single-pane document experience over split preview.
- Keep Markdown canonical on disk.
- Use native macOS affordances: document windows, sidebars, toolbars, commands.
- When adding formatting features, make the document canvas feel richer first, then preserve or improve Markdown round-tripping.

## Development Setup

Run the app from the repo root:

```bash
./script/build_and_run.sh
```

Useful variants:

```bash
./script/build_and_run.sh --sample
./script/build_and_run.sh --verify
```

## Key Components

- `MarkdownDocument` - file-backed Markdown document model
- `NativeMarkdownTextView` - AppKit editor bridge used for actual editing
- `MarkdownTextStyler` - live formatting layer for document-canvas presentation
- `WorkspaceStore` - selected folder, file index, related-file navigation
- `MarkdownReviewParser` - headings, tasks, links, tags, front matter analysis

## Working Rules

- Treat the `.md` file as the durable format.
- Keep AppKit interop narrow and explicit.
- If you add UI modes, default to the formatted document canvas.
- Build with `swift build` after meaningful native code changes.
- Prefer updating the sample Markdown documents when product behavior changes enough that the current examples become misleading.

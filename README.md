# markiiup

[![CI](https://github.com/mtdmo/markiiup/actions/workflows/ci.yml/badge.svg)](https://github.com/mtdmo/markiiup/actions/workflows/ci.yml)

`markiiup` is a native macOS Markdown editor built around one rule: the `.md` file stays canonical.

The app is meant to feel like a document canvas, not a raw source file, while still saving plain Markdown that works anywhere.

![markiiup Logo](markiiup.png)

## Current Features

- native `.md` open and save with `DocumentGroup`
- `Document` mode for a formatted writing canvas backed by Markdown
- `Markdown` mode for exact source editing
- incremental document-canvas restyling so ordinary edits do not repaint the full file
- inline canvas table editing that rewrites the underlying Markdown table
- native toolbar and command-menu actions for headings, emphasis, code, links, quotes, checklists, and tables
- live workspace watching so Markdown folders refresh automatically as files change
- review baselines that let you capture a document state and see what changed since that checkpoint
- workspace sidebar for related files, outline, tasks, links, tags, tables, SQL blocks, front matter, and baseline deltas
- local link resolution for Markdown links and `[[wiki links]]`

## Running The App

From the repo root:

```bash
./script/build_and_run.sh
```

Useful variants:

```bash
./script/build_and_run.sh --sample
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
```

The run script builds the SwiftPM target, stages `dist/markiiupMac.app`, applies the app icon, and launches it as a real macOS app.

## Repository Checks

- GitHub Actions runs `swift build` and `swift test` for pushes to `main` and pull requests
- Dependabot watches SwiftPM and GitHub Actions dependencies
- Issue forms and a pull request template keep reports and contributions consistent

## Quick Test

```bash
./script/build_and_run.sh --sample
```

That opens the app with [examplefile.md](examplefile.md).

Suggested manual flow:

1. Run `./script/build_and_run.sh --sample`
2. Click `Choose Folder` and select the repo root
3. Open [Document Name.md](Document%20Name.md) or [User Guide.md](User%20Guide.md) from `Workspace Files`
4. Switch between `Document` and `Markdown`
5. Capture a review baseline from the left sidebar
6. Put the cursor inside a table to use the inline table editor
7. Save and confirm the `.md` file stays clean while the baseline summary updates

## Repo Layout

```text
markiiup/
├── Package.swift
├── Sources/markiiupMac/
├── script/build_and_run.sh
├── examplefile.md
├── Document Name.md
└── User Guide.md
```

## Development Notes

- Stack: Swift 6, SwiftUI, AppKit interop, SwiftPM
- Minimum target: macOS 14+
- Generated artifacts in `.build/` and `dist/` are ignored
- The document canvas is the main product surface; Markdown source remains the fallback precision mode
- SwiftPM tests cover Markdown analysis, Markdown table round-tripping, and baseline comparison logic

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for local setup, validation, and contribution guidance.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

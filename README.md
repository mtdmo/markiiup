# markiiup

`markiiup` is a native macOS Markdown editor built around one rule: the `.md` file stays canonical.

The app is meant to feel like a document canvas, not a raw source file, while still saving plain Markdown that works anywhere.

![markiiup Logo](markiiup.png)

## Current Features

- native `.md` open and save with `DocumentGroup`
- `Document` mode for a formatted writing canvas backed by Markdown
- `Markdown` mode for exact source editing
- inline canvas table editing that rewrites the underlying Markdown table
- native toolbar and command-menu actions for headings, emphasis, code, links, quotes, checklists, and tables
- workspace sidebar for related files, outline, tasks, links, tags, tables, SQL blocks, and front matter
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
5. Put the cursor inside a table to use the inline table editor
6. Save and confirm the `.md` file stays clean

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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for local setup, validation, and contribution guidance.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

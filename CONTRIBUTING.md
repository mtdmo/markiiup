# Contributing to markiiup

Thank you for contributing to `markiiup`.

The project is now a native macOS app built with SwiftUI, AppKit interop, and SwiftPM. The main product constraint is simple: keep Markdown canonical on disk while making the document canvas better to edit.

## Reporting Bugs

- Open a GitHub issue with clear reproduction steps
- Include the macOS version you tested on
- Include whether the issue happens in `Document`, `Markdown`, or both modes
- If relevant, attach the Markdown snippet that triggers the problem

## Suggesting Features

- Open a GitHub issue describing the workflow problem first
- Prioritize document-canvas editing, Markdown round-tripping, navigation, and review workflows

## Local Setup

```bash
swift build
swift test
./script/build_and_run.sh
```

Useful checks:

```bash
./script/build_and_run.sh --sample
./script/build_and_run.sh --verify
swift test
```

## Contribution Guidelines

1. Create a branch for your work
2. Keep changes focused and intentional
3. Prefer native macOS patterns over custom web-style UI abstractions
4. Keep AppKit interop narrow and explicit
5. Update sample Markdown docs when product behavior changes enough that the current examples become misleading
6. Run `swift build` and `swift test` before opening a PR
7. Expect GitHub Actions CI to stay green on your branch

## Testing Expectations

- Verify the app builds successfully
- Run `swift test`
- Manually test the affected document workflow
- If you change the editor bridge or document canvas, test both `Document` and `Markdown` modes
- If you change table behavior, confirm the resulting `.md` table remains valid and readable
- If you change workspace or review flows, verify live refresh and review-baseline capture on a real Markdown file

## Questions

Open a GitHub issue if you need clarification before contributing.

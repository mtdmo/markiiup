# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Native macOS v2 app foundation built with SwiftUI, AppKit, and SwiftPM
- Document-based `.md` open/save workflow for the macOS app
- Native Markdown menu and toolbar commands for common editing actions
- Workspace folder picker and Markdown file browser in the native app
- Related-file resolution for local Markdown links and wiki links
- Sidebar analysis for headings, tasks, links, tags, and front matter
- Single-pane document canvas that live-styles Markdown while keeping the file canonical
- Local build-and-run script plus Codex Run action for the macOS app
- App bundle icon generation based on the cat logo
- Sidebar-native filtering for workspace and document sections
- Table and fenced-code review cards in the sidebar
- Inline document-canvas table editor with row, column, and cell updates
- Table insertion actions in the toolbar and command menu

### Changed
- Reframed the repository as a native macOS app
- Kept Markdown as the canonical file format
- Replaced split-preview editing with document-canvas and raw-markdown modes
- Cleaned public docs and sample files around the desktop-only product

### Removed
- Legacy HTML/CSS/JavaScript web application files
- Legacy web release notes and push helper script

## [1.0.0] - 2024-12-19

### Added
- Initial public release
- Complete WYSIWYG editing experience
- Markdown export functionality
- Comment/task management system
- Wiki-style internal linking
- Tag system with visual indicators
- Modern, responsive UI
- Cross-browser support

# 📝 markiiup v1.2 Feature Showcase

## Overview

This document demonstrates all the features available in **markiiup v1.2** - a modern Microsoft Word-like editor that saves files in Markdown format. markiiup provides a rich WYSIWYG editing experience with font management, enhanced file handling, distraction-free modes, and advanced table editing while maintaining clean Markdown output.

> **New in v1.2**: Font family & size selection, smart save functionality, and proper Save As dialog!

---

## ✨ Core Features

### 📄 File Operations (v1.2 Enhanced!)

- **New Document**: Create fresh documents with `📄` button

- **Open Document**: Load existing `.md` files with `📁` button
  - Chrome/Edge: Uses File System Access API for better integration

- **Save**: Smart save with `💾` button
  - Saves to original location when possible
  - Falls back to download when needed

- **Save As**: Choose save location with new Save As option
  - Chrome/Edge/Opera: System file dialog
  - Other browsers: Downloads to default folder

- **Auto-save**: Documents are automatically converted to Markdown format

### 🎨 Rich Text Formatting

- **Bold Text**: Use `B` button or Ctrl+B for **bold formatting**

- **Italic Text**: Use `I` button or Ctrl+I for *italic formatting*

- **Underline**: Use `U` button for underlined text

- **Headings**: Select from H1-H6 dropdown for structured content

### 🔤 Font Management (v1.2 New!)

- **Font Family**: Choose from 8 professional fonts:
  - Arial (sans-serif)
  - Times New Roman (serif)
  - Georgia (serif)
  - Courier New (monospace)
  - Verdana (sans-serif)
  - Trebuchet MS (sans-serif)
  - Palatino (serif)

- **Font Size**: Adjust text size from 8pt to 36pt
  - Perfect for emphasizing important content
  - Maintains formatting when saving/loading

### 📋 Lists and Structure

- **Bullet Lists**: Use `• List` button for unordered lists

  - First item
  - Second item
  - Nested item
- **Numbered Lists**: Use `1. List` button for ordered lists

  1. First numbered item
  2. Second numbered item
  3. Third numbered item

### 🔗 Media and Links

- **Hyperlinks**: Use `🔗` button to insert [clickable links](https://example.com)

- **Images**: Use `🖼️` button to embed images

- **Advanced Tables**: Use `📊` button dropdown for comprehensive table operations

### 🎯 New v1.1 Features

- **Expanded View**: Click `⛶` button for distraction-free writing with wider editor space

- **Smart Table Operations**: Click any table cell, then use table dropdown for intuitive editing

- **Integrated Help**: Click `❓` button for direct access to GitHub issues and support

---

📊 Enhanced Table Example (v1.1)

**How to edit this table:**
- Click any cell below

- Click the table button (📊) in toolbar  

Choose your operation from the dropdown
| Feature | Description | Status | Version | Notes |
| --- | --- | --- | --- | --- |
| Rich Text Editing | WYSIWYG interface | ✅ Active | v1.0 | Core functionality |
| Markdown Export | Clean MD output | ✅ Active | v1.0 | Bidirectional conversion |
| Task Comments | Collaborative commenting | ✅ Active | v1.0 | Open/close states |
| Wiki Links | Document linking `name` | ✅ Active | v1.0 | Auto-detection |
| Tag System | `hashtag` categorization | ✅ Active | v1.0 | Real-time processing |
| Expanded View | Distraction-free writing | ✅ Active | v1.1 | NEW: Wider editor |
| Smart Tables | Toolbar-based operations | ✅ Active | v1.1 | NEW: Add/delete rows/cols |
| Help Integration | GitHub issues access | ✅ Active | v1.1 | NEW: Direct support |

---

## 💬 Comment System

markiiup includes a powerful task-based commenting system:

- **Add Comments**: Select text and click `💬` button

- **Comment Panel**: Toggle with `👥` button to view all comments

- **Task Management**: Each comment can be marked as OPEN or COMPLETED

- **Visual States**: 

  - Open tasks appear with yellow highlighting
  - Completed tasks show green highlighting with strikethrough
- **Persistence**: Comments are saved in Markdown files as HTML comments

---

## 🔗 Wiki Links

markiiup supports wiki-style document linking:

- **Syntax**: Use `[[Document Name]]` to create links

- **Auto-detection**: Links are automatically detected and styled

- **Document Creation**: Click links to create new documents

- **Visual States**: 

  - Existing documents: Normal link styling
  - Missing documents: "Broken" link stylingExample links: [[Document Name]], [[User Guide]], [[Technical Specs]]

This document specifically references [[Document Name]] to test the backlink functionality.

### 🏷️ Tag System

markiiup supports hashtag-based categorization:

- **Auto-detection**: Tags like #documentation #features #demo are automatically styled

- **Real-time Processing**: Tags are processed as you type

- **Visual Pills**: Tags appear as colored badges in both editor and sidebar

- **Organization**: Use tags to categorize and organize your documents

Try these tags: #markiiup #wysiwyg #markdown #v1.1 #showcase

---

## ⚙️ Settings and Preferences

Access settings with the `⚙️` button:

### User Profile

- **Name**: Set your name for comment attribution

- **Email**: Optional email for enhanced features

- **Persistence**: Settings saved in browser localStorage

### Editor Features

- **Real-time Stats**: Word and character counting

- **Auto-focus**: Editor maintains focus during operations

- **Keyboard Shortcuts**: Standard editing shortcuts supported

---

## 📈 Statistics and Metrics

The status bar shows real-time document statistics:
- **Word Count**: Total words in document

- **Character Count**: Total characters (including spaces)

Current document stats: 0 words, 0 characters

---

## 🎯 Advanced Features

### HTML to Markdown Conversion

- **Bidirectional**: Seamless HTML ↔ Markdown conversion

- **Table Support**: Full table conversion including headers

- **Format Preservation**: Maintains all formatting during conversion

- **Clean Output**: Generates clean, readable Markdown

### Comment Persistence

- **HTML Comments**: Comments stored as HTML comments in Markdown

- **JSON Metadata**: Rich comment data including timestamps and status

- **Cross-session**: Comments persist across browser sessions

- **Export Compatible**: Comments preserved when saving files

### Document Linking

- **Wiki Syntax**: `[[Document Name]]` creates document links

- **Auto-processing**: Links processed in real-time as you type

- **Click Navigation**: Click links to navigate or create documents

- **Visual Feedback**: Different styling for existing vs missing documents

---

## 🚀 Getting Started

- **Open markiiup**: Load `index.html` in any modern browser

- **Start Typing**: Begin writing in the WYSIWYG editor

- **Format Content**: Use toolbar buttons for formatting

- **Add Comments**: Select text and add task-based comments

- **Create Links**: Use `[[Document Name]]` for wiki links

- **Save Document**: Export as clean Markdown file

---

## 🔧 Technical Architecture

### Core Components

- **MarkiiupEditor Class**: Main application controller

- **ContentEditable**: Rich text editing interface

- **Markdown Converter**: Bidirectional HTML ↔ Markdown conversion

- **Comment System**: Task-based commenting with persistence

- **Wiki Link Processor**: Real-time link detection and processing

### File Format

- **Input**: Markdown files (`.md`)

- **Editing**: HTML format for rich editing

- **Output**: Clean Markdown with embedded HTML comments

- **Compatibility**: Works with any Markdown processor

---

## 📋 Complete Feature Checklist

### Core Features (v1.0)

- [x] Rich text editing (bold, italic, underline)

- [x] Heading formatting (H1-H6)

- [x] Bullet and numbered lists

- [x] Hyperlink insertion

- [x] Image embedding

- [x] Table creation and editing

- [x] Comment system with task management

- [x] Wiki-style document linking with `[[Document Name]]`

- [x] Hashtag tagging with `#tag` syntax

- [x] Settings and user preferences

- [x] Real-time word/character counting

- [x] File operations (new, open, save)

- [x] Bidirectional HTML ↔ Markdown conversion

- [x] Comment persistence in saved files

- [x] Microsoft Word-like interface

- [x] No build process required (pure HTML/CSS/JS)

- [x] Cross-document backlink tracking

- [x] Modern UI with DaisyUI + Material Icons

### New Features (v1.1)

- [x] **Expanded View**: Distraction-free writing mode

- [x] **Smart Table Operations**: Toolbar-based table editing

  - [x] Add row above/below
  - [x] Add column left/right  
  - [x] Delete rows and columns
  - [x] Intuitive click-to-select workflow
- [x] **Help Integration**: Direct GitHub issues access

- [x] **Enhanced UI**: Improved button positioning and accessibility

- [x] **Version Display**: Version shown in status bar

---

## 🚀 Quick Start Guide

### Getting Started with markiiup v1.1:

- **Basic Writing**: Start typing in the main editor area

- **Format Text**: Use toolbar buttons for bold, italic, underline, headings

- **Try Expanded View**: Click the `⛶` button for distraction-free writing

- **Add Comments**: Select text and click `💬` to add task-based comments

- **Create Links**: Type `[[Document Name]]` for wiki-style links

- **Add Tags**: Use `#hashtag` syntax for categorization

- **Work with Tables**: 

   - Click table button dropdown → "New Table"
   - Click any cell, then table dropdown for editing options
- **Get Help**: Click `❓` button to report issues or request features

- **Save Work**: Click save button to export as clean Markdown

### Testing Instructions:

- **Table Editing**: Try adding/removing rows and columns from the table above

- **Expanded Mode**: Toggle the expanded view to see the difference

- **Comments**: Select this text and add a comment to test the system

- **Links**: Click [[Document Name]] to test cross-document navigation

- **Tags**: Notice how #testing #demo #tutorial appear as styled pills

---

*This document showcases all markiiup v1.1 features. Edit it in the markiiup editor to experience the rich formatting and interactive features!*

<!-- COMMENTS -->
<!-- COMMENT 1: {"text":"This is an example comment","selectedText":"Comment System","author":"User","timestamp":"8/1/2025, 9:39:02 PM","completed":false,"status":"open"} -->
<!-- COMMENT 2: {"text":"Testing","selectedText":"ing new function","author":"User","timestamp":"8/1/2025, 9:39:02 PM","completed":true,"status":"completed"} -->

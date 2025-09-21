# markiiup v1.2.3

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub issues](https://img.shields.io/github/issues/mtdmo/markiiup)](https://github.com/mtdmo/markiiup/issues)
[![GitHub stars](https://img.shields.io/github/stars/mtdmo/markiiup)](https://github.com/mtdmo/markiiup/stargazers)
[![Version](https://img.shields.io/badge/version-1.2.3-blue)](https://github.com/mtdmo/markiiup/releases)

A modern JavaScript word processor that provides a Microsoft Word-like editing experience while saving files in Markdown format. Now with font management, enhanced file handling, and improved save functionality.

![markiiup Logo](markiiup.png)

## Overview

**markiiup** is a WYSIWYG (What You See Is What You Get) editor that allows users to create rich text documents with a familiar word processor interface, while seamlessly saving content in clean Markdown format. No side-by-side preview needed - just write naturally and let markiiup handle the conversion.

## Features

### 📝 Rich Text Editing
- **Familiar Interface**: Microsoft Word-like toolbar and editing experience
- **Text Formatting**: Bold, italic, underline, headings (H1-H6)
- **Font Management**: Choose from multiple font families (Arial, Times New Roman, Georgia, Courier, Verdana, and more)
- **Font Sizing**: Adjustable font sizes from 8pt to 36pt
- **Remove Formatting**: Clear all formatting with a single click
- **Lists**: Bullet and numbered lists
- **Advanced Tables**: Full table support with intuitive editing operations
- **Links & Images**: Easy insertion with toolbar buttons
- **Expanded View**: Distraction-free writing mode with wider editor space

### 💬 Task-Based Comments
- Add comments to any selected text
- Comments function as tasks with open/closed states
- Visual indicators: Yellow for open tasks, green for completed
- Persistent comment storage in Markdown files

### 🔗 Wiki-Style Linking
- Use `[[Document Name]]` syntax for internal links
- Automatic link detection and styling
- Visual feedback for valid (blue) and broken (red) links
- Click broken links to create new documents

### 🏷️ Tag System
- Add tags with `#tagname` syntax
- Automatic tag detection and pill-style display
- Tag cloud in sidebar showing all document tags

### 🔄 Backlinks
- Track which documents reference the current document
- Automatic backlink detection
- Document store for cross-reference management

### 🎨 Modern UI
- Clean, modern design with Tailwind CSS and DaisyUI
- Material Design icons
- Light theme optimized for readability
- Responsive design for mobile and desktop
- Teal brand color (#2FAEAC) throughout
- **Integrated Help**: Direct access to GitHub issues for support and feedback

### 💾 Enhanced File Management (v1.2)
- **Smart Save**: Automatically saves back to original file location when supported
- **Save As Dialog**: Proper file system dialog for choosing save location (Chrome/Edge)
- **File System Access API**: Modern file handling for supported browsers
- **Fallback Support**: Automatic download for browsers without File System Access API

### 💻 Code Formatting (v1.2.1)
- **Inline Code**: Format selected text as `inline code` with monospace font
- **Code Blocks**: Insert formatted code blocks with syntax-friendly styling
- **Markdown Support**: Seamless conversion between HTML and Markdown for code
- **Visual Styling**: Professional code appearance with proper highlighting

### 🛠️ Advanced Table Operations
- **Smart Table Editing**: Click any table cell, then use toolbar dropdown for operations
- **Row Management**: Add rows above/below, delete rows
- **Column Management**: Add columns left/right, delete columns
- **Intuitive Workflow**: No complex hover menus or context menus needed

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/mtdmo/markiiup.git
cd markiiup
```

2. Open `index.html` in your web browser
   - No build process required!
   - No dependencies to install!
   - Works offline once loaded

## Usage

### Basic Editing
- Start typing in the editor area
- Use the toolbar buttons for formatting
- Choose fonts and sizes from the dropdowns
- Save your work as a `.md` file

### File Operations (v1.2)
- **Open**: Use File menu or Ctrl/Cmd+O to open files
- **Save**: Saves to original location if opened with File System Access API
- **Save As**: Choose a new location and filename (Chrome/Edge/Opera)
- **Auto-fallback**: Downloads file if browser doesn't support modern APIs

### Comments/Tasks
1. Select any text
2. Click the comment button
3. Add your comment
4. Use the comments panel to manage tasks

### Wiki Links
- Type `[[Document Name]]` to create a link
- Links are automatically styled
- Click to navigate (or create new documents)

### Tags
- Add tags anywhere with `#tagname`
- View all tags in the sidebar
- Click tags to filter/search (future feature)

### Font Management
- Select text and choose a font family from the dropdown
- Adjust font size for selected text or new content
- Fonts are preserved when converting between HTML and Markdown

### Tables
1. Click the table button dropdown in toolbar
2. Select "New Table" to create a table
3. To edit existing table:
   - Click any cell in the table
   - Click table button dropdown again
   - Choose your operation (add/delete rows/columns)

### Expanded View
- Click the expand button (⛶) in toolbar
- Enjoy distraction-free writing with wider editor space
- Click again to return to normal view

## Technical Details

### Stack
- **Frontend**: Vanilla JavaScript (no framework dependencies)
- **Styling**: Tailwind CSS + DaisyUI
- **Icons**: Google Material Icons
- **Storage**: LocalStorage for settings and document store

### Architecture
- Single-page application
- `MarkiiupEditor` class handles all functionality
- Bidirectional HTML ↔ Markdown conversion
- Real-time text processing for links and tags

### File Structure
```
markiiup/
├── index.html          # Main application file
├── script.js           # Core JavaScript logic (MarkiiupEditor class)
├── styles.css          # Legacy styles (being phased out)
├── daisyui-custom.css  # Custom DaisyUI components
├── tailwind-styles.css # Tailwind utility classes
├── markiiup.png        # Application logo
├── CLAUDE.md          # AI assistant instructions
├── examplefile.md     # Feature showcase document
└── Document Name.md   # Test document for backlinks
```

## Browser Support

### Full Feature Support (v1.2)
- **Chrome 86+** (recommended) - Full File System Access API support
- **Edge 86+** - Full File System Access API support
- **Opera 72+** - Full File System Access API support

### Basic Support
- Firefox - All features except native file save dialog
- Safari - All features except native file save dialog
- Any modern browser with ES6+ support

## Contributing

We welcome contributions! Here's how you can help:

1. **Report Issues**: Click the help button (❓) in the app or visit [GitHub Issues](https://github.com/mtdmo/markiiup/issues)
2. **Feature Requests**: Share your ideas for new features
3. **Bug Reports**: Help us fix problems you encounter
4. **Code Contributions**: Fork, improve, and submit pull requests

## Roadmap

### Upcoming Features
- Enhanced document navigation UI
- Performance optimizations for larger documents
- Export options (PDF, DOCX)
- Plugin system for extensibility
- Cloud integration for document storage
- Advanced formatting options (text colors, highlighting)
- Real-time collaboration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Tailwind CSS](https://tailwindcss.com/)
- UI components from [DaisyUI](https://daisyui.com/)
- Icons from [Material Design Icons](https://fonts.google.com/icons)

## Version History

- **v1.2.3** (Current - December 2024) - Added Remove Formatting feature with format_clear toolbar button
- **v1.2.2** (September 2025) - Fixed inline code and code block styling issues where CSS was displayed as text
- **v1.2.1** (September 2025) - Added code formatting support (inline code and code blocks)
- **v1.2** (September 2025) - Font management (family & size), enhanced file handling with File System Access API, proper Save As dialog
- **v1.1** - Enhanced UI with expanded view, improved table operations, integrated help system
- **v1.0** - Initial release with core WYSIWYG editing, comments, wiki links, tags, and modern UI

---

Made with ❤️ from North Carolina, USA • markiiup v1.2.3

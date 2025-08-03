# markiiup

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub issues](https://img.shields.io/github/issues/yourusername/markiiup)](https://github.com/yourusername/markiiup/issues)
[![GitHub stars](https://img.shields.io/github/stars/yourusername/markiiup)](https://github.com/yourusername/markiiup/stargazers)

A modern JavaScript word processor that provides a Microsoft Word-like editing experience while saving files in Markdown format.

![markiiup Logo](markiiup.png)

## Overview

**markiiup** is a WYSIWYG (What You See Is What You Get) editor that allows users to create rich text documents with a familiar word processor interface, while seamlessly saving content in clean Markdown format. No side-by-side preview needed - just write naturally and let markiiup handle the conversion.

## Features

### 📝 Rich Text Editing
- **Familiar Interface**: Microsoft Word-like toolbar and editing experience
- **Text Formatting**: Bold, italic, underline, headings (H1-H6)
- **Lists**: Bullet and numbered lists
- **Tables**: Full table support with Markdown conversion
- **Links & Images**: Easy insertion with toolbar buttons

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

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/yourusername/markiiup.git
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
- Save your work as a `.md` file

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
├── script.js           # Core JavaScript logic
├── styles.css          # Legacy styles
├── daisyui-custom.css  # Custom DaisyUI components
├── markiiup.png        # Application logo
└── CLAUDE.md          # AI assistant instructions
```

## Browser Support

- Chrome (recommended)
- Firefox
- Safari
- Edge
- Any modern browser with ES6+ support

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Tailwind CSS](https://tailwindcss.com/)
- UI components from [DaisyUI](https://daisyui.com/)
- Icons from [Material Design Icons](https://fonts.google.com/icons)

---

Made with ❤️ using markiiup
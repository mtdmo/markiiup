# markiiup v1.2 Release Notes
*September 2025*

## 🎉 Introducing markiiup v1.2: Professional Typography & Modern File Management

We're excited to announce the release of markiiup v1.2, bringing professional font management capabilities and modern file handling to your favorite Markdown word processor. This update focuses on giving you more control over document appearance while streamlining the save workflow with cutting-edge browser APIs.

## ✨ What's New in v1.2

### 🔤 Complete Font Management System
Take full control of your document's typography with our new font management features:

#### Font Family Selection
- **8 Professional Fonts**: Choose from carefully selected typefaces perfect for any document type
  - Arial (clean, modern sans-serif)
  - Times New Roman (classic serif for formal documents)
  - Georgia (elegant serif with excellent readability)
  - Courier (monospace for code and technical content)
  - Verdana (highly readable sans-serif)
  - Trebuchet MS (distinctive sans-serif)
  - Palatino (sophisticated serif)
  - System Default (inherit from browser)

#### Font Size Control
- **Comprehensive Size Range**: Select from 8pt to 36pt
  - Quick access to common sizes: 8pt, 9pt, 10pt, 11pt, 12pt, 14pt, 16pt, 18pt, 20pt, 24pt, 28pt, 32pt, 36pt
  - Perfect for everything from fine print to eye-catching headers
  - Maintains size consistency across HTML and Markdown conversions

### 💾 Revolutionary File Management with File System Access API

#### Smart Save (In-Place Saving)
- **Seamless Updates**: When you open a file, markiiup remembers its location
- **One-Click Save**: Hit Save to instantly update the original file - no dialogs, no hassle
- **Persistent File Handle**: Maintains connection to your file throughout the editing session
- **Supported Browsers**: Chrome 86+, Edge 86+, Opera 72+

#### True Save As Dialog
- **Native File System Dialog**: Choose exactly where to save your document
- **Folder Navigation**: Browse and select any folder on your system
- **Rename on Save**: Change filename directly in the save dialog
- **Modern UX**: Feels just like saving in desktop applications

#### Intelligent Fallback System
- **Universal Compatibility**: Automatically detects browser capabilities
- **Graceful Degradation**: Falls back to download method for Firefox/Safari
- **No Features Lost**: All users can save their work, regardless of browser
- **Clear Feedback**: User-friendly notifications explain save behavior

### 🎨 UI & Toolbar Improvements

#### Reorganized Toolbar Layout
- **Better Organization**: Font controls grouped together for intuitive access
- **Improved Spacing**: Fixed flex wrapping for cleaner appearance on all screen sizes
- **Consistent Styling**: All dropdowns now match the markiiup theme perfectly
- **Visual Hierarchy**: Clear separation between formatting and file operations

#### Enhanced Dropdown Styling
- **Fixed Height Issues**: All selects now properly align with toolbar buttons
- **Theme Consistency**: Dropdowns fully integrated with markiiup's teal color scheme
- **Better Readability**: Improved contrast and sizing for dropdown options

## 🚀 How to Use the New Features

### Using Font Controls
1. **Select Text**: Highlight the text you want to format
2. **Choose Font Family**: Pick from the dropdown (defaults to Times New Roman)
3. **Adjust Size**: Select your preferred size (defaults to 12pt)
4. **Instant Preview**: Changes apply immediately in the editor

### Modern Save Workflow
1. **Open a File**: Use File → Open to load a document
2. **Edit Your Content**: Make your changes with full font control
3. **Quick Save**: Hit Save to update the original file instantly
4. **Save As**: Use Save As to create a copy or save to a new location

## 🔧 Technical Improvements

### Under the Hood
- **File Handle Persistence**: Maintains `currentFileHandle` throughout session
- **Writable Stream API**: Uses modern `createWritable()` for efficient file writing
- **Error Handling**: Comprehensive try-catch blocks for all file operations
- **Permission Management**: Handles file access permissions gracefully

### Code Quality
- **Cleaner Architecture**: Separated font management into dedicated methods
- **Better State Management**: Proper tracking of file handles and paths
- **Improved Comments**: Removed legacy table menu code from CSS
- **Consistent Formatting**: Standardized toolbar element spacing

## 📊 Version Comparison

| Feature | v1.1 | v1.2 |
|---------|------|------|
| Font Family Selection | ❌ | ✅ 8 fonts |
| Font Size Control | ❌ | ✅ 8pt-36pt |
| Save In-Place | ❌ | ✅ |
| Native Save As Dialog | ❌ | ✅ |
| File System Access API | ❌ | ✅ |
| Browser Fallback | Basic | Smart |
| Toolbar Organization | Good | Excellent |

## 🌐 Browser Compatibility

### Full Feature Support
- **Chrome 86+** ✅ All features including File System Access API
- **Edge 86+** ✅ All features including File System Access API  
- **Opera 72+** ✅ All features including File System Access API

### Basic Support (with automatic fallback)
- **Firefox** ⚠️ Font features work perfectly, file saves use download method
- **Safari** ⚠️ Font features work perfectly, file saves use download method
- **Mobile Browsers** ⚠️ Limited file system access, uses download fallback

## 🎯 Why Upgrade to v1.2?

### For Writers
- **Professional Documents**: Create beautifully formatted documents with proper typography
- **Faster Workflow**: Save time with one-click save to original location
- **Font Flexibility**: Match any style guide or personal preference

### For Developers
- **Modern APIs**: Experience cutting-edge web platform capabilities
- **Clean Markdown**: Font styles properly preserved in Markdown format
- **Better Integration**: File handling that feels native to the OS

### For Everyone
- **No Learning Curve**: Intuitive controls that work like traditional word processors
- **Cross-Platform**: Works on Windows, Mac, and Linux
- **Future-Proof**: Built on modern web standards

## 📈 What's Next?

We're already planning v1.3 with exciting features on the roadmap:
- Enhanced document navigation UI
- File explorer sidebar
- Advanced table features (sorting, templates, cell merging)
- Export to PDF and DOCX
- Full-text search across documents
- Text colors and highlighting

## 💬 Feedback & Support

We'd love to hear your thoughts on v1.2! 
- **Report Issues**: Click the ❓ button in the app or visit [GitHub Issues](https://github.com/mtdmo/markiiup/issues)
- **Feature Requests**: Share your ideas for v1.3 and beyond
- **Documentation**: Check out the updated User Guide for detailed instructions

## 🙏 Thank You

Thank you to our growing community of users who have made markiiup a success. Your feedback and support drive us to keep improving. Special thanks to everyone who reported issues and suggested features that made it into v1.2.

## 📥 Get Started

Simply refresh your browser if you're using the web version, or download the latest files from our [GitHub repository](https://github.com/mtdmo/markiiup). No installation or build process required - just open `index.html` and start writing!

---

**markiiup v1.2** - *Write in Word, Save in Markdown*

Released September 2025 | MIT License
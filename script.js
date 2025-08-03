class WordMarksEditor {
    constructor() {
        this.editor = document.getElementById('editor');
        this.currentFileName = 'untitled.md';
        this.comments = [];
        this.commentCounter = 1;
        this.commentsVisible = false;
        this.userSettings = this.loadUserSettings();
        this.documentLinks = new Set(); // Track linked documents
        this.documentTags = new Set(); // Track tags in document
        this.documentStore = this.loadDocumentStore(); // Simulate document database
        this.workingDirectory = this.detectWorkingDirectory(); // Track current working directory
        this.initializeEventListeners();
        this.loadTheme();
        this.updateStats();
        this.processWikiLinks();
        this.processTags();
        this.updateBacklinksPanel();
    }

    initializeEventListeners() {
        // Toolbar buttons
        document.getElementById('new-btn').addEventListener('click', () => this.newDocument());
        document.getElementById('open-btn').addEventListener('click', () => this.openDocument());
        document.getElementById('save-btn').addEventListener('click', () => this.saveDocument());
        
        // Formatting buttons
        document.getElementById('bold-btn').addEventListener('click', () => this.execCommand('bold'));
        document.getElementById('italic-btn').addEventListener('click', () => this.execCommand('italic'));
        document.getElementById('underline-btn').addEventListener('click', () => this.execCommand('underline'));
        
        // Heading selector
        document.getElementById('heading-select').addEventListener('change', (e) => this.formatHeading(e.target.value));
        
        // List buttons
        document.getElementById('bullet-list-btn').addEventListener('click', () => this.execCommand('insertUnorderedList'));
        document.getElementById('number-list-btn').addEventListener('click', () => this.execCommand('insertOrderedList'));
        
        // Link, image, table, and comment buttons
        document.getElementById('link-btn').addEventListener('click', () => this.insertLink());
        document.getElementById('image-btn').addEventListener('click', () => this.insertImage());
        document.getElementById('table-btn').addEventListener('click', () => this.insertTable());
        document.getElementById('comment-btn').addEventListener('click', () => this.addComment());
        document.getElementById('toggle-comments-btn').addEventListener('click', () => this.toggleCommentsPanel());
        document.getElementById('settings-btn').addEventListener('click', () => this.openSettings());
        document.getElementById('close-settings-btn').addEventListener('click', () => this.closeSettings());
        document.getElementById('save-settings-btn').addEventListener('click', () => this.saveSettings());
        document.getElementById('debug-store-btn').addEventListener('click', () => this.showDebugInfo());
        document.getElementById('clear-store-btn').addEventListener('click', () => this.clearDocumentStore());
        
        // File input
        document.getElementById('file-input').addEventListener('change', (e) => this.handleFileLoad(e));
        
        // Editor events
        this.editor.addEventListener('input', () => {
            this.updateStats();
            this.debounceWikiLinks();
            this.debounceTags();
            this.debounceDocumentUpdate();
        });
        this.editor.addEventListener('paste', (e) => this.handlePaste(e));
        this.editor.addEventListener('mouseup', () => this.handleSelection());
        
        // Prevent default drag and drop
        this.editor.addEventListener('dragover', (e) => e.preventDefault());
        this.editor.addEventListener('drop', (e) => e.preventDefault());
    }

    execCommand(command, value = null) {
        document.execCommand(command, false, value);
        this.editor.focus();
    }

    formatHeading(tag) {
        if (tag) {
            this.execCommand('formatBlock', tag);
        } else {
            this.execCommand('formatBlock', 'div');
        }
    }

    insertLink() {
        const url = prompt('Enter URL:');
        if (url) {
            this.execCommand('createLink', url);
        }
    }

    insertImage() {
        const url = prompt('Enter image URL:');
        if (url) {
            this.execCommand('insertImage', url);
        }
    }

    insertTable() {
        const rows = parseInt(prompt('Number of rows:', '3')) || 3;
        const cols = parseInt(prompt('Number of columns:', '3')) || 3;
        
        let tableHTML = '<table>';
        
        // Create header row
        tableHTML += '<tr>';
        for (let j = 0; j < cols; j++) {
            tableHTML += `<th>Header ${j + 1}</th>`;
        }
        tableHTML += '</tr>';
        
        // Create data rows
        for (let i = 1; i < rows; i++) {
            tableHTML += '<tr>';
            for (let j = 0; j < cols; j++) {
                tableHTML += `<td>Cell ${i},${j + 1}</td>`;
            }
            tableHTML += '</tr>';
        }
        
        tableHTML += '</table>';
        
        this.execCommand('insertHTML', tableHTML);
    }

    handleSelection() {
        const selection = window.getSelection();
        if (selection.rangeCount > 0 && !selection.isCollapsed) {
            this.lastSelection = selection.getRangeAt(0).cloneRange();
        }
    }

    addComment() {
        const selection = window.getSelection();
        if (selection.rangeCount === 0 || selection.isCollapsed) {
            alert('Please select some text to comment on.');
            return;
        }

        const selectedText = selection.toString();
        const commentText = prompt('Enter your comment:');
        
        if (!commentText) return;

        const commentId = `comment-${this.commentCounter++}`;
        const range = selection.getRangeAt(0);
        
        // Create comment highlight span
        const span = document.createElement('span');
        span.className = 'comment-highlight';
        span.setAttribute('data-comment-id', commentId);
        span.title = commentText;
        
        try {
            range.surroundContents(span);
        } catch (e) {
            // If surroundContents fails, use extractContents and appendChild
            const contents = range.extractContents();
            span.appendChild(contents);
            range.insertNode(span);
        }
        
        // Add comment to comments array
        const comment = {
            id: commentId,
            text: commentText,
            selectedText: selectedText,
            author: this.userSettings.name || 'User',
            timestamp: new Date().toLocaleString(),
            completed: false,
            status: 'open'
        };
        
        this.comments.push(comment);
        this.updateCommentsPanel();
        
        // Show comments panel if not visible
        if (!this.commentsVisible) {
            this.toggleCommentsPanel();
        }
        
        // Add click event to highlight
        span.addEventListener('click', () => this.highlightComment(commentId));
        
        selection.removeAllRanges();
    }

    toggleCommentStatus(commentId) {
        const comment = this.comments.find(c => c.id === commentId);
        if (comment) {
            comment.completed = !comment.completed;
            comment.status = comment.completed ? 'completed' : 'open';
            
            // Update highlight in editor
            const highlight = document.querySelector(`[data-comment-id="${commentId}"]`);
            if (highlight) {
                if (comment.completed) {
                    highlight.classList.add('completed');
                } else {
                    highlight.classList.remove('completed');
                }
            }
            
            this.updateCommentsPanel();
        }
    }
    
    deleteComment(commentId) {
        if (confirm('Are you sure you want to delete this comment?')) {
            // Remove from comments array
            this.comments = this.comments.filter(c => c.id !== commentId);
            
            // Remove highlight from editor
            const highlight = document.querySelector(`[data-comment-id="${commentId}"]`);
            if (highlight) {
                const parent = highlight.parentNode;
                const text = highlight.textContent;
                parent.replaceChild(document.createTextNode(text), highlight);
            }
            
            this.updateCommentsPanel();
        }
    }

    highlightComment(commentId) {
        // Remove active class from all highlights
        document.querySelectorAll('.comment-highlight.active').forEach(el => {
            el.classList.remove('active');
        });
        
        // Add active class to clicked highlight
        const highlight = document.querySelector(`[data-comment-id="${commentId}"]`);
        if (highlight) {
            highlight.classList.add('active');
        }
        
        // Scroll to corresponding comment in panel
        const commentElement = document.querySelector(`[data-comment-id="${commentId}"]`);
        if (commentElement) {
            commentElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    }

    updateCommentsPanel() {
        const commentsList = document.getElementById('comments-list');
        commentsList.innerHTML = '';
        
        this.comments.forEach(comment => {
            const commentDiv = document.createElement('div');
            commentDiv.className = `comment-item ${comment.completed ? 'completed' : ''}`;
            commentDiv.setAttribute('data-comment-id', comment.id);
            
            commentDiv.innerHTML = `
                <div class="card bg-base-100 shadow-sm border border-base-300 transition-all duration-300 ${comment.completed ? 'bg-success/5 border-success/30 opacity-80' : ''}">
                    <div class="card-body p-3">
                        <div class="flex justify-between items-start mb-2">
                            <div class="flex items-center gap-2">
                                <div class="badge badge-primary badge-xs"></div>
                                <span class="text-sm font-semibold text-primary">${comment.author}</span>
                                <div class="badge ${comment.completed ? 'badge-success' : 'badge-warning'} badge-sm">
                                    ${comment.status.toUpperCase()}
                                </div>
                            </div>
                            <div class="flex gap-1">
                                <button class="btn btn-xs ${comment.completed ? 'btn-outline btn-secondary' : 'btn-success'}" 
                                        onclick="editor.toggleCommentStatus('${comment.id}')">
                                    ${comment.completed ? 'Reopen' : 'Close'}
                                </button>
                                <button class="btn btn-xs btn-error btn-outline" 
                                        onclick="editor.deleteComment('${comment.id}')">
                                    Delete
                                </button>
                            </div>
                        </div>
                        <div class="text-sm mb-2 ${comment.completed ? 'line-through text-base-content/60' : ''}">
                            <div class="font-medium text-base-content/80">"${comment.selectedText}"</div>
                            <div class="mt-1">${comment.text}</div>
                        </div>
                        <div class="text-xs text-base-content/60">${comment.timestamp}</div>
                    </div>
                </div>
            `;
            
            commentDiv.addEventListener('click', (e) => {
                if (!e.target.matches('button')) {
                    this.highlightComment(comment.id);
                }
            });
            commentsList.appendChild(commentDiv);
        });
    }

    toggleCommentsPanel() {
        const panel = document.getElementById('comments-panel');
        this.commentsVisible = !this.commentsVisible;
        panel.style.display = this.commentsVisible ? 'flex' : 'none';
    }

    handlePaste(e) {
        e.preventDefault();
        const text = (e.clipboardData || window.clipboardData).getData('text/plain');
        this.execCommand('insertText', text);
    }

    newDocument() {
        this.editor.innerHTML = '<p>Start typing your document here...</p>';
        this.currentFileName = 'untitled.md';
        this.comments = [];
        this.commentCounter = 1;
        this.documentTags.clear();
        this.updateCommentsPanel();
        this.updateTagsPanel();
        this.updateBacklinksPanel();
        this.updateStats();
    }

    openDocument() {
        document.getElementById('file-input').click();
    }

    handleFileLoad(e) {
        const file = e.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (e) => {
                const content = e.target.result;
                this.loadMarkdownContent(content);
                this.currentFileName = file.name;
                this.updateStats();
            };
            reader.readAsText(file);
        }
    }

    loadMarkdownContent(content) {
        // Parse comments from markdown
        this.comments = [];
        this.commentCounter = 1;
        
        // Extract comments (looking for HTML comments with special format)
        const commentRegex = /<!--\s*COMMENT\s*(\d+):\s*(.+?)\s*-->/g;
        let match;
        
        while ((match = commentRegex.exec(content)) !== null) {
            const commentId = `comment-${match[1]}`;
            const commentData = JSON.parse(match[2]);
            commentData.id = commentId;
            this.comments.push(commentData);
            this.commentCounter = Math.max(this.commentCounter, parseInt(match[1]) + 1);
        }
        
        // Remove comment markers from content for display
        content = content.replace(commentRegex, '');
        
        // Convert markdown to HTML
        this.editor.innerHTML = this.markdownToHtml(content);
        
        // Re-apply comment highlights
        this.reapplyCommentHighlights();
        this.updateCommentsPanel();
        
        // Process wiki links and tags after loading
        this.processWikiLinks();
        this.processTags();
        this.updateBacklinksPanel();
    }

    reapplyCommentHighlights() {
        // This is a simplified approach - in a production app you'd want more sophisticated text matching
        this.comments.forEach(comment => {
            const textNodes = this.getTextNodes(this.editor);
            textNodes.forEach(node => {
                if (node.textContent.includes(comment.selectedText)) {
                    const text = node.textContent;
                    const index = text.indexOf(comment.selectedText);
                    if (index !== -1) {
                        const before = text.substring(0, index);
                        const selected = text.substring(index, index + comment.selectedText.length);
                        const after = text.substring(index + comment.selectedText.length);
                        
                        const span = document.createElement('span');
                        span.className = 'comment-highlight';
                        span.setAttribute('data-comment-id', comment.id);
                        span.textContent = selected;
                        span.title = comment.text;
                        span.addEventListener('click', () => this.highlightComment(comment.id));
                        
                        // Apply completed styling if comment is completed
                        if (comment.completed) {
                            span.classList.add('completed');
                        }
                        
                        const parent = node.parentNode;
                        if (before) parent.insertBefore(document.createTextNode(before), node);
                        parent.insertBefore(span, node);
                        if (after) parent.insertBefore(document.createTextNode(after), node);
                        parent.removeChild(node);
                        
                        return; // Only highlight first occurrence
                    }
                }
            });
        });
    }

    getTextNodes(element) {
        const walker = document.createTreeWalker(
            element,
            NodeFilter.SHOW_TEXT,
            null,
            false
        );
        
        const textNodes = [];
        let node;
        while (node = walker.nextNode()) {
            textNodes.push(node);
        }
        return textNodes;
    }

    saveDocument() {
        const htmlContent = this.editor.innerHTML;
        let markdownContent = this.htmlToMarkdown(htmlContent);
        
        // Add comments to markdown as HTML comments
        if (this.comments.length > 0) {
            markdownContent += '\n\n<!-- COMMENTS -->\n';
            this.comments.forEach((comment, index) => {
                const commentData = {
                    text: comment.text,
                    selectedText: comment.selectedText,
                    author: comment.author,
                    timestamp: comment.timestamp,
                    completed: comment.completed || false,
                    status: comment.status || 'open'
                };
                markdownContent += `<!-- COMMENT ${comment.id.replace('comment-', '')}: ${JSON.stringify(commentData)} -->\n`;
            });
        }
        
        // Update document store before saving
        this.updateDocumentInStore();
        
        const blob = new Blob([markdownContent], { type: 'text/markdown' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = this.currentFileName;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    htmlToMarkdown(html) {
        let markdown = html;
        
        // Convert tables first
        markdown = markdown.replace(/<table[^>]*>(.*?)<\/table>/gis, (match, content) => {
            let tableMarkdown = '\n';
            const rows = content.match(/<tr[^>]*>(.*?)<\/tr>/gis) || [];
            
            rows.forEach((row, rowIndex) => {
                const cells = row.match(/<t[hd][^>]*>(.*?)<\/t[hd]>/gis) || [];
                const cellContents = cells.map(cell => {
                    return cell.replace(/<[^>]*>/g, '').trim();
                });
                
                tableMarkdown += '| ' + cellContents.join(' | ') + ' |\n';
                
                // Add separator after header row
                if (rowIndex === 0) {
                    tableMarkdown += '| ' + cellContents.map(() => '---').join(' | ') + ' |\n';
                }
            });
            
            return tableMarkdown + '\n';
        });
        
        // Convert headings
        markdown = markdown.replace(/<h1[^>]*>(.*?)<\/h1>/gi, '# $1\n\n');
        markdown = markdown.replace(/<h2[^>]*>(.*?)<\/h2>/gi, '## $1\n\n');
        markdown = markdown.replace(/<h3[^>]*>(.*?)<\/h3>/gi, '### $1\n\n');
        markdown = markdown.replace(/<h4[^>]*>(.*?)<\/h4>/gi, '#### $1\n\n');
        markdown = markdown.replace(/<h5[^>]*>(.*?)<\/h5>/gi, '##### $1\n\n');
        markdown = markdown.replace(/<h6[^>]*>(.*?)<\/h6>/gi, '###### $1\n\n');
        
        // Convert bold and italic
        markdown = markdown.replace(/<strong[^>]*>(.*?)<\/strong>/gi, '**$1**');
        markdown = markdown.replace(/<b[^>]*>(.*?)<\/b>/gi, '**$1**');
        markdown = markdown.replace(/<em[^>]*>(.*?)<\/em>/gi, '*$1*');
        markdown = markdown.replace(/<i[^>]*>(.*?)<\/i>/gi, '*$1*');
        
        // Convert underline (not standard markdown, but we'll use HTML)
        markdown = markdown.replace(/<u[^>]*>(.*?)<\/u>/gi, '<u>$1</u>');
        
        // Convert wiki links back to markdown
        markdown = markdown.replace(/<span[^>]*class="[^"]*wiki-link[^"]*"[^>]*data-link="([^"]*)"[^>]*>([^<]*)<\/span>/gi, '[[$1]]');
        
        // Convert tags back to markdown
        markdown = markdown.replace(/<span[^>]*class="tag"[^>]*data-tag="([^"]*)"[^>]*>([^<]*)<span[^>]*class="tag-count"[^>]*>[^<]*<\/span><\/span>/gi, '#$2');
        markdown = markdown.replace(/<span[^>]*class="tag"[^>]*data-tag="([^"]*)"[^>]*>([^<]*)<\/span>/gi, '#$2');
        
        // Convert regular links
        markdown = markdown.replace(/<a[^>]*href="([^"]*)"[^>]*>(.*?)<\/a>/gi, '[$2]($1)');
        
        // Convert images
        markdown = markdown.replace(/<img[^>]*src="([^"]*)"[^>]*alt="([^"]*)"[^>]*>/gi, '![$2]($1)');
        markdown = markdown.replace(/<img[^>]*src="([^"]*)"[^>]*>/gi, '![]($1)');
        
        // Convert lists
        markdown = markdown.replace(/<ul[^>]*>(.*?)<\/ul>/gis, (match, content) => {
            return content.replace(/<li[^>]*>(.*?)<\/li>/gi, '- $1\n') + '\n';
        });
        
        markdown = markdown.replace(/<ol[^>]*>(.*?)<\/ol>/gis, (match, content) => {
            let counter = 1;
            return content.replace(/<li[^>]*>(.*?)<\/li>/gi, () => `${counter++}. $1\n`) + '\n';
        });
        
        // Remove comment highlights but preserve text
        markdown = markdown.replace(/<span[^>]*class="[^"]*comment-highlight[^"]*"[^>]*>(.*?)<\/span>/gi, '$1');
        
        // Convert paragraphs
        markdown = markdown.replace(/<p[^>]*>(.*?)<\/p>/gi, '$1\n\n');
        
        // Convert line breaks
        markdown = markdown.replace(/<br[^>]*>/gi, '\n');
        
        // Clean up extra whitespace and HTML tags
        markdown = markdown.replace(/<[^>]*>/g, '');
        markdown = markdown.replace(/&nbsp;/g, ' ');
        markdown = markdown.replace(/&amp;/g, '&');
        markdown = markdown.replace(/&lt;/g, '<');
        markdown = markdown.replace(/&gt;/g, '>');
        markdown = markdown.replace(/&quot;/g, '"');
        
        // Clean up excessive newlines
        markdown = markdown.replace(/\n{3,}/g, '\n\n');
        
        return markdown.trim();
    }

    markdownToHtml(markdown) {
        let html = markdown;
        
        // Convert tables first
        const tableRegex = /\n\s*\|(.+)\|\s*\n\s*\|[-\s|:]+\|\s*\n((?:\s*\|.+\|\s*\n)*)/g;
        html = html.replace(tableRegex, (match, header, rows) => {
            let tableHtml = '<table>';
            
            // Process header
            const headerCells = header.split('|').map(cell => cell.trim()).filter(cell => cell);
            tableHtml += '<tr>';
            headerCells.forEach(cell => {
                tableHtml += `<th>${cell}</th>`;
            });
            tableHtml += '</tr>';
            
            // Process rows
            const rowLines = rows.trim().split('\n');
            rowLines.forEach(rowLine => {
                if (rowLine.trim()) {
                    const cells = rowLine.split('|').map(cell => cell.trim()).filter(cell => cell);
                    tableHtml += '<tr>';
                    cells.forEach(cell => {
                        tableHtml += `<td>${cell}</td>`;
                    });
                    tableHtml += '</tr>';
                }
            });
            
            tableHtml += '</table>';
            return tableHtml;
        });
        
        // Convert headings
        html = html.replace(/^# (.*$)/gim, '<h1>$1</h1>');
        html = html.replace(/^## (.*$)/gim, '<h2>$1</h2>');
        html = html.replace(/^### (.*$)/gim, '<h3>$1</h3>');
        html = html.replace(/^#### (.*$)/gim, '<h4>$1</h4>');
        html = html.replace(/^##### (.*$)/gim, '<h5>$1</h5>');
        html = html.replace(/^###### (.*$)/gim, '<h6>$1</h6>');
        
        // Convert bold and italic
        html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
        html = html.replace(/\*(.*?)\*/g, '<em>$1</em>');
        
        // Convert wiki links first
        html = html.replace(/\[\[([^\]]+)\]\]/g, '<span class="wiki-link broken" data-link="$1" onclick="editor.handleWikiLinkClick(\'$1\')">$1</span>');
        
        // Convert tags
        html = html.replace(/#([a-zA-Z0-9_-]+)(?!\w)/g, '<span class="tag" data-tag="$1" onclick="editor.handleTagClick(\'$1\')">$1</span>');
        
        // Convert regular links
        html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
        
        // Convert images
        html = html.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1">');
        
        // Convert lists
        html = html.replace(/^\- (.+)$/gm, '<li>$1</li>');
        html = html.replace(/^(\d+)\. (.+)$/gm, '<li>$2</li>');
        
        // Wrap consecutive list items in ul/ol tags
        html = html.replace(/(<li>.*<\/li>)/s, '<ul>$1</ul>');
        
        // Convert paragraphs (simple approach)
        html = html.replace(/\n\n/g, '</p><p>');
        html = '<p>' + html + '</p>';
        
        // Clean up empty paragraphs
        html = html.replace(/<p><\/p>/g, '');
        html = html.replace(/<p>(<[^>]+>)<\/p>/g, '$1');
        
        return html;
    }

    updateStats() {
        const text = this.editor.innerText || this.editor.textContent;
        const words = text.trim() ? text.trim().split(/\s+/).length : 0;
        const chars = text.length;
        
        document.getElementById('word-count').textContent = `${words} words`;
        document.getElementById('char-count').textContent = `${chars} characters`;
    }
    
    loadUserSettings() {
        const saved = localStorage.getItem('wordmarks-settings');
        if (saved) {
            try {
                return JSON.parse(saved);
            } catch (e) {
                console.warn('Failed to parse saved settings:', e);
            }
        }
        return {
            name: '',
            email: ''
        };
    }

    saveUserSettings() {
        localStorage.setItem('wordmarks-settings', JSON.stringify(this.userSettings));
    }

    openSettings() {
        const modal = document.getElementById('settings-modal');
        const nameInput = document.getElementById('user-name');
        const emailInput = document.getElementById('user-email');
        
        // Populate current values
        nameInput.value = this.userSettings.name || '';
        emailInput.value = this.userSettings.email || '';
        
        // Open DaisyUI modal by checking the checkbox
        modal.checked = true;
        setTimeout(() => nameInput.focus(), 100);
    }

    closeSettings() {
        const modal = document.getElementById('settings-modal');
        modal.checked = false;
    }

    saveSettings() {
        const nameInput = document.getElementById('user-name');
        const emailInput = document.getElementById('user-email');
        
        this.userSettings.name = nameInput.value.trim();
        this.userSettings.email = emailInput.value.trim();
        
        this.saveUserSettings();
        this.closeSettings();
        
        // Show confirmation
        if (this.userSettings.name) {
            console.log(`Settings saved for ${this.userSettings.name}`);
        }
    }

    showDebugInfo() {
        // Force update the document store
        this.updateDocumentInStore();
        
        const info = {
            currentFile: this.currentFileName,
            normalizedName: this.normalizeDocumentName(this.currentFileName),
            workingDirectory: this.workingDirectory,
            documentStore: this.documentStore,
            currentLinks: Array.from(this.documentLinks),
            currentTags: Array.from(this.documentTags),
            backlinks: this.findBacklinks()
        };
        
        console.log('Debug Info:', info);
        
        const debugText = `Debug Info (check console for full details):

Current File: ${info.currentFile}
Normalized: ${info.normalizedName}
Working Dir: ${info.workingDirectory}
Documents in Store: ${Object.keys(this.documentStore).length}
Links in Current Doc: ${info.currentLinks.length}
Tags in Current Doc: ${info.currentTags.length}
Backlinks Found: ${info.backlinks.length}

Stored Documents:
${Object.keys(this.documentStore).map(key => `- ${key} (${this.documentStore[key].fileName})`).join('\n')}`;
        
        alert(debugText);
    }

    clearDocumentStore() {
        if (confirm('Clear all document store data? This will remove backlink tracking.')) {
            this.documentStore = {};
            this.saveDocumentStore();
            this.updateBacklinksPanel();
            alert('Document store cleared!');
        }
    }

    // Wiki Links functionality
    debounceWikiLinks() {
        clearTimeout(this.wikiLinkTimeout);
        this.wikiLinkTimeout = setTimeout(() => {
            this.processWikiLinks();
        }, 500);
    }

    processWikiLinks() {
        const content = this.editor.innerHTML;
        const wikiLinkRegex = /\[\[([^\]]+)\]\]/g;
        let newContent = content;
        
        // Remove existing wiki link spans to reprocess
        newContent = newContent.replace(/<span class="wiki-link[^"]*"[^>]*>([^<]+)<\/span>/g, '[[$1]]');
        
        // Find and replace wiki links
        newContent = newContent.replace(wikiLinkRegex, (match, linkText) => {
            const trimmedText = linkText.trim();
            this.documentLinks.add(trimmedText);
            
            // For now, all links are "broken" since we don't have a document store
            // In a full implementation, you'd check if the document exists
            const isExisting = false; // This would check your document database
            const cssClass = isExisting ? 'wiki-link' : 'wiki-link broken';
            
            return `<span class="${cssClass}" data-link="${trimmedText}" onclick="editor.handleWikiLinkClick('${trimmedText}')">${trimmedText}</span>`;
        });
        
        if (newContent !== content) {
            const selection = window.getSelection();
            const range = selection.rangeCount > 0 ? selection.getRangeAt(0) : null;
            const startOffset = range ? range.startOffset : 0;
            const endOffset = range ? range.endOffset : 0;
            
            this.editor.innerHTML = newContent;
            
            // Try to restore cursor position (basic implementation)
            if (range) {
                try {
                    const newRange = document.createRange();
                    const walker = document.createTreeWalker(
                        this.editor,
                        NodeFilter.SHOW_TEXT,
                        null,
                        false
                    );
                    
                    let currentOffset = 0;
                    let textNode;
                    
                    while (textNode = walker.nextNode()) {
                        const nodeLength = textNode.textContent.length;
                        if (currentOffset + nodeLength >= startOffset) {
                            newRange.setStart(textNode, Math.min(startOffset - currentOffset, nodeLength));
                            newRange.setEnd(textNode, Math.min(endOffset - currentOffset, nodeLength));
                            selection.removeAllRanges();
                            selection.addRange(newRange);
                            break;
                        }
                        currentOffset += nodeLength;
                    }
                } catch (e) {
                    // If cursor restoration fails, just place it at the end
                    this.editor.focus();
                }
            }
        }
    }

    handleWikiLinkClick(linkText) {
        const normalizedLinkText = this.normalizeDocumentName(linkText);
        
        // Check if document exists in our store
        const existingDoc = Object.values(this.documentStore).find(doc => 
            (doc.normalizedName || this.normalizeDocumentName(doc.title)) === normalizedLinkText
        );
        
        if (existingDoc) {
            const shouldOpen = confirm(`Open "${existingDoc.displayTitle || existingDoc.title}"? This will replace the current document.`);
            if (shouldOpen) {
                this.openBacklinkedDocument(existingDoc.fileName);
            }
        } else {
            const shouldCreate = confirm(`Document "${linkText}" doesn't exist yet. Would you like to create it?`);
            if (shouldCreate) {
                this.createNewDocument(linkText);
            }
        }
    }

    createNewDocument(documentName) {
        // Save current document first
        const shouldSave = confirm('Save current document before creating new one?');
        if (shouldSave) {
            this.saveDocument();
        }
        
        // Create new document
        this.editor.innerHTML = `<h1>${documentName}</h1><p>Start writing your document here...</p>`;
        this.currentFileName = `${documentName.replace(/[^a-zA-Z0-9\s-]/g, '').replace(/\s+/g, '-').toLowerCase()}.md`;
        this.comments = [];
        this.commentCounter = 1;
        this.documentTags.clear();
        this.updateCommentsPanel();
        this.updateTagsPanel();
        this.updateBacklinksPanel();
        this.updateStats();
        
        // Focus on the editor
        this.editor.focus();
        
        // Place cursor after the title
        const h1 = this.editor.querySelector('h1');
        if (h1 && h1.nextSibling) {
            const range = document.createRange();
            const selection = window.getSelection();
            range.setStart(h1.nextSibling, 0);
            range.setEnd(h1.nextSibling, 0);
            selection.removeAllRanges();
            selection.addRange(range);
        }
    }

    getAllLinkedDocuments() {
        return Array.from(this.documentLinks);
    }

    // Tags functionality
    debounceTags() {
        clearTimeout(this.tagTimeout);
        this.tagTimeout = setTimeout(() => {
            this.processTags();
        }, 300);
    }

    processTags() {
        const content = this.editor.innerHTML;
        const tagRegex = /#([a-zA-Z0-9_-]+)(?!\w)/g;
        let newContent = content;
        
        // Clear existing tags set
        this.documentTags.clear();
        
        // Remove existing tag spans to reprocess
        newContent = newContent.replace(/<span class="tag"[^>]*>([^<]+)<\/span>/g, '#$1');
        
        // Find and replace tags
        newContent = newContent.replace(tagRegex, (match, tagName) => {
            this.documentTags.add(tagName.toLowerCase());
            return `<span class="tag" data-tag="${tagName.toLowerCase()}" onclick="editor.handleTagClick('${tagName.toLowerCase()}')">${tagName}</span>`;
        });
        
        if (newContent !== content) {
            const selection = window.getSelection();
            const range = selection.rangeCount > 0 ? selection.getRangeAt(0) : null;
            const startOffset = range ? range.startOffset : 0;
            
            this.editor.innerHTML = newContent;
            
            // Try to restore cursor position
            if (range) {
                try {
                    const newRange = document.createRange();
                    const walker = document.createTreeWalker(
                        this.editor,
                        NodeFilter.SHOW_TEXT,
                        null,
                        false
                    );
                    
                    let currentOffset = 0;
                    let textNode;
                    
                    while (textNode = walker.nextNode()) {
                        const nodeLength = textNode.textContent.length;
                        if (currentOffset + nodeLength >= startOffset) {
                            newRange.setStart(textNode, Math.min(startOffset - currentOffset, nodeLength));
                            newRange.collapse(true);
                            selection.removeAllRanges();
                            selection.addRange(newRange);
                            break;
                        }
                        currentOffset += nodeLength;
                    }
                } catch (e) {
                    this.editor.focus();
                }
            }
        }
        
        // Update tags panel
        this.updateTagsPanel();
    }

    handleTagClick(tagName) {
        // For now, show which tag was clicked
        // In a full implementation, this could:
        // 1. Search for all documents with this tag
        // 2. Show a filtered view
        // 3. Open a tag-based search
        console.log(`Clicked tag: ${tagName}`);
        alert(`Tag "${tagName}" clicked! In a full implementation, this would show all documents with this tag.`);
    }

    updateTagsPanel() {
        const tagsCloud = document.getElementById('tags-cloud');
        tagsCloud.innerHTML = '';
        
        if (this.documentTags.size === 0) {
            tagsCloud.innerHTML = '<span style="color: #605e5c; font-style: italic; font-size: 12px;">No tags in this document</span>';
            return;
        }
        
        // Convert to array and sort
        const sortedTags = Array.from(this.documentTags).sort();
        
        sortedTags.forEach(tag => {
            const tagElement = document.createElement('span');
            tagElement.className = 'tag';
            tagElement.setAttribute('data-tag', tag);
            tagElement.textContent = tag;
            tagElement.onclick = () => this.handleTagClick(tag);
            
            // Add count (for now always 1, but could count occurrences)
            const countSpan = document.createElement('span');
            countSpan.className = 'tag-count';
            countSpan.textContent = '1';
            tagElement.appendChild(countSpan);
            
            tagsCloud.appendChild(tagElement);
        });
    }

    getAllTags() {
        return Array.from(this.documentTags);
    }

    // Document Store and Backlinks functionality
    debounceDocumentUpdate() {
        clearTimeout(this.documentUpdateTimeout);
        this.documentUpdateTimeout = setTimeout(() => {
            this.updateDocumentInStore();
        }, 2000); // Update document store every 2 seconds of inactivity
    }

    loadDocumentStore() {
        const saved = localStorage.getItem('wordmarks-document-store');
        if (saved) {
            try {
                return JSON.parse(saved);
            } catch (e) {
                console.warn('Failed to parse document store:', e);
            }
        }
        return {};
    }

    saveDocumentStore() {
        localStorage.setItem('wordmarks-document-store', JSON.stringify(this.documentStore));
    }

    detectWorkingDirectory() {
        // Try to detect working directory from current location
        const currentPath = window.location.pathname;
        const pathParts = currentPath.split('/');
        
        // Remove the HTML file from the path to get directory
        pathParts.pop();
        return pathParts.join('/') || '/';
    }

    normalizeDocumentName(name) {
        // Handle both file paths and simple names
        let normalized = name;
        
        // If it's a path, extract just the filename
        if (name.includes('/')) {
            const parts = name.split('/');
            normalized = parts[parts.length - 1];
        }
        
        // Remove .md extension if present
        if (normalized.endsWith('.md')) {
            normalized = normalized.slice(0, -3);
        }
        
        // Normalize for consistent matching
        return normalized.toLowerCase()
                  .replace(/[^a-zA-Z0-9\s-]/g, '') // Remove special chars
                  .replace(/\s+/g, '-') // Replace spaces with hyphens
                  .trim();
    }

    resolveDocumentPath(linkText) {
        // Convert wiki link text to potential file paths
        const possibilities = [
            linkText, // Exact text
            `${linkText}.md`, // Add .md extension
            `./${linkText}`, // Relative path
            `./${linkText}.md`, // Relative with extension
            `${this.workingDirectory}/${linkText}`, // Full path
            `${this.workingDirectory}/${linkText}.md` // Full path with extension
        ];
        
        return possibilities;
    }

    updateDocumentInStore() {
        // Store current document info for backlink tracking
        const documentKey = this.normalizeDocumentName(this.currentFileName);
        const content = this.editor.innerHTML;
        
        // Extract all wiki links from current document
        const wikiLinkRegex = /\[\[([^\]]+)\]\]/g;
        const plainContent = this.editor.innerText || this.editor.textContent;
        const links = [];
        const rawLinks = [];
        let match;
        
        while ((match = wikiLinkRegex.exec(plainContent)) !== null) {
            const rawLink = match[1].trim();
            rawLinks.push(rawLink);
            // Store both normalized and raw versions for flexible matching
            links.push({
                raw: rawLink,
                normalized: this.normalizeDocumentName(rawLink),
                possiblePaths: this.resolveDocumentPath(rawLink)
            });
        }
        
        this.documentStore[documentKey] = {
            title: this.currentFileName.replace('.md', ''),
            displayTitle: this.currentFileName.replace('.md', ''),
            fileName: this.currentFileName,
            filePath: `${this.workingDirectory}/${this.currentFileName}`,
            normalizedName: documentKey,
            links: links,
            rawLinks: rawLinks, // Keep original link text
            tags: Array.from(this.documentTags),
            lastModified: new Date().toISOString(),
            content: plainContent.substring(0, 300) // Store more content for better context
        };
        
        console.log('Updated document store:', {
            documentKey,
            fileName: this.currentFileName,
            workingDirectory: this.workingDirectory,
            links,
            rawLinks,
            store: this.documentStore
        });
        
        this.saveDocumentStore();
        this.updateBacklinksPanel();
    }

    findBacklinks() {
        const currentDocNormalized = this.normalizeDocumentName(this.currentFileName);
        const currentTitle = this.currentFileName.replace('.md', '');
        const backlinks = [];
        
        console.log('Looking for backlinks to:', {
            fileName: this.currentFileName,
            normalized: currentDocNormalized,
            title: currentTitle
        });
        console.log('Document store:', this.documentStore);
        
        // Search through all stored documents for links to current document
        Object.values(this.documentStore).forEach(doc => {
            console.log('Checking document:', doc.fileName, 'with links:', doc.links);
            
            // Check if this document links to the current document
            let hasBacklink = false;
            let matchedLink = null;
            
            if (doc.links && Array.isArray(doc.links)) {
                doc.links.forEach(link => {
                    // Handle both old format (string) and new format (object)
                    const linkData = typeof link === 'string' ? { raw: link, normalized: this.normalizeDocumentName(link) } : link;
                    
                    // Check multiple ways the link might match:
                    const matches = [
                        linkData.normalized === currentDocNormalized, // Normalized match
                        linkData.raw === currentTitle, // Exact title match
                        linkData.raw === this.currentFileName, // Filename match
                        linkData.raw.toLowerCase() === currentTitle.toLowerCase(), // Case-insensitive title
                        this.normalizeDocumentName(linkData.raw) === this.normalizeDocumentName(currentTitle) // Double normalize
                    ];
                    
                    if (matches.some(match => match)) {
                        hasBacklink = true;
                        matchedLink = linkData.raw;
                        console.log('Found backlink match:', {
                            from: doc.fileName,
                            linkRaw: linkData.raw,
                            linkNormalized: linkData.normalized,
                            currentNormalized: currentDocNormalized,
                            currentTitle: currentTitle
                        });
                    }
                });
            }
            
            if (hasBacklink) {
                // Find context around the link in the document content
                const escapedLink = matchedLink.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
                const contextPattern = new RegExp(`.{0,50}\\[\\[${escapedLink}\\]\\].{0,50}`, 'i');
                const contextMatch = doc.content.match(contextPattern);
                
                backlinks.push({
                    title: doc.displayTitle || doc.title,
                    fileName: doc.fileName,
                    filePath: doc.filePath,
                    context: contextMatch ? contextMatch[0] : `Contains link to [[${matchedLink}]]`,
                    lastModified: doc.lastModified,
                    matchedLink: matchedLink
                });
                
                console.log('Added backlink from:', doc.title);
            }
        });
        
        console.log('Total backlinks found:', backlinks.length);
        return backlinks;
    }

    updateBacklinksPanel() {
        const backlinksList = document.getElementById('backlinks-list');
        const backlinks = this.findBacklinks();
        
        backlinksList.innerHTML = '';
        
        if (backlinks.length === 0) {
            backlinksList.innerHTML = `
                <div class="no-backlinks">
                    No documents link to this page<br>
                    <small style="color: #888; font-size: 10px;">
                        Current: ${this.currentFileName}<br>
                        Normalized: ${this.normalizeDocumentName(this.currentFileName)}<br>
                        Documents in store: ${Object.keys(this.documentStore).length}
                    </small>
                </div>`;
            return;
        }
        
        backlinks.forEach(backlink => {
            const backlinkDiv = document.createElement('div');
            backlinkDiv.className = 'backlink-item';
            backlinkDiv.onclick = () => this.openBacklinkedDocument(backlink.fileName);
            
            backlinkDiv.innerHTML = `
                <div class="backlink-title">${backlink.title}</div>
                <div class="backlink-context">...${backlink.context}...</div>
                <div style="font-size: 10px; color: #888; margin-top: 4px;">
                    📄 ${backlink.fileName} → [[${backlink.matchedLink}]]
                </div>
            `;
            
            backlinksList.appendChild(backlinkDiv);
        });
    }

    openBacklinkedDocument(fileName) {
        // For now, show an alert. In a full implementation, this would:
        // 1. Load the document from storage
        // 2. Switch to that document
        // 3. Update the editor content
        
        const doc = Object.values(this.documentStore).find(d => d.fileName === fileName);
        if (doc) {
            const shouldSwitch = confirm(`Open "${doc.title}"? This will replace the current document.`);
            if (shouldSwitch) {
                // Save current document first
                this.updateDocumentInStore();
                
                // Simulate loading the document
                alert(`Opening "${doc.title}"\n\nIn a full implementation, this would load the document content.`);
            }
        }
    }

    toggleTheme() {
        // Disabled - force light mode only
        this.forceLightMode();
    }

    loadTheme() {
        // Force light mode only
        this.forceLightMode();
    }

    // Force light mode method
    forceLightMode() {
        const body = document.body;
        const html = document.documentElement;
        const sunIcon = document.getElementById('sun-icon');
        const moonIcon = document.getElementById('moon-icon');
        
        // Clear any existing theme preferences
        localStorage.removeItem('markiiup-theme');
        
        // Force light theme
        html.setAttribute('data-theme', 'markiiup');
        body.setAttribute('data-theme', 'markiiup');
        
        // Ensure light theme icons are shown
        if (sunIcon && moonIcon) {
            sunIcon.classList.remove('hidden');
            moonIcon.classList.add('hidden');
        }
        
        console.log('Forced light mode active');
    }
}

// Global editor instance for button onclick handlers
let editor;

// Initialize the editor when the page loads
document.addEventListener('DOMContentLoaded', () => {
    editor = new WordMarksEditor();
    
    // DaisyUI modal handles click outside automatically via checkbox
    
    // Close modal with Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            const modal = document.getElementById('settings-modal');
            if (modal.checked) {
                editor.closeSettings();
            }
        }
    });
});
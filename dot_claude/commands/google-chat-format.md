# Google Chat Format Command

Convert text to Google Chat compatible formatting automatically.

## Usage
```bash
claude chat --file ~/.claude/commands/google-chat-format.md [TEXT|FILE]
```

## Arguments
- `TEXT` (optional): Text to convert inline
- `FILE` (optional): File path containing text to convert
- If no arguments provided, processes text from clipboard or stdin

## Workflow

1. **Text Input**
   - Accept text from command arguments, file, clipboard, or stdin
   - Preserve existing structure and intent

2. **Format Conversion**
   - Convert Markdown headers (`#`, `##`, etc.) to bold text (`*Header*`)
   - Convert double asterisks (`**bold**`) to single asterisks (`*bold*`)
   - Replace hyphens and asterisks in lists with bullet symbols (`•`)
   - Preserve existing backticks for code formatting
   - Add proper spacing around formatted elements

3. **Structure Enhancement**
   - Ensure blank lines between sections
   - Format labels with colons: `*Label:* description`
   - Maintain readability for mobile viewing

## Conversion Rules

### Headers
- `# Header` → `*Header*`
- `## Subheader` → `*Subheader*`
- `### Section` → `*Section*`

### Text Formatting
- `**bold**` → `*bold*`
- `__bold__` → `*bold*`
- Preserve existing `*bold*` formatting
- Preserve `` `code` `` formatting

### Lists
- `- item` → `• item`
- `* item` → `• item`
- `+ item` → `• item`
- Preserve numbered lists as-is

### Special Patterns
- `**Label:**` → `*Label:*`
- Multiple blank lines → Single blank line
- Trailing whitespace → Cleaned

## Examples

### Input:
```markdown
# Meeting Notes

## Key Decisions
- Approved budget increase
- **Priority:** High urgency items first
- Next meeting: `2024-01-15`

### Action Items
* Review proposal
* Update documentation
```

### Output:
```
*Meeting Notes*

*Key Decisions*
• Approved budget increase
• *Priority:* High urgency items first
• Next meeting: `2024-01-15`

*Action Items*
• Review proposal
• Update documentation
```

## Features

- **Batch Processing**: Convert multiple files at once
- **Clipboard Integration**: Automatically process clipboard content
- **Preservation**: Maintain code blocks and existing Google Chat formatting
- **Validation**: Check output for Google Chat compatibility
- **Preview**: Show before/after comparison

## Integration

- Works with any text editor or IDE
- Can be piped with other text processing commands
- Compatible with markdown files, documentation, and plain text
- Integrates with Claude workflows for content creation

## Success Criteria
- All Markdown formatting converted to Google Chat equivalents
- Text structure and readability maintained
- Code blocks and technical content preserved
- Output ready for direct paste into Google Chat

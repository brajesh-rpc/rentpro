# Claude Desktop MCP Filesystem Setup Guide

Complete guide to enable Claude Desktop to read/write local files on Windows using Model Context Protocol (MCP).

## What is MCP?

Model Context Protocol (MCP) allows Claude Desktop to access your local filesystem, enabling it to:
- Read files and directories
- Create and edit files
- Search through project files
- Work directly with your codebase

## Prerequisites

- Claude Desktop installed on Windows
- Node.js installed (for filesystem MCP server)
- Project directory that you want Claude to access

## Step 1: Install MCP Filesystem Server

Open PowerShell/Command Prompt and run:

```bash
npm install -g @modelcontextprotocol/server-filesystem
```

This installs the official MCP filesystem server globally.

## Step 2: Configure Claude Desktop

### Locate Config File

Claude Desktop config file is located at:
```
%APPDATA%\Claude\claude_desktop_config.json
```

Full path example:
```
C:\Users\HP\AppData\Roaming\Claude\claude_desktop_config.json
```

### Edit Configuration

Open `claude_desktop_config.json` in a text editor and add:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": [
        "C:\\Users\\HP\\AppData\\Roaming\\npm\\node_modules\\@modelcontextprotocol\\server-filesystem\\dist\\index.js",
        "C:\\Users\\HP\\Desktop\\100xcrm-local"
      ]
    }
  }
}
```

**Important Notes:**
- Use double backslashes `\\` in Windows paths
- First path in `args`: Location of the MCP server installation
- Second path in `args`: Your project directory that Claude can access
- You can add multiple allowed directories by adding more paths

### Configuration for Multiple Projects

```json
{
  "mcpServers": {
    "filesystem-100xcrm": {
      "command": "node",
      "args": [
        "C:\\Users\\HP\\AppData\\Roaming\\npm\\node_modules\\@modelcontextprotocol\\server-filesystem\\dist\\index.js",
        "C:\\Users\\HP\\Desktop\\100xcrm-local"
      ]
    },
    "filesystem-rentcrm": {
      "command": "node",
      "args": [
        "C:\\Users\\HP\\AppData\\Roaming\\npm\\node_modules\\@modelcontextprotocol\\server-filesystem\\dist\\index.js",
        "C:\\Users\\HP\\Desktop\\rentcrm"
      ]
    }
  }
}
```

## Step 3: Restart Claude Desktop

**CRITICAL:** After editing config, completely restart Claude Desktop:
1. Close all Claude Desktop windows
2. Exit from system tray (if present)
3. Reopen Claude Desktop

## Step 4: Verify Setup

Start a new chat and ask Claude to test filesystem access:

```
Can you list the contents of C:\Users\HP\Desktop\100xcrm-local?
```

If working, Claude will use the `filesystem:list_directory` tool and show you the contents.

## Available MCP Filesystem Tools

Once configured, Claude can use these tools:

### 1. Read Files
Reads complete file contents
Tool: `filesystem:read_text_file`

### 2. Write Files  
Creates new file or overwrites existing
Tool: `filesystem:write_file`

### 3. Edit Files
Find and replace specific text
Tool: `filesystem:edit_file`

### 4. List Directory
Tool: `filesystem:list_directory`

### 5. Search Files
Find files matching pattern
Tool: `filesystem:search_files`

### 6. Create Directory
Tool: `filesystem:create_directory`

### 7. Get File Info
Gets size, timestamps, permissions
Tool: `filesystem:get_file_info`

### 8. Directory Tree
Get recursive JSON tree structure
Tool: `filesystem:directory_tree`

## CRITICAL: Which Tools Claude Should Use

⚠️ **Important:** Claude Desktop has multiple file handling tools available, but NOT all work reliably with MCP filesystem.

### ✅ ALWAYS USE (Reliable with MCP)

These tools work correctly with the MCP filesystem server:

1. **`filesystem:write_file`** - For creating NEW files
   - Use this instead of `create_file`
   - Works reliably for all file types
   - Example: Creating new documentation, config files, source code

2. **`filesystem:edit_file`** - For modifying EXISTING files
   - Find and replace specific text
   - Best for targeted edits
   - Example: Fixing bugs, updating configuration

3. **`filesystem:read_text_file`** - For reading files
   - Always works correctly
   - Supports line ranges for large files

4. **`filesystem:list_directory`** - For browsing directories
   - Shows all files and folders
   - Essential for navigation

5. **`filesystem:search_files`** - For finding files
   - Pattern-based search
   - Works across subdirectories

### ❌ AVOID (May Fail with MCP)

1. **`create_file`** - Internal tool, NOT part of MCP filesystem
   - May silently fail to create files
   - Use `filesystem:write_file` instead
   - Only works in special Claude environments (not standard MCP)

2. **`present_files`** - For user file downloads
   - Works only with `/mnt/user-data/outputs/` directory
   - Not applicable to Windows local filesystem via MCP
   - Files created via MCP are already on your local disk

### Example: Creating a New File

❌ **WRONG (will fail silently):**
```
User: "Create a new README.md file"
Claude: Uses create_file tool
Result: Tool returns success but file doesn't actually exist on disk
```

✅ **CORRECT:**
```
User: "Create a new README.md file"
Claude: Uses filesystem:write_file tool
Result: File is actually created at C:\Users\HP\Desktop\project\README.md
```

### Example: Editing Existing Files

✅ **Best Practice:**
```
User: "Fix the bug in admin.js - change 'superadmin' to 'super_admin'"
Claude: 
  1. Uses filesystem:read_text_file to read current content
  2. Uses filesystem:edit_file with specific oldText/newText
  3. Change is applied correctly
```

### How to Instruct Claude

If Claude is not using the right tools, be explicit:

**Good instructions:**
- "Use filesystem:write_file to create a new config.json"
- "Read the file first, then use filesystem:edit_file to fix the import"
- "List all JavaScript files in the backend folder"

**What NOT to say:**
- "Create an artifact" (artifacts are for web interface, not filesystem)
- "Make it downloadable" (MCP files are already on your disk)
- "Present the file" (not needed for MCP, file is already saved locally)

## Common Issues & Solutions

### Issue 1: "No tools available" or filesystem tools not showing

**Solution:**
- Verify config file path is correct
- Check JSON syntax (use JSONLint.com)
- Ensure double backslashes in Windows paths
- Completely restart Claude Desktop (not just close window)

### Issue 2: "Permission denied" errors

**Solution:**
- Run Claude Desktop as Administrator
- Check folder permissions in Windows
- Ensure the path exists and is accessible

### Issue 3: MCP server not found

**Solution:**
Verify installation path. Run in PowerShell:
```powershell
npm list -g @modelcontextprotocol/server-filesystem
```

This shows the exact installation path. Use that in your config.

### Issue 4: Config changes not taking effect

**Solution:**
- Save the JSON file
- Completely exit Claude Desktop (check Task Manager)
- Wait 5 seconds
- Restart Claude Desktop
- Start a NEW conversation (old conversations don't reload config)

### Issue 5: WSL/Ubuntu path issues

If you installed via WSL, the path might be different:
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "wsl",
      "args": [
        "node",
        "/home/username/.nvm/versions/node/v20.x.x/lib/node_modules/@modelcontextprotocol/server-filesystem/dist/index.js",
        "/mnt/c/Users/HP/Desktop/100xcrm-local"
      ]
    }
  }
}
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **Limited Access:** Claude can ONLY access directories specified in the config
2. **Full Permissions:** Within allowed directories, Claude has full read/write access
3. **No Git Operations:** Claude cannot run git commands directly, only edit files
4. **Code Review:** Always review Claude's file changes before committing to git

## Best Practices

1. **Specific Directories:** Only grant access to specific project directories, not C:\ root
2. **Backup First:** Keep git backups before major file changes
3. **Review Changes:** Use `git diff` to review Claude's edits before committing
4. **New Conversations:** Start fresh conversations for unrelated projects
5. **Clear Instructions:** Be specific about which files to edit

## Testing Your Setup

Run these test commands in a new Claude conversation:

```
1. List files: "Show me all files in the project root"
2. Read file: "Read the package.json file"
3. Write test: "Create a file called test.txt with the content 'Hello'"
4. Edit test: "Change 'Hello' to 'Hi' in test.txt"
5. Search: "Find all JavaScript files in the backend folder"
```

If all work, your setup is complete! ✅

## Troubleshooting Checklist

- [ ] Node.js installed and accessible via `node` command
- [ ] MCP filesystem package installed globally via npm
- [ ] Config file path correct: `%APPDATA%\Claude\claude_desktop_config.json`
- [ ] JSON syntax valid (no trailing commas, proper quotes)
- [ ] Windows paths use double backslashes `\\`
- [ ] Project directory path exists and is accessible
- [ ] Claude Desktop fully restarted (not just window closed)
- [ ] Testing in a NEW conversation after restart

---

## Quick Reference Card

### Config Location
```
%APPDATA%\Claude\claude_desktop_config.json
```

### Minimal Working Config
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": [
        "C:\\Users\\HP\\AppData\\Roaming\\npm\\node_modules\\@modelcontextprotocol\\server-filesystem\\dist\\index.js",
        "C:\\Users\\HP\\Desktop\\YOUR_PROJECT_FOLDER"
      ]
    }
  }
}
```

### After Config Changes
1. Save file
2. Exit Claude Desktop completely
3. Restart Claude Desktop
4. Start NEW conversation
5. Test: "List files in the project"

---

**Document Version:** 1.0  
**Last Updated:** 2025-02-08  
**Tested On:** Windows 11, Claude Desktop, Node.js v20

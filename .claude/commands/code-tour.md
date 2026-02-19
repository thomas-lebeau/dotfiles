---
name: code-tour
description: >
  Use when user says "code tour", "give me a tour", "walk me through", "show me how X works",
  "explain the codebase", "guided tour", "teach me about", or asks to understand a service's
  architecture or code structure. Interactive educational tour using tmux side pane with vim.
allowed-tools: Bash, Read, Grep, Glob, Task, mcp__atlassian__search, mcp__atlassian__getConfluencePage
---

# Interactive Code Tour

Give an interactive educational tour explaining code by displaying it in a tmux side pane with vim while walking through explanations.

## Arguments

`$ARGUMENTS` - The topic, service, or code area to tour (e.g., "apm-services-api", "authentication flow", "src/handlers")

## Setup Phase

1. **Verify tmux session**:
   ```bash
   echo "TMUX=$TMUX"
   ```
   If not in tmux, inform the user they need to run from a tmux session.

2. **Capture the window ID of the pane running Claude Code** (CRITICAL for targeting commands correctly):
   ```bash
   tmux display-message -p -t $TMUX_PANE '#{window_id}'
   ```
   The `-t $TMUX_PANE` flag is essential: `$TMUX_PANE` is an env var (e.g., `%5`) that tmux sets in every pane's shell, identifying that specific pane. Without it, `display-message` returns the **currently active** window, which may be a different window if the user has switched focus. With `-t $TMUX_PANE`, it always resolves to the window containing Claude Code's pane.

   Store this window ID (e.g., `@0`, `@1`, etc.) - you will use it for ALL subsequent tmux commands to ensure they target the correct window even if the user switches windows.

3. **Find code context** (for Datadog services):
   - Query Atlassian with `mcp__atlassian__search` for documentation about $ARGUMENTS
   - Fetch relevant Confluence pages for architecture context
   - Code locations: `~/dd/` (various repos) or `~/go/src/github.com/DataDog/dd-source` (monorepo)

4. **Create pane below and open vim** (two-step approach for reliability):
   First, split directly off of Claude Code's pane (using `$TMUX_PANE` ensures the split happens in the correct window even if the user has switched focus):
   ```bash
   tmux split-window -v -t $TMUX_PANE && sleep 0.5
   ```
   Then identify the new pane:
   ```bash
   tmux list-panes -t {window_id} -F '#{pane_index} #{pane_current_command}'
   ```
   Store the pane index (typically 1). The full target for commands will be `{window_id}.{pane_index}` (e.g., `@0.1`).

   Then cd and open vim via send-keys:
   ```bash
   tmux send-keys -t {window_id}.{pane_index} 'cd <working_directory> && vim <initial_file>' Enter
   ```

   **Why two steps?** Passing a command directly to `split-window` (e.g., `tmux split-window -v "vim file"`) causes the pane to close immediately if the command fails or the path to the editor is wrong. Opening a shell first, then launching vim via `send-keys`, is more reliable.

## Navigation Pattern

**CRITICAL**: Use sub-agents (Task tool with subagent_type=Bash) for ALL vim interactions to avoid polluting conversation context.

**CRITICAL**: Always use the full target `{window_id}.{pane_index}` (e.g., `@0.2`) for ALL tmux commands. This ensures commands go to the correct pane even if the user has switched to a different tmux window.

**CRITICAL - Line Numbers**: When explaining code to the user, always reference the **actual file line numbers** (shown in vim's left gutter or status line), NOT the position within the tmux capture output. The user sees vim with line numbers - your references must match what they see. Look at vim's status line which shows the current line number (e.g., "321,1" means line 321, column 1).

Example sub-agent prompt:
```
Navigate vim in tmux target {window_id}.{pane_index} to show {description} at line {line_number}.

Steps:
1. Send keys: tmux send-keys -t {window_id}.{pane_index} ':{line_number}' Enter 'zz'
2. Verify: tmux capture-pane -t {window_id}.{pane_index} -p | head -40
3. Note the actual file line numbers from vim's status line or gutter

Return brief confirmation of what's now visible, referencing ACTUAL file line numbers.
```

## Pacing Rules

**CRITICAL**: This is an INTERACTIVE tour. You MUST:

1. After explaining what's on screen, ALWAYS ask for confirmation before navigating elsewhere:
   - "Ready to see [next concept]?"
   - "Let me know when you're ready to continue"
   - "Any questions before we move on?"

2. NEVER blast through multiple locations without user confirmation between each.

3. Give the user time to read and absorb the code in the side pane.

## Reading User Selections

Users can highlight code in vim and ask questions about it.

**User workflow**: Select text in visual mode → Press `Escape` → Ask question

**To read the selection** (run directly, not in sub-agent):
```bash
tmux send-keys -t {window_id}.{pane_index} ":'<,'>w! /tmp/vim_sel.txt" Enter
sleep 0.3
cat /tmp/vim_sel.txt
```

This writes the visually selected lines to a temp file using vim's `'<,'>` range marks (set when exiting visual mode).

**When user asks about a selection**:
1. Read the selection using the command above
2. Use a sub-agent (Task with subagent_type=Explore) to research what the selected code does
3. Provide a concise explanation

## Tour Structure

1. **Overview**: Start with high-level context from documentation
2. **Entry point**: Show main() or equivalent, explain the starting point
3. **Dependencies**: Walk through initialization and dependency injection
4. **Core logic**: Show key handlers, routes, or business logic
5. **Integration points**: Show connections to other services
6. **Q&A**: Let user highlight and ask about specific code

## Example Flow

```
[You] "Let me give you a tour of {service}. First, let me find the documentation..."
[Query Atlassian, setup tmux pane]

[You] "This service does X. Looking at the entry point now..."
[Sub-agent navigates to main()]

[You] "Here's main() - it creates the API server with these options: ...
       Ready to see how dependencies are wired up?"

[Wait for user: "yes"]

[Sub-agent navigates to next location]
[Explain, then ask for confirmation again]

[User highlights something, asks "what does this do?"]
[Read selection, research with sub-agent, explain]
```

## Cleanup

When tour is complete, optionally close the pane:
```bash
tmux send-keys -t {window_id}.{pane_index} ':q!' Enter
```
Or leave it open for the user to continue exploring.

## PR Comment Mode

When the user asks to post a code tour as a comment on a PR (e.g., "post this tour as a PR comment", "write a code tour comment on PR #123"), generate a single PR comment containing the full tour.

### Gathering context

1. Fetch the PR metadata and diff:
   ```bash
   gh pr view {PR_NUMBER} --json title,body,files,commits
   gh pr diff {PR_NUMBER}
   ```
2. Read the changed files to understand the code in full context (not just the diff hunks).

### Building diff links

GitHub diff links use SHA-256 hashes of file paths as anchors. Compute them with:

```bash
python3 -c "
import hashlib
files = ['path/to/file.go', ...]
for f in files:
    h = hashlib.sha256(f.encode()).hexdigest()
    print(f'{f} -> {h}')
"
```

Link format: `https://github.com/{owner}/{repo}/pull/{number}/files#diff-{sha256_hash}R{line_number}`
- `R{line}` for right side (new code), `L{line}` for left side (old code)
- For line ranges: `R{start}-R{end}`

**IMPORTANT**: Use HTML `<a>` tags with `target="_blank"` so links open in a new tab:
```html
<a href="https://github.com/.../pull/123/files#diff-{hash}R{line}" target="_blank"><code>file.go</code> — description</a>
```

### Comment structure

Use collapsible `<details>` sections for each "stop" on the tour:

```markdown
## Code Tour

A guided walkthrough of the changes in this PR. Each stop covers one logical area — expand to read.

---

<details>
<summary><strong>Stop 1: Title</strong> — brief subtitle</summary>

📍 <a href="https://github.com/.../pull/123/files#diff-{hash}R{line}-R{line}" target="_blank"><code>file.go</code> — description</a>

Explanation with inline code snippets:

\`\`\`go
// relevant code excerpt
\`\`\`

</details>

<details>
<summary><strong>Stop 2: Title</strong> — brief subtitle</summary>
...
</details>

---

### Data flow summary

\`\`\`
component A → component B → component C
\`\`\`
```

### Guidelines

- Each stop should cover one logical area of the change (a new type, a caller, an integration point, etc.)
- Include inline code snippets showing the key lines — don't make the reader expand every diff
- Link to specific diff regions so readers can click through to full context
- End with a data flow summary showing how the pieces connect
- Write the comment to a temp file and post with `gh pr comment {number} --body-file /tmp/file.md`

### When to use this mode

- User explicitly asks to post the tour as a PR comment
- User provides a PR URL and asks for a written tour (without being in tmux, or asking for a comment)
- After an interactive tour, user asks to capture it as a PR comment

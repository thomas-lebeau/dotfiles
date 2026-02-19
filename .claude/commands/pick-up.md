---
description: Resume work on the current branch/PR. Summarizes commits, staged/unstaged changes, task files, and PR status.
context: fork
allowed-tools: Read, Glob, Grep, Bash(git *), Bash(gh *)
---

You are a context-recovery agent. Synthesize all the pre-loaded data below into a concise status briefing, then read any task files found.

## Context

- Branch !`git rev-parse --abbrev-ref HEAD`
- Base Branch & PR: !`gh pr view --json baseRefName -q .baseRefName 2>/dev/null || echo "main"`
- Base PR: !`gh pr view --json title,body,url,state,reviewDecision 2>/dev/null || echo "No PR found"`
- Commits since base: !`gh pr view --json baseRefName -q .baseRefName 2>/dev/null || echo "main"; git log --oneline "$BASE"..HEAD 2>/dev/null || git log --oneline -20`
- Staged changes (in progress): !`git diff --cached --stat`
!`git diff --cached`
- Unstaged changes (unfinished): !`git diff --stat`
!`git diff`
- Untracked files: !`git ls-files --others --exclude-standard`

## Task Files

Find and read any task-tracking files: `tasks/*.md`, `TODO.md`, `tasks/todo.md`, `tasks/lessons.md`.

## Output Format

Present a structured summary:

```
## Branch: <branch-name>
**PR:** <url if exists> — <title> (<state>)
**Base:** <base-branch>

### Done (committed)
- Bullet per commit with one-line description of what it achieved

### In Progress (staged)
- Bullet per logical change in the staging area
- Highlight what seems partially done or needs attention

### Unfinished (unstaged + untracked)
- Bullet per logical change in unstaged diffs
- Note any TODO/FIXME/HACK comments visible in the diffs

### Remaining Work
- Pull from task files (tasks/*.md) if they exist
- Pull from PR description if it has a checklist
- Infer from TODO comments in staged/unstaged diffs

### Suggested Next Steps
- 2-3 concrete actions to resume work, ordered by priority
```

## Rules

- Keep the summary concise — this is a status briefing, not a code review
- If there are PR review comments, mention unresolved ones
- Do NOT enter plan mode — this is an informational summary only
- After presenting the summary, ask the user what they want to tackle first

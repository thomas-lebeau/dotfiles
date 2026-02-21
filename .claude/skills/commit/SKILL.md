---
name: commit
description: Create a git commit from current changes using conventional commit format and selective staging
argument-hint: [type] [scope] [description]
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*)
disable-model-invocation: true
context: fork
---

## Context

- Git status: !`git status`
- Staged and unstaged changes: !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits (style reference): !`git log --oneline -10`
- format code: !`yarn format --write`

## Arguments

<$ARGUMENTS>

If arguments are provided, use them as commit type, scope, and/or description.

## Your Task

Create a well-structured git commit from the current changes.

### 1. Verify Changes Exist

If there are no staged or unstaged changes, report "Nothing to commit" and stop.

### 2. Verify Branch

If the current branch is `main` or `master`, create a new branch.

### 3. Analyze Changes

- Review the diff to understand what changed and why
- If changes span unrelated concerns, stage only files for one logical change and inform the user that remaining changes can be committed separately

### 4. Stage Files Selectively

```bash
git add <specific-files> \
  <another-file> \
  # Add only files relevant to the logical change being committed
```

Do NOT use `git add -A` or `git add .`.

### 5. Generate Commit Message

Use conventional commit format:

```
<type>(<scope>): <brief description>

- What changed and why
```

**Types:** feat, fix, refactor, docs, test, chore, style, perf

### 6. Commit

```bash
git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```

### 7. Verify

```bash
git log -1 --stat && git status
```

## Error Handling

If any git command fails, **STOP immediately**. Report the error — do not attempt recovery.

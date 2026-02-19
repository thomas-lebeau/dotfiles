---
name: pr
description: Create a draft pull request for the current branch, pushing if needed
argument-hint: [base-branch] [title]
allowed-tools: Bash(git push:*), Bash(git log:*), Bash(git diff:*), Bash(git status:*), Bash(git branch:*), Bash(gh pr view:*), Bash(gh repo view:*)
context: fork
---

## Context

- Current branch: !`git branch --show-current`
- Repository: !`gh repo view --json nameWithOwner,defaultBranchRef --jq '{repo: .nameWithOwner, defaultBranch: .defaultBranchRef.name}' 2>/dev/null || echo "Unknown"`
- Git status: !`git status --short`
- Recent commits: !`git log --oneline -15`

## Arguments

$ARGUMENTS

If a base branch is provided, use it. Otherwise, target the repository's default branch.

## Your Task

Push the current branch (if needed) and create a draft pull request.

### 1. Pre-flight Checks

- Verify the current branch is not `main`/`master`. If it is, stop and warn.
- Check if a PR already exists: `gh pr view --json url,state 2>/dev/null`. If yes, report its URL and stop.
- Warn about uncommitted changes (they won't be in the PR).

### 2. Push the Branch

```bash
git push -u origin HEAD
```

### 3. Build the PR Description

- Check if `@.github/PULL_REQUEST_TEMPLATE.md` exists. Use it if available, otherwise use Summary + Test Plan sections.
- Summarize changes from commits and diff.
- Use mermaid diagrams only for architectural changes (new service interactions, data flows, state machines).

### 4. Create the Draft PR

```bash
gh pr create --draft --title "<title>" --body "$(cat <<'EOF'
<PR body>
EOF
)"
```

### 5. Report

Display the PR URL and remind it was created as a draft.

## Error Handling

If any command fails, **STOP immediately**. Report the error.

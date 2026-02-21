---
name: code-simplifier
description: Simplify, refactor, and clean up the current PR for readability and maintainability
disable-model-invocation: true
agent: code-simplifier:code-simplifier
context: fork
---

## Context

- Current branch: !`git branch --show-current`
- Changed files: !`git diff --name-only main...HEAD`
- Diff summary: !`git diff main...HEAD --stat`

## Your task

Analyze and simplify the code changes in the current PR.

**Scope:** Only review files changed in this PR (listed above). Do not touch unrelated code.

**Process:**
1. Review the diff to understand what changed and why
2. Identify simplification opportunities (unnecessary complexity, redundant code, unclear naming, deep nesting)
3. Apply simplifications while preserving all existing functionality
4. Summarize what you changed and why

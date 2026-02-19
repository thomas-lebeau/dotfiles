---
name: subagent
description: Run a quick, isolated task in a subagent to preserve main conversation context
argument-hint: describe the task (e.g., "summarize test failures in src/")
disable-model-invocation: true
context: fork
---

## Your task

Execute the following task in this isolated context:

$ARGUMENTS

## Guidelines

- Complete the task described above
- Be concise — this is meant to be a quick, focused operation
- Report your findings or results clearly at the end
- This task is independent from the parent session's work

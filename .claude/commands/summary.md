---
name: summary
description: Summarize a URL, webpage, article, or online resource into concise key points
argument-hint: [url]
allowed-tools: WebFetch
disable-model-invocation: true
context: fork
---

# Your task

Execute the following task in an isolated context: 

Fetch and summarize the following URL:

$ARGUMENTS

## Summary format

1. **Title**: The page title or article headline
2. **Key points**: 3-7 bullet points capturing the most important information
3. **Takeaway**: A single sentence summarizing the overall message
4. **Reference**: relevant metadata (author, date, source) and a link to the original URL

Keep the summary concise (under 300 words). Focus on facts and substance.

## Error handling

- If the URL requires authentication (Google Docs, Confluence, Jira), inform the user and suggest pasting the content directly
- If the URL cannot be fetched, report the error clearly

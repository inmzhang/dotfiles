---
name: github-search
description: "CRITICAL: Use for searching GitHub repositories for skills. Triggers on: search for skills, find skill repositories, cowork search, search GitHub topics, discover skills on GitHub, find repos on GitHub, browse skill repos, 搜索 skill, 查找技能仓库, 搜索仓库, 找技能"
---

# GitHub Repository Search

> Search GitHub for skill-related repositories and discover new skills to install.

---

## When to Use

Use this skill when the user wants to:
- Find repositories related to a topic
- Discover `agent-skill` tagged repositories
- Search for libraries to convert to skills
- Find popular repositories in a domain

---

## Workflow

### 1. Search for Repositories

```bash
# Search by keyword
cowork search tokio

# Search by topic
cowork search agent-skill --topic

# Verbose output with details
cowork search rust-skills --verbose

# Limit results
cowork search async --limit 5
```

### 2. Review Results

The search returns:
- Repository name and owner
- Star count
- Description
- Language and topics (with --verbose)

### 3. Generate or Install

After finding a repository:
```bash
# Generate skills from it
cowork generate owner/repo

# Or install existing skills
cowork install owner/repo
```

---

## Example Interactions

### User: "Find some Rust async skills"

Response:
```
Let me search for Rust async-related repositories.
```

```bash
cowork search "rust async" --verbose
```

### User: "搜索有 agent-skill 标签的仓库"

Response:
```
I'll search for repositories with the agent-skill topic.
```

```bash
cowork search agent-skill --topic --verbose
```

---

## Command Reference

| Option | Description |
|--------|-------------|
| `--topic` | Search by GitHub topic instead of keyword |
| `--verbose, -v` | Show detailed information |
| `--limit, -n <N>` | Maximum results (default: 10) |

---

## Search Tips

### Finding Agent Skills

```bash
# Repositories tagged with agent-skill
cowork search agent-skill --topic

# Claude Code specific skills
cowork search claude-code-skill --topic
```

### Finding Libraries

```bash
# Popular Rust crates
cowork search "rust library" --limit 20

# TypeScript utilities
cowork search "typescript utility"
```

### Finding by Domain

```bash
# Web frameworks
cowork search "web framework rust"

# Data processing
cowork search "data pipeline python"
```

---

## Requirements

- `GITHUB_TOKEN` environment variable must be set
- Works with public repositories
- Private repos require appropriate token permissions

---

## Recommended Workflow

```
1. cowork search <topic>              # Find repositories
2. cowork generate <repo>             # Generate skills from it
3. cowork install --list              # Verify installation
```

---

## Related Skills

| When | See |
|------|-----|
| Generate skills from repo | github-generate |
| Install skills | `cowork install` |
| List installed skills | `cowork list` |

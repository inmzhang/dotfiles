---
name: github-generate
description: "CRITICAL: Use for generating skills from GitHub repositories. Triggers on: generate skill from repo, create skills from GitHub, cowork generate, generate llms.txt, convert repo to skills, make skills from repository, parse repository, GitHub 转 skill, 从仓库生成 skill, 生成技能, extract API from code"
---

# GitHub Repository to Skills Generator

> Generate Claude Code skills from any GitHub repository by extracting public APIs and documentation.

---

## When to Use

Use this skill when the user wants to:
- Convert a GitHub repository into skills
- Generate llms.txt documentation from source code
- Create skills from a library or framework
- Parse Rust/TypeScript/Python source code to extract APIs

---

## Workflow

### 1. Identify the Repository

Extract the GitHub repository from the user's request:
- Full URL: `https://github.com/tokio-rs/tokio`
- Short form: `tokio-rs/tokio`
- Just name: Search first with `cowork search tokio`

### 2. Generate Skills

Execute the cowork generate command:

```bash
# Basic generation
cowork generate user/repo

# Specify language(s)
cowork generate user/repo --lang rust

# Only generate llms.txt (for review)
cowork generate user/repo --llms-only -o ./output

# From specific branch/tag
cowork generate user/repo --ref v1.0.0

# Install to specific agents
cowork generate user/repo -a claude-code -a cursor
```

### 3. Review Output

The command generates:
- `llms.txt` - Comprehensive API documentation
- `skills/` directory - One SKILL.md per module

---

## Example Interactions

### User: "帮我把 tokio 转成 skill"

Response:
```
Let me generate skills from the tokio repository.

First, I'll run the generation command:
```

```bash
cowork generate tokio-rs/tokio --lang rust
```

### User: "Create a skill from this repo: https://github.com/vercel/next.js"

Response:
```
I'll generate skills from the Next.js repository.
```

```bash
cowork generate vercel/next.js --lang typescript
```

---

## Command Reference

| Option | Description |
|--------|-------------|
| `--lang <LANG>` | Languages to parse (rust, typescript, python) |
| `--llms-only` | Only generate llms.txt |
| `-o, --output <PATH>` | Output directory |
| `--ref <REF>` | Git ref (branch, tag, commit) |
| `-a, --agent <AGENT>` | Install to agent(s) |
| `--split-modules` | Split into per-module skills (default: true) |

---

## Requirements

- `GITHUB_TOKEN` environment variable must be set
- Token needs `repo` scope for private repositories

---

## Supported Languages

| Language | Parser | Extracts |
|----------|--------|----------|
| Rust | `syn` | pub fn, struct, enum, trait, impl |
| TypeScript | `tree-sitter` | export function, class, interface, type |
| Python | `tree-sitter` | def, class (excluding `_` private) |

---

## Related Skills

| When | See |
|------|-----|
| Search for repositories | github-search |
| Install existing skills | `cowork install` |
| Manage local skills | `cowork list`, `cowork sync` |

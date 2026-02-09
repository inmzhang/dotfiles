---
name: cowork-router
description: "Meta-router for dynamic skill routing. Use when: cowork, skill management, router generation, Skills.toml, plugin configuration"
---

# CoWork Router

> Meta-router that guides dynamic generation of project-specific skill routers

## Purpose

This is a **meta-skill** that:
1. Explains how the cowork dynamic routing system works
2. Guides AI to generate project-specific routers via `cowork config router`
3. Provides the routing architecture pattern for all skill plugins

**This skill does NOT hardcode specific plugins** - it describes the system for dynamically discovering and routing to installed plugins.

## Dynamic Router Generation

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Skills.toml (User Config)                        │
│  [skills.install]                                                        │
│  rust-skills = "user/rust-skills"                                        │
│  dora-skills = { path = "/local/dora-skills", plugin = true }           │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │ cowork config install │
                        └───────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         Skills.lock (Generated)                          │
│  - Tracks installed plugins, versions, paths                            │
│  - Records extracted trigger keywords                                    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │ cowork config router  │
                        └───────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              .claude/skills/cowork-router/SKILL.md (Dynamic)            │
│  - Auto-generated from installed plugins                                 │
│  - Merged trigger keywords from all plugins                              │
│  - Domain detection table based on actual installations                  │
└─────────────────────────────────────────────────────────────────────────┘
```

## How It Works

### 1. Plugin Discovery

Each plugin contains skills with `SKILL.md` files. The frontmatter `description` field contains trigger keywords:

```yaml
---
name: rust-router
description: "Triggers on: E0xxx, ownership, borrow, lifetime, async, trait"
---
```

### 2. Keyword Extraction

`cowork config router` scans all installed plugins and extracts:
- Trigger keywords from each skill's description
- Router skill names (e.g., `rust-router`, `dora-router`)
- Skill counts per plugin

### 3. Unified Router Generation

Generates a project-specific `cowork-router` that:
- Combines all trigger keywords into one description
- Creates a domain detection table
- Maps keywords → plugin routers

## CLI Commands

```bash
# Initialize project configuration
cowork config init

# Add plugin dependencies
cowork config add rust-skills ZhangHanDong/rust-skills --plugin
cowork config add dora-dev /path/to/dora-skills --dev --plugin

# Install all dependencies
cowork config install

# Generate dynamic router from installed plugins
cowork config router

# Generate router with auto-trigger hooks
cowork config router --hooks
```

## Generated Router Structure

The dynamically generated router will contain:

```markdown
---
name: cowork-router
description: "Triggers on: [merged keywords from all plugins]"
---

## Domain Detection

| Domain | Keywords | Route To |
|--------|----------|----------|
| [plugin-1] | [extracted keywords] | [plugin-1-router] |
| [plugin-2] | [extracted keywords] | [plugin-2-router] |
| ... | ... | ... |
```

## Routing Architecture Pattern

All plugin routers should follow this pattern:

```
                    ┌─────────────────────────────────────┐
                    │         cowork-router (Meta)         │
                    │   Unified entry - Domain detection   │
                    └───────────────┬─────────────────────┘
                                    │
           ┌────────────────────────┼────────────────────────┐
           ▼                        ▼                        ▼
   ┌───────────────┐        ┌───────────────┐        ┌───────────────┐
   │ plugin-router │        │ plugin-router │        │ plugin-router │
   │   (Domain A)  │        │   (Domain B)  │        │   (Domain C)  │
   └───────┬───────┘        └───────┬───────┘        └───────┬───────┘
           │                        │                        │
           ▼                        ▼                        ▼
    plugin-skills            plugin-skills            plugin-skills
```

## Cross-Domain Routing

When a question spans multiple domains:

1. **Detect all matching domains** from keywords
2. **Load primary domain router** (most specific match)
3. **Cross-reference other domains** as needed
4. **Combine context** for comprehensive answer

Example: "Dora node 中 E0382 错误"
- Primary: `dora-router` (dataflow context)
- Cross-ref: `rust-skills:m01-ownership` (ownership mechanics)

## Configuration Files

| File | Location | Purpose |
|------|----------|---------|
| `Skills.toml` | `.cowork/Skills.toml` | User configuration |
| `Skills.lock` | `.cowork/Skills.lock` | Installed state (auto-generated) |
| `cowork-router` | `.claude/skills/cowork-router/` | Dynamic router (auto-generated) |
| `hooks.json` | `.claude/skills/cowork-router/` | Auto-trigger hooks (optional) |

## When to Regenerate Router

Run `cowork config router` after:
- Adding new plugin dependencies
- Removing plugins
- Updating plugin versions
- Modifying trigger priority in Skills.toml

## Trigger Priority Configuration

In `Skills.toml`:

```toml
[triggers]
priority = ["dora-router", "rust-router", "makepad-router"]

[triggers.overrides]
"async" = "rust-router"
"widget" = "makepad-router"
```

Higher priority routers win when keywords conflict.

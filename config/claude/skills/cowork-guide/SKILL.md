---
name: cowork-guide
description: "CRITICAL: Comprehensive guide for CoWork Skills CLI tool. Triggers on: cowork, Skills.toml, skill management, plugin configuration, cowork init, cowork install, cowork config, cowork generate, cowork audit, cowork verify, cowork test"
---

# CoWork Guide

> Complete reference for the CoWork Skills CLI tool

## Overview

**CoWork Skills** (`cowork` / `co`) is a CLI tool for managing Claude Code skills and plugins across 16+ AI coding agents:
- Install skills from GitHub repositories
- Generate skills from source code (Rust, TypeScript, Python)
- Manage project-level skill configuration via Skills.toml
- Security auditing and checksum verification
- Search GitHub for skill repositories

## Installation

**First, check if cowork is installed:**
```bash
cowork --version
```

**If not installed, install via one of these methods:**

```bash
# Option 1: From crates.io (recommended)
cargo install cowork

# Option 2: From source
git clone https://github.com/ZhangHanDong/cowork-skills
cd cowork-skills/cli
cargo install --path .
```

**Then initialize built-in skills:**
```bash
cowork init
```

> **Note:** If you installed cowork-skills via `npx @anthropic-ai/claude-code add`,
> you still need to install the `cowork` CLI separately using the commands above.

## Command Alias

```bash
cowork = co   # 简写别名
```

## Commands by Category

### 🚀 Quick Start (初始化)

| Command | Description |
|---------|-------------|
| `co init` | 安装内置 skills 到全局/项目 |
| `co init --list` | 列出可用的内置 skills |
| `co init --local` | 安装到项目 `.claude/skills/` |
| `co init -r <name>` | 删除指定 skill |

### 📦 Install & Uninstall (安装)

| Command | Description |
|---------|-------------|
| `co install user/repo` | 从 GitHub 安装 |
| `co install user/repo -s skill1` | 安装指定 skills |
| `co install user/repo --plugin` | 作为插件安装 |
| `co install user/repo -l` | 安装到项目本地 |
| `co install user/repo --update` | 更新到最新版本 |
| `co install --list` | 列出已安装仓库 |
| `co install --uninstall repo` | 卸载仓库 |

### ⚙️ Configuration (配置)

| Command | Description |
|---------|-------------|
| `co config init` | 创建 Skills.toml |
| `co config show` | 显示当前配置 |
| `co config add name repo` | 添加依赖 |
| `co config add name path --dev` | 添加开发链接 |
| `co config install` | 安装 Skills.toml 中的依赖 |
| `co config sync` | 同步锁文件状态 |
| `co config enable/disable` | 启用/禁用 skills |
| `co config priority` | 设置触发优先级 |
| `co config router` | 生成动态路由 |
| `co config router --analyze` | AI 分析生成智能路由 |

### 🔍 Discovery (发现)

| Command | Description |
|---------|-------------|
| `co list` | 列出所有可用 skills |
| `co search query` | 搜索 GitHub 仓库 |
| `co search topic --topic` | 按 topic 搜索 |
| `co generate user/repo` | 从源码生成 skills |

### 🔌 Plugin Management (插件)

| Command | Description |
|---------|-------------|
| `co plugins list` | 列出已安装插件 |
| `co plugins status` | 插件系统状态 |
| `co plugins enable/disable` | 启用/禁用插件 |
| `co plugins uninstall` | 卸载插件 |

### 🛡️ Security & Testing (安全)

| Command | Description |
|---------|-------------|
| `co audit` | 安全审计 |
| `co verify` | 校验 checksums |
| `co test` | 生成触发测试 |
| `co test --run` | 运行实际测试 |
| `co test --check-conflicts` | 检查触发冲突 |

### 📊 Status & Debug (状态)

| Command | Description |
|---------|-------------|
| `co status` | 显示当前状态 |
| `co doctor` | 检查配置问题 |

## Workflow 工作流

```
┌─────────────────────────────────────────────────────────────────┐
│                        CoWork 工作流                              │
└─────────────────────────────────────────────────────────────────┘

1. 初始化
   co init                          # 安装内置 skills

2. 安装外部 skills
   co install user/repo             # 从 GitHub 安装
   co install user/repo --plugin    # 作为插件安装

3. 项目配置 (可选)
   co config init                   # 创建 Skills.toml
   co config add rust ZhangHanDong/rust-skills
   co config install                # 安装依赖

4. 生成路由
   co config router --analyze       # AI 分析生成智能路由

5. 测试 & 验证
   co test --check-conflicts        # 检查触发冲突
   co audit                         # 安全审计

6. 日常使用
   co list                          # 查看所有 skills
   co status                        # 查看状态
   co doctor                        # 诊断问题
```

---

## cowork init

Initialize built-in skills to ~/.claude/skills/.

```bash
# Install all built-in skills
cowork init

# List available built-in skills
cowork init --list

# Install specific skills only
cowork init -s memory-skills -s cowork-guide

# Force overwrite existing
cowork init --force

# Install to project local (.claude/skills/)
cowork init --local

# Remove specific skills
cowork init --remove memory-skills
```

**Built-in Skills:**
- `memory-skills` - CoALA-based memory system (remember, recall, reflect)
- `cowork-guide` - Complete CoWork CLI usage guide
- `cowork-router` - Unified router for installed plugins/skills
- `code-review` - Code review assistant with best practices
- `github-generate` - Generate skills from GitHub repositories
- `github-search` - Search GitHub for skill repositories

---

## cowork install

Install skills from GitHub or local repositories.

### Basic Usage

```bash
# Install from GitHub (user/repo format)
cowork install ZhangHanDong/rust-skills

# Install from full URL
cowork install https://github.com/user/repo

# Install current project to global
cowork install

# List installed repositories
cowork install --list
```

### Installation Options

```bash
# Install specific skills only
cowork install user/repo -s skill1 -s skill2

# Install to specific agents
cowork install user/repo -a claude-code -a cursor

# Install as plugin (preserves full repo structure)
cowork install user/repo --plugin

# Install to project local (.claude/skills/)
cowork install user/repo --local

# Force reinstall
cowork install user/repo --reinstall

# Update to latest version
cowork install user/repo --update

# Include additional directories
cowork install user/repo --include-dir docs --include-dir examples

# Copy files instead of symlinks
cowork install user/repo --no-symlink

# Use npx add-skill backend
cowork install user/repo --use-add-skill

# Skip confirmation prompts
cowork install user/repo -y
```

### Uninstall

```bash
cowork install --uninstall repo-name
```

### Supported Agents

Install skills to 16+ coding agents:

| Agent | Flag | Agent | Flag |
|-------|------|-------|------|
| Claude Code | `-a claude-code` | Amp | `-a amp` |
| Cursor | `-a cursor` | Antigravity | `-a antigravity` |
| Codex | `-a codex` | Clawdbot | `-a clawdbot` |
| GitHub Copilot | `-a github-copilot` | Droid | `-a droid` |
| Windsurf | `-a windsurf` | Gemini CLI | `-a gemini-cli` |
| Goose | `-a goose` | Kilo | `-a kilo` |
| Kiro CLI | `-a kiro-cli` | OpenCode | `-a opencode` |
| Roo | `-a roo` | Trae | `-a trae` |

---

## cowork config

Manage project-level skill configuration via Skills.toml.

### Initialize Configuration

```bash
# Initialize with auto-detection of installed plugins/skills
cowork config init

# Skip auto-detection
cowork config init --no-detect

# Force overwrite existing
cowork config init --force
```

Auto-detection scans:
- `~/.claude/` for global plugins
- `~/.claude/skills/` for global skills
- `.claude/` for project plugins
- `.claude/skills/` for project skills

### View Configuration

```bash
# Show current config
cowork config show

# List available skill groups
cowork config groups
```

### Add Dependencies

```bash
# Add from GitHub (global)
cowork config add rust-skills ZhangHanDong/rust-skills

# Add to project local
cowork config add my-skills user/skills --local

# Add specific skills
cowork config add tokio user/tokio-skills -s tokio-runtime -s tokio-sync

# Add as plugin
cowork config add makepad user/makepad-skills --plugin

# Add as disabled
cowork config add old-lib user/old --disabled

# Add with git ref
cowork config add pinned user/repo --ref v1.0.0

# Add development link (symlink for testing)
cowork config add dora-dev /path/to/dora-skills --dev
```

### Install Dependencies

```bash
# Install all dependencies from Skills.toml
cowork config install
```

### Sync Configuration

```bash
# Sync enabled/disabled status with lock file
cowork config sync

# Also update remote repos (git pull)
cowork config sync --update
```

### Enable/Disable

```bash
# Enable skill groups
cowork config enable rust-core makepad

# Enable individual skills
cowork config enable memory-filesystem

# Disable skills or groups
cowork config disable rust-domains
```

### Trigger Configuration

```bash
# Set priority order
cowork config priority dora-router rust-router makepad-router

# Override specific trigger
cowork config override "async" rust-router
cowork config override "widget" makepad-router
```

### Generate Output

```bash
# Generate SKILLS.md from config
cowork config apply

# Generate to custom path
cowork config apply -o ./docs/SKILLS.md

# Generate dynamic router based on installed plugins
cowork config router

# Generate router with hooks for auto-triggering
cowork config router --hooks

# Analyze trigger conflicts
cowork config router --analyze

# Skip cache
cowork config router --no-cache
```

---

## Skills.toml

Project-level configuration file stored at `.cowork/Skills.toml`.

### Basic Structure

```toml
[project]
name = "my-project"
description = "Project description"

[skills.global]
enabled = ["memory-filesystem"]
disabled = []

[skills.install]
rust-skills = "ZhangHanDong/rust-skills"

[skills.groups]
enabled = ["rust-core"]
disabled = []

[triggers]
priority = ["dora-router", "rust-router"]

[triggers.overrides]
"async" = "rust-router"
```

### Dependency Forms

**Simple form:**
```toml
[skills.install]
rust-skills = "ZhangHanDong/rust-skills"
```

**Detailed form:**
```toml
[skills.install]
tokio = { repo = "user/tokio-skills", skills = ["tokio-runtime", "tokio-sync"] }
local = { path = "../my-local-skills" }
pinned = { repo = "user/repo", ref = "v1.0.0" }
makepad = { repo = "user/makepad-skills", plugin = true }
my-project = { repo = "user/skills", local = true }
old-lib = { repo = "user/old", enabled = false }
```

### Dev Links

Development symlinks for testing local skills:

```toml
[skills.dev]
my-skill = "/path/to/my-skill-project"
dora-dev = { path = "/path/to/dora-skills" }
dora-plugin = { path = "/path/to/dora-skills", plugin = true }
```

### Skill Groups

| Group | Skills | Description |
|-------|--------|-------------|
| `rust-core` | 8 | Basic Rust (ownership, concurrency, error handling) |
| `rust-patterns` | 7 | Design patterns (domain modeling, performance) |
| `rust-domains` | 7 | Domain-specific (web, CLI, fintech, embedded) |
| `makepad` | 11 | Makepad UI framework |
| `dora` | 8 | Dora-rs robotics framework |
| `dora-hubs` | 9 | Dora hub integrations |

---

## cowork generate

Generate skills from source code of any GitHub repository.

```bash
# Generate from GitHub repo
cowork generate user/repo

# Specify language(s)
cowork generate tokio-rs/tokio --lang rust
cowork generate vercel/next.js --lang typescript

# Only generate llms.txt
cowork generate user/repo --llms-only -o ./output

# Generate from existing llms.txt
cowork generate --from-llms ./llms.txt

# Specify git ref
cowork generate user/repo --ref v1.0.0
```

### Supported Languages

| Language | Parser | Extracts |
|----------|--------|----------|
| Rust | `syn` | pub fn, struct, enum, trait, impl |
| TypeScript | `tree-sitter` | export function, class, interface, type |
| Python | `tree-sitter` | def, class (excluding `_` private items) |

### Output

1. **llms.txt** - API documentation following llms.txt specification
2. **SKILL.md** - Generated skill files with triggers and references

---

## cowork search

Search GitHub for skill repositories.

```bash
# Search by keyword
cowork search tokio

# Search by GitHub topic
cowork search agent-skill --topic

# Limit results
cowork search rust-skills --limit 5

# Show detailed results
cowork search rust-skills --verbose
```

---

## cowork plugins

Manage Claude Code marketplace plugins.

```bash
# List marketplace plugins
cowork plugins list

# Show plugin status
cowork plugins status

# Uninstall a plugin
cowork plugins uninstall rust-skills

# Enable/disable plugins
cowork plugins enable rust-skills
cowork plugins disable rust-skills

# List marketplaces
cowork plugins marketplaces

# Remove a marketplace
cowork plugins remove-marketplace rust-skills
```

---

## cowork test

Generate and run trigger tests for skills.

### Generate Test Reports

```bash
# Generate trigger test report
cowork test

# List all triggers with their skills
cowork test triggers

# Check for trigger conflicts
cowork test --check-conflicts

# Output formats
cowork test -o triggers.json --format json
cowork test -o triggers.yaml --format yaml
cowork test -o triggers.md --format markdown
```

### Run Actual Tests

```bash
# Run trigger tests using Claude
cowork test --run

# Test specific skills by pattern
cowork test --filter "rust-*" --run

# Limit triggers per skill
cowork test --run -n 5

# Scan specific locations
cowork test --global          # ~/.claude/skills/
cowork test --path ./skills   # Custom directory
cowork test --plugins         # Installed plugins
cowork test --all             # Project + global + plugins
```

---

## cowork audit

Security audit of installed skills.

### Basic Usage

```bash
# Scan all installed skills
cowork audit

# Verbose output with details
cowork audit --verbose

# Auto-fix issues where possible
cowork audit --fix
```

### Scan Locations

```bash
cowork audit --global    # Scan ~/.claude/skills/
cowork audit --project   # Scan .claude/skills/
cowork audit --plugins   # Scan installed plugins
```

### Output Formats

```bash
cowork audit -o report.txt --format text
cowork audit -o report.json --format json
cowork audit -o report.md --format markdown
```

### Detection Capabilities

- **Dangerous patterns**: `rm -rf`, `eval()`, `curl|sh`, `sudo`
- **Prompt injection**: Attempts to override system prompts
- **Credential leaks**: `API_KEY`, `PRIVATE KEY`, `password`
- **Risk levels**: SAFE, LOW, MEDIUM, HIGH, CRITICAL

---

## cowork verify

Verify checksums of installed skills against Skills.lock.

```bash
# Verify all skills
cowork verify

# Verify specific skill
cowork verify rust-skills

# Update checksums in lockfile
cowork verify --update

# Verbose output
cowork verify --verbose
```

---

## Security Configuration

Add to `Skills.toml`:

```toml
[security]
# Trusted authors
trusted_authors = ["ZhangHanDong", "anthropics"]

# Custom blocked patterns (regex)
blocked_patterns = ["dangerous-pattern"]

# Paths to skip during scanning (glob patterns)
skip_paths = [
    "**/docs/**",
    "**/examples/**",
    "**/tests/**",
]

# Trusted marketplace plugins (skip scanning)
trusted_marketplaces = ["hookify", "rust-skills"]

# Auto-reject high risk skills
auto_reject_high_risk = false
```

---

## Storage Locations

| Location | Purpose |
|----------|---------|
| `~/.cowork/repos/` | Cloned GitHub repositories |
| `~/.claude/skills/` | Global skills directory |
| `~/.claude/<plugin>/` | Global plugins |
| `.claude/skills/` | Project-local skills |
| `.claude/<plugin>/` | Project-local plugins |
| `.cowork/Skills.toml` | Project configuration |
| `.cowork/Skills.lock` | Installed packages lock |

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `GITHUB_TOKEN` | Required for generate/search commands |

---

## Troubleshooting

### Check Configuration

```bash
cowork doctor
cowork status
```

### Common Issues

**Skills not loading:**
1. Check if skill exists: `cowork list`
2. Verify enabled status: `cowork config show`
3. Ensure triggers match: `cowork test triggers`

**Installation fails:**
1. Check GitHub token: `echo $GITHUB_TOKEN`
2. Verify repo exists: `gh repo view user/repo`
3. Try with verbose: `cowork install user/repo --reinstall`

**Plugin conflicts:**
1. Set trigger priority: `cowork config priority router1 router2`
2. Override specific triggers: `cowork config override "keyword" skill-name`
3. Check for conflicts: `cowork test --check-conflicts`

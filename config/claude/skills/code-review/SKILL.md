---
name: code-review
description: "CRITICAL: Code review skill using GitHub API. Triggers on: review PR, code review, PR review, pull request review, review changes, check this PR, analyze this PR, review #, 代码审查, 审查 PR"
---

# Code Review

> AI-powered code review using GitHub API

## Overview

This skill provides comprehensive code review capabilities by integrating with GitHub's API:
- Fetch and analyze pull requests
- Review code changes with AI assistance
- Generate review comments and suggestions
- Check for common issues and anti-patterns

## Prerequisites

- `gh` CLI must be installed and authenticated
- Or `GITHUB_TOKEN` environment variable must be set

## Usage

### Review a Pull Request

When you ask me to review a PR, I will:

1. **Fetch PR details** using `gh pr view`
2. **Analyze the diff** using `gh pr diff`
3. **Review each file** for:
   - Code quality issues
   - Security vulnerabilities
   - Performance concerns
   - Best practices violations
   - Documentation gaps
4. **Provide actionable feedback**

### Trigger Patterns

| Trigger | Example |
|---------|---------|
| `review PR #123` | Review a specific PR by number |
| `review this PR` | Review the current branch's PR |
| `code review` | Start code review workflow |
| `check PR changes` | Analyze PR changes |
| `review https://github.com/user/repo/pull/123` | Review from URL |

## Commands Reference

### Fetch PR Information

```bash
# View PR details
gh pr view 123

# View PR diff
gh pr diff 123

# View PR files changed
gh api repos/{owner}/{repo}/pulls/123/files

# View PR comments
gh api repos/{owner}/{repo}/pulls/123/comments

# View PR reviews
gh api repos/{owner}/{repo}/pulls/123/reviews
```

### Submit Review Comments

```bash
# Add a comment to a PR
gh pr comment 123 --body "Review comment here"

# Create a review with comments
gh api repos/{owner}/{repo}/pulls/123/reviews \
  -f body="Review summary" \
  -f event="COMMENT"

# Approve a PR
gh pr review 123 --approve --body "LGTM"

# Request changes
gh pr review 123 --request-changes --body "Please address the issues"
```

## Review Workflow

### Step 1: Fetch PR Context

```bash
# Get PR metadata
gh pr view 123 --json title,body,author,files,additions,deletions

# Get full diff
gh pr diff 123
```

### Step 2: Analyze Changes

For each file in the PR, I analyze:

**Code Quality:**
- [ ] Naming conventions
- [ ] Code organization
- [ ] DRY principle violations
- [ ] Complex logic that needs refactoring
- [ ] Unused code or imports

**Security:**
- [ ] Input validation
- [ ] SQL injection risks
- [ ] XSS vulnerabilities
- [ ] Hardcoded secrets
- [ ] Improper error handling

**Performance:**
- [ ] N+1 queries
- [ ] Unnecessary allocations
- [ ] Blocking operations in async code
- [ ] Missing indexes (for DB changes)

**Rust-Specific (if applicable):**
- [ ] Ownership issues (E0382, E0507, etc.)
- [ ] Lifetime annotations
- [ ] Unsafe code usage
- [ ] Error handling with Result/Option
- [ ] Clippy warnings

### Step 3: Generate Review

I provide:
1. **Summary** - Overall assessment
2. **Critical Issues** - Must-fix before merge
3. **Suggestions** - Recommended improvements
4. **Nitpicks** - Optional style improvements
5. **Questions** - Clarifications needed

## Review Templates

### Standard Review

```markdown
## Code Review Summary

**PR:** #123 - Title
**Author:** @username
**Files Changed:** N files (+X/-Y lines)

### Overall Assessment
[APPROVE / REQUEST_CHANGES / COMMENT]

Brief summary of the changes and overall quality.

### Critical Issues
- [ ] Issue 1: Description (file:line)
- [ ] Issue 2: Description (file:line)

### Suggestions
- Consider using X instead of Y in `file.rs:42`
- The function could be simplified by...

### Nitpicks
- Style: Prefer `foo` over `bar` per project conventions
- Typo in comment at line 15

### Questions
- What is the expected behavior when...?
- Should this be documented in the README?

### Files Reviewed
- [x] src/main.rs
- [x] src/lib.rs
- [ ] tests/test.rs (no concerns)
```

### Security-Focused Review

```markdown
## Security Review

**PR:** #123
**Risk Level:** [LOW / MEDIUM / HIGH]

### Security Checklist
- [ ] Input validation on all user inputs
- [ ] No hardcoded credentials
- [ ] Proper error handling (no stack traces exposed)
- [ ] SQL queries use parameterized statements
- [ ] File paths are validated
- [ ] Authentication/authorization checks in place

### Findings
| Severity | Issue | Location | Recommendation |
|----------|-------|----------|----------------|
| HIGH | ... | file:line | ... |
| MEDIUM | ... | file:line | ... |

### Recommendations
1. ...
2. ...
```

## Example Usage

### Review Current PR

```
User: Review the current PR

Claude: Let me fetch the PR details and review the changes.

[Executes: gh pr view --json number,title,body,files]
[Executes: gh pr diff]

Based on my analysis...
```

### Review Specific PR

```
User: Review PR #42 in user/repo

Claude: I'll review PR #42.

[Executes: gh pr view 42 -R user/repo --json ...]
[Executes: gh pr diff 42 -R user/repo]

Here's my review...
```

### Quick Check

```
User: Quick check the PR for security issues

Claude: I'll perform a security-focused review.

[Analyzes for security patterns only]

Security assessment...
```

## Integration with Other Skills

This skill works well with:

| Skill | Integration |
|-------|-------------|
| `rust-router` | Rust-specific code quality checks |
| `domain-web` | Web security best practices |
| `unsafe-checker` | Unsafe Rust code analysis |
| `memory-filesystem` | Remember previous review context |

## Best Practices

### For Reviewers

1. **Be specific** - Reference exact file:line locations
2. **Be constructive** - Suggest solutions, not just problems
3. **Prioritize** - Mark critical vs. nice-to-have
4. **Be timely** - Review PRs promptly

### For Authors

1. **Small PRs** - Easier to review thoroughly
2. **Good descriptions** - Explain the why, not just what
3. **Self-review first** - Check your own code before requesting
4. **Address all comments** - Don't leave feedback unresolved

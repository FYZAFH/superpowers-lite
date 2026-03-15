---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Creation Steps

### 1. Ensure `.worktrees/` is in `.gitignore`

```bash
git check-ignore -q .worktrees 2>/dev/null || echo '.worktrees' >> .gitignore && git add .gitignore && git commit -m "Add .worktrees to .gitignore"
```

### 2. Create Worktree

```bash
git worktree add .worktrees/$BRANCH_NAME -b $BRANCH_NAME
cd .worktrees/$BRANCH_NAME
```

### 3. Run Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### 4. Verify Clean Baseline

Run tests to ensure worktree starts clean:

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### 5. Report Location

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Example Workflow

```
You: I'm using the using-git-worktrees skill to set up an isolated workspace.

[Ensure .worktrees in .gitignore]
[Create worktree: git worktree add .worktrees/auth -b feature/auth]
[Run npm install]
[Run npm test - 47 passing]

Worktree ready at /Users/jesse/myproject/.worktrees/auth
Tests passing (47 tests, 0 failures)
Ready to implement auth feature
```

## Red Flags

**Never:**
- Skip baseline test verification
- Proceed with failing tests without asking

**Always:**
- Ensure `.worktrees/` is in `.gitignore`
- Auto-detect and run project setup
- Verify clean test baseline

## Integration

**Called by:**
- **brainstorming** (Phase 4) - REQUIRED when design is approved and implementation follows
- **subagent-driven-development** - REQUIRED before executing any tasks
- Any skill needing isolated workspace

**Pairs with:**
- **finishing-a-development-branch** - REQUIRED for cleanup after work complete

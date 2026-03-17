---
name: subagent-driven-development
description: Use before implementing anything - dispatches fresh subagent per task with two-stage review. As an orchestrator, you must never implement anything yourself.
---

# Subagent-Driven Development

Execute plan by dispatching fresh subagent per task, use code-review skill to review after each: spec compliance review first, then code quality review.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Fresh subagent per task + two-stage review (spec then quality, code-review skill) = high quality, fast iteration

## Prerequisites

This skill requires two artifacts before starting:

1. **Spec** — a design document produced by the `brainstorming` skill, saved to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`. If you don't have a spec, invoke `brainstorming` first.
2. **Plan** — an implementation plan produced by the `writing-plans` skill, saved to `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`. If you have a spec but no plan, invoke `writing-plans` first.

**IMPORTANT:** Do NOT assume these artifacts exist based on the topic being discussed or files you find by searching. A spec/plan only counts as "existing" if the user has **explicitly pointed you to it** (e.g., via `@file` reference or by providing the path directly). If the user has not explicitly indicated these files, treat them as missing and invoke the corresponding skill.

- No spec → invoke `brainstorming`, stop here
- Spec but no plan → invoke `writing-plans`, stop here
- Both exist → proceed with this skill

## Setup: Isolated Workspace

Before executing any tasks, create an isolated worktree:

```bash
# Ensure .worktrees/ is git-ignored
git check-ignore -q .worktrees 2>/dev/null || echo '.worktrees' >> .gitignore && git add .gitignore && git commit -m "Add .worktrees to .gitignore"

# Create worktree
git worktree add .worktrees/$BRANCH_NAME -b $BRANCH_NAME
cd .worktrees/$BRANCH_NAME
```

Run project setup (npm install / cargo build / pip install / go mod download) and verify tests pass before proceeding.

## The Process

1. Read plan, extract all tasks, create TodoWrite
2. **For each task, sequentially (never parallel):**
   a. Dispatch `implementer` subagent
   b. Handle implementer status:
      - NEEDS_CONTEXT → answer their questions, re-dispatch implementer from (a)
      - DONE / DONE_WITH_CONCERNS → continue to (c)
   c. Dispatch `spec-reviewer` subagent
      - Issues found → implementer fixes → re-dispatch spec-reviewer, repeat until approved
      - **3 consecutive failures → stop loop, orchestrator assesses and decides next step**
      - Approved → continue to (d)
   d. Dispatch `code-reviewer` subagent
      - Issues found → implementer fixes → re-dispatch code-reviewer, repeat until approved
      - **3 consecutive failures → stop loop, orchestrator assesses and decides next step**
      - Approved → mark task complete, advance to next task
3. After all tasks complete: dispatch `code-reviewer` for the **entire implementation** (full git range)
4. Invoke `finishing-a-development-branch` skill

## Dispatching Subagents

Three agent types, dispatched by name via the Agent tool:

**`implementer`** — Implements a single task using TDD.
Dispatch with: task description, spec/plan paths, working directory, context about dependencies.

**`spec-reviewer`** — Verifies implementation matches spec.
Dispatch with: spec/plan paths, git range (base SHA..head SHA).

**`code-reviewer`** — Reviews code quality and production readiness.
Dispatch with: spec/plan paths, git range (base SHA..head SHA).

### Example Dispatch

```
Agent tool:
  subagent_type: implementer
  prompt: |
    Task 3: Implement user authentication endpoint

    Spec: docs/superpowers/specs/auth-spec.md
    Plan: docs/superpowers/plans/auth-plan.md
    Work from: .worktrees/feature-auth

    Context: This builds on the session middleware from Task 2.
    The database schema is already in place (see db/schema.ts).
```

```
Agent tool:
  subagent_type: spec-reviewer
  prompt: |
    Review Task 3: user authentication endpoint

    Spec: docs/superpowers/specs/auth-spec.md
    Plan: docs/superpowers/plans/auth-plan.md
    Base: abc1234
    Head: def5678
```

## Handling Implementer Status

**DONE:** Proceed to spec compliance review.

**DONE_WITH_CONCERNS:** Read the concerns. If about correctness or scope, address before review. If observations (e.g., "this file is getting large"), note and proceed.

**NEEDS_CONTEXT:** Provide missing context and resume it.

**BLOCKED:** Assess the blocker:
1. If it's a context problem, provide more context and resume it
2. If the task is too large, break it into smaller pieces
3. If the plan itself is wrong, verify the blocker is real. Then:
      - If the fix is local to the plan (does not contradict the spec or invalidate completed tasks) → fix the plan yourself and re-dispatch
      - Otherwise → escalate to the human

**Never** ignore an escalation or force retry without changes. If the implementer said it's stuck, something needs to change.

## Evaluating Reviewer Feedback

Subagent reviewers catch real issues, but they lack full session context. **Verify before implementing. Technical correctness over compliance.**

- **Correct:** Fix it, test, move on
- **Wrong (reviewer lacks context):** Note why and skip
- **Unclear:** Investigate before acting

If reviewer suggests adding unrequested features: check codebase for actual usage. If unused, skip (YAGNI).

## Red Flags

**Never:**
- Implement the code yourself instead of using sub-agents.
- Start implementation on main/master branch without explicit user consent
- Skip reviews (spec compliance OR code quality)
- Proceed with unfixed issues
- Dispatch multiple implementation subagents in parallel (conflicts)
- Skip scene-setting context (subagent needs to understand where task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance
- Skip review loops (reviewer found issues = implementer fixes = review again)
- Let implementer self-review replace actual review (both are needed)
- Start code quality review before spec compliance passes
- Move to next task while either review has open issues

**If subagent asks questions:** Answer clearly and completely. Don't rush them.

**If reviewer finds issues:** Implementer fixes → reviewer reviews again → repeat until approved.

**If subagent fails task:** Dispatch fix subagent with specific instructions. **Don't fix manually** (context pollution).

## Integration

**Required workflow skills:**
- **superpowers-lite:writing-plans** — Creates the plan this skill executes
- **superpowers-lite:finishing-a-development-branch** — Complete development after all tasks

---
name: code-review
description: Two-stage code review via subagents — spec compliance then code quality. Guides evaluation of reviewer feedback.
---

# Code Review

## Two-Stage Review Process

Every implementation gets two independent reviews, in order:

1. **Spec compliance** (`spec-reviewer` agent) — Did they build what was requested? Nothing more, nothing less.
2. **Code quality** (`code-reviewer` agent) — Is it well-built? Clean, tested, production-ready.

Only proceed to stage 2 after stage 1 passes.

## Dispatching Reviewers

Dispatch each reviewer as a subagent with the spec/plan paths and git range:

```
Agent tool:
  subagent_type: spec-reviewer
  prompt: |
    Review: [task description]
    Spec: [path to spec]
    Plan: [path to plan]
    Base: [base SHA]
    Head: [head SHA]
```

```
Agent tool:
  subagent_type: code-reviewer
  prompt: |
    Review: [task description]
    Spec: [path to spec]
    Plan: [path to plan]
    Base: [base SHA]
    Head: [head SHA]
```

## Evaluating Reviewer Feedback

Subagent reviewers catch real issues, but they lack full session context. **Verify before implementing. Technical correctness over compliance.**

### Reviewer approves

Proceed to next stage or next task.

### Reviewer finds issues

```
FOR each issue:
  1. Check: Is suggestion technically correct for THIS codebase?
  2. Check: Does it break existing functionality?
  3. Check: Does reviewer have full context?

  IF correct: Fix it, test, move on
  IF wrong: Note why and skip (reviewer lacks context)
  IF unclear: Investigate before acting
```

### YAGNI Check

If reviewer suggests adding features or "implementing properly":
- Check codebase for actual usage
- If unused: skip (YAGNI)
- If used: implement

### When To Push Back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context (common with subagents)
- Violates YAGNI
- Technically incorrect for this stack
- Conflicts with the plan or spec

Note the technical reason, skip the suggestion, continue.

## The Bottom Line

**Subagent feedback = suggestions to evaluate, not orders to follow.**

Verify. Then implement what's correct. Skip what's wrong.

---
name: receiving-code-review
description: Use when processing code review feedback from reviewer subagents, before implementing suggestions - requires technical verification against the codebase, not blind implementation
---

# Receiving Subagent Code Review

## Overview

Subagent reviewers catch real issues, but they also lack full session context. Evaluate every suggestion against codebase reality before implementing.

**Core principle:** Verify before implementing. Technical correctness over compliance.

## The Response Pattern

```
WHEN receiving subagent review feedback:

1. READ: Complete feedback without reacting
2. VERIFY: Check each suggestion against codebase reality
3. EVALUATE: Technically sound for THIS codebase?
4. CATEGORIZE: Critical / Important / Minor / Wrong
5. IMPLEMENT: One item at a time, test each
```

## Handling Review Results

### Reviewer approves
Proceed to next step in workflow.

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

```
IF reviewer suggests "implementing properly" or adding features:
  grep codebase for actual usage

  IF unused: Skip (YAGNI)
  IF used: Implement
```

## Implementation Order

```
FOR multi-item feedback:
  1. Blocking issues (breaks, security)
  2. Simple fixes (typos, imports)
  3. Complex fixes (refactoring, logic)
  4. Test each fix individually
  5. Verify no regressions
```

## When To Push Back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context (common with subagents)
- Violates YAGNI (unused feature)
- Technically incorrect for this stack
- Conflicts with the plan or spec

**How:** Note the technical reason, skip the suggestion, continue.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Blind implementation | Verify against codebase first |
| Batch without testing | One at a time, test each |
| Assuming reviewer is right | Subagents lack session context — check |
| Adding unrequested features | YAGNI — reviewer may over-suggest |
| Ignoring all feedback | Reviewers catch real issues — evaluate fairly |

## The Bottom Line

**Subagent feedback = suggestions to evaluate, not orders to follow.**

Verify. Then implement what's correct. Skip what's wrong.

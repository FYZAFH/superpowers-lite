# Superpowers Lite

A simplified fork of [superpowers](https://github.com/obra/superpowers), focused on **Claude Code only** with a **serial execution** workflow.

## What Changed (and Why)

This fork strips superpowers down to its essential serial happy path for Claude Code. The original supports multiple platforms (Gemini CLI, Codex, OpenCode, Cursor) and multiple execution strategies. This version makes opinionated choices so the agent has fewer decisions and more focus.

### Removed

- **Multi-platform support** — Codex, OpenCode, Cursor, Gemini CLI configs and docs. Claude Code only.
- **`dispatching-parallel-agents`** — Claude Code natively supports parallel dispatch via the Agent tool. A skill standardizing it added weight without value.
- **`executing-plans`** — The "no subagent" fallback for platforms that can't dispatch agents. With Claude Code, subagent-driven-development is always available.
- **`requesting-code-review` / `receiving-code-review`** (as separate skills) — Merged into a single `code-review` skill. You never dispatch a reviewer without evaluating results.
- **`test-driven-development`** (as a standalone skill) — The main agent never writes code; the implementer subagent does. TDD methodology is now baked directly into the implementer agent.
- **`using-git-worktrees`** (as a standalone skill) — Reduced to a setup step in `subagent-driven-development`. Always uses `.worktrees/`, always git-ignored.
- **Visual companion** — Browser-based brainstorming visualization. ASCII art and text visualization remain.
- **Model selection guidance** — The controller doesn't need to decide which model subagents use.
- **Historical docs and plans** — Internal development history not relevant to users.

### Restructured

- **Agent-driven architecture** — Prompt templates with `{PLACEHOLDER}` filling replaced by proper subagent files in `agents/`. The agent file defines WHO you are and HOW you work (static). The dispatch prompt provides WHAT you're doing (dynamic).
  - `agents/implementer.md` — TDD implementer subagent
  - `agents/spec-reviewer.md` — Spec compliance reviewer
  - `agents/code-reviewer.md` — Code quality reviewer
- **`code-review`** — Single skill covering two-stage review (spec compliance → code quality) and guidance on evaluating reviewer feedback.
- **Decision points standardized** — Worktree location (always `.worktrees/`), execution strategy (always subagent-driven), review flow (always two-stage).

## The Workflow

```
brainstorming → writing-plans → subagent-driven-development → finishing-a-development-branch
```

1. **brainstorming** — Refines ideas through questions, explores alternatives, presents design in sections for validation.
2. **writing-plans** — Breaks work into tasks. Every task has file paths, code, verification steps.
3. **subagent-driven-development** — Dispatches fresh `implementer` subagent per task. Each task gets two-stage review: `spec-reviewer` then `code-reviewer`. Implementer uses strict TDD.
4. **finishing-a-development-branch** — Verifies tests, presents options (merge/PR/keep/discard), cleans up worktree.

## Installation

### Claude Code (Plugin Marketplace)

```bash
/plugin install superpowers-lite
```

### Manual

Clone this repo and add it as a local plugin:

```bash
git clone https://github.com/FYZAFH/superpowers-lite.git
```

## Skills

| Skill | Purpose |
|-------|---------|
| `brainstorming` | Socratic design refinement |
| `writing-plans` | Detailed implementation plans |
| `subagent-driven-development` | Serial task execution with two-stage review |
| `code-review` | Dispatch reviewers + evaluate feedback |
| `finishing-a-development-branch` | Merge/PR decision workflow |
| `systematic-debugging` | 4-phase root cause process |
| `verification-before-completion` | Final safety net before claiming "done" |
| `using-superpowers` | Introduction to the skills system |

## Agents

| Agent | Dispatched by | Role |
|-------|--------------|------|
| `implementer` | subagent-driven-development | Implements tasks using TDD |
| `spec-reviewer` | code-review | Verifies implementation matches spec |
| `code-reviewer` | code-review | Reviews code quality and production readiness |

## Philosophy

- **Test-Driven Development** — Write tests first, always (enforced in implementer agent)
- **Systematic over ad-hoc** — Process over guessing
- **Simplicity** — Fewer decisions, more focus
- **Evidence over claims** — Verify before declaring success

## Credits

Based on [superpowers](https://github.com/obra/superpowers) by [Jesse Vincent](https://github.com/obra).

## License

MIT License — see LICENSE file for details.

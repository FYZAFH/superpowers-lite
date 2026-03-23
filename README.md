# Superpowers Lite

A shared-source fork of [superpowers](https://github.com/obra/superpowers), with **direct Claude Code plugin installation** and **install-time Codex adaptation** for the same serial workflow.

## Repository Model

This repo keeps the Claude-oriented prompts as the source of truth, then adapts file names and tool names at render/install time for Codex. The workflow itself stays the same on both platforms.

- Claude Code stays plugin-native via `.claude-plugin/`, `hooks/`, and `bootstrap.md`
- Codex gets a rendered bundle with platform-specific replacements during install
- `bootstrap.md` is the shared session bootstrap source; Claude hooks read it directly, Codex install injects it into `AGENTS.md`

### Simplified

- **Single workflow** — one serial happy path: brainstorm → plan → implement via subagents → finish
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

### Claude Code (Plugin System)

This repository still ships a first-class Claude Code plugin:
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `hooks/hooks.json`

If your Claude Code environment can install from the plugin marketplace:

```bash
/plugin install superpowers-lite
```

If you prefer working from a local clone, clone this repo and install it through Claude Code's plugin system as a local plugin.

### Codex

Codex project-local installation creates a dedicated `./.superpowers-lite/codex-home`, installs the rendered Codex bundle there, and creates launchers plus uninstallers in the same folder. It also reuses your existing Codex login/model config from `~/.codex` when available.

Requirements:
- macOS / Linux: `bash`, `python3`
- Windows: `PowerShell`, `Python 3`
- No-preclone bootstrap flows also require `git`

macOS / Linux, no-preclone installation:

```bash
cd ~/example_sound
bash <(curl -fsSL https://raw.githubusercontent.com/FYZAFH/superpowers-lite/main/scripts/bootstrap-codex-project.sh)
./.superpowers-lite/codex
```

If you want to remove it later:

```bash
./.superpowers-lite/uninstall
```

macOS / Linux, if you already have a local clone of this repo:

```bash
cd ~/example_sound
/path/to/superpowers-lite/scripts/install-codex-project.sh
./.superpowers-lite/codex
```

This creates `./.superpowers-lite/codex-home`, installs the rendered bundle there, creates `./.superpowers-lite/codex` as a launcher, and creates `./.superpowers-lite/uninstall` as a self-contained remover. When `~/.codex/config.toml` or `~/.codex/auth.json` exist, the project-local home links them automatically so you keep your existing Codex login and model settings. In git repos, `.superpowers-lite/` is also added to `.git/info/exclude`.

To remove the project-local installation:

```bash
cd ~/example_sound
/path/to/superpowers-lite/scripts/uninstall-codex-project.sh
```

Windows PowerShell, no-preclone installation:

```powershell
cd ~\example_sound
powershell -NoProfile -ExecutionPolicy Bypass -Command "$tmp = Join-Path $env:TEMP 'bootstrap-codex-project.ps1'; Invoke-RestMethod 'https://raw.githubusercontent.com/FYZAFH/superpowers-lite/main/scripts/bootstrap-codex-project.ps1' -OutFile $tmp; & $tmp"
.\.superpowers-lite\codex.cmd
```

Shorter version, if you're OK with executing the fetched script directly:

```powershell
cd ~\example_sound
irm https://raw.githubusercontent.com/FYZAFH/superpowers-lite/main/scripts/bootstrap-codex-project.ps1 | iex
.\.superpowers-lite\codex.cmd
```

To remove the project-local installation on Windows:

```powershell
.\.superpowers-lite\uninstall.cmd
```

Windows PowerShell, if you already have a local clone of this repo:

```powershell
cd ~\example_sound
powershell -NoProfile -ExecutionPolicy Bypass -File C:\path\to\superpowers-lite\scripts\install-codex-project.ps1 -ProjectRoot (Get-Location).Path
.\.superpowers-lite\codex.cmd
```

The Windows project-local install also creates `codex.ps1`, `uninstall.ps1`, `codex.cmd`, and `uninstall.cmd` alongside the Unix `codex` and `uninstall` helpers.

Global installation, shared by all projects:

```bash
git clone https://github.com/FYZAFH/superpowers-lite.git
cd superpowers-lite
./scripts/install-codex.sh
```

By default this installs the rendered Codex bundle under `${CODEX_HOME:-~/.codex}/vendor_imports/superpowers-lite`, links the skills into `${CODEX_HOME:-~/.codex}/skills`, and updates `${CODEX_HOME:-~/.codex}/AGENTS.md` with a managed block.

To remove the Codex installation:

```bash
./scripts/uninstall-codex.sh
```

Windows global installation from a local clone:

```powershell
cd C:\path\to\superpowers-lite
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-codex.ps1
```

To remove the Windows global installation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall-codex.ps1
```

### Development Utilities

```bash
./scripts/render-bootstrap.sh
python3 ./scripts/render-platform-bundle.py --platform codex --output /tmp/superpowers-codex
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

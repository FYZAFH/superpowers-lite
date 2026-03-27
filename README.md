# Superpowers Lite

A workflow-focused fork of [superpowers](https://github.com/obra/superpowers), with **direct Claude Code plugin installation** and a **Codex-native prompt/config tree** for the same serial workflow.

## Repository Model

This repo keeps the workflow aligned across Claude Code and Codex, but the prompt sources are platform-native because the two tools weight instructions, expose files, and run subagents differently.

- Claude Code stays plugin-native via `.claude-plugin/`, `hooks/`, `bootstrap.md`, `skills/`, and `agents/`
- Codex has its own source tree under `codex/`
- Render/install copies native platform bundles instead of doing text-level prompt rewriting between platforms
- `bootstrap.md` remains Claude-only; Codex orchestration lives in `codex/config.toml` and `codex/agents/*.toml`
- Codex installs into Codex's native filesystem layout:
  - project scope: `.agents/skills/`, `.codex/config.toml`, `.codex/agents/`
  - user scope: `~/.agents/skills/`, `~/.codex/config.toml`, `~/.codex/agents/`

### Simplified

- **Single workflow** — one serial happy path: brainstorm → plan → implement via subagents → finish
- **`dispatching-parallel-agents`** — Claude Code natively supports parallel dispatch via the Agent tool. A skill standardizing it added weight without value.
- **`executing-plans`** — The "no subagent" fallback for platforms that can't dispatch agents. With Claude Code, subagent-driven-development is always available.
- **`requesting-code-review` / `receiving-code-review`** (as separate skills) — Merged into a single `code-review` skill. You never dispatch a reviewer without evaluating results.
- **`test-driven-development`** (as a standalone skill) — The main agent never writes code; the implementer subagent does. TDD methodology is now baked directly into the implementer agent.
- **`using-git-worktrees`** (as a standalone skill) — Reduced to a setup step in `subagent-driven-development`. Always uses `.worktrees/`, always git-ignored.
- **Visual companion** — Browser-based design/spec visualization. ASCII art and text visualization remain.
- **Model selection guidance** — The controller doesn't need to decide which model subagents use.
- **Historical docs and plans** — Internal development history not relevant to users.

### Restructured

- **Agent-driven architecture** — Prompt templates with `{PLACEHOLDER}` filling replaced by real subagent files. Claude Code keeps its native Markdown agent files in `agents/`; Codex uses `codex/agents/*.toml` registered from `codex/config.toml`. The agent file defines WHO you are and HOW you work (static). The dispatch prompt provides WHAT you're doing (dynamic).
  - `agents/implementer.md` / `codex/agents/implementer.toml` — TDD implementer subagent
  - `agents/spec-reviewer.md` / `codex/agents/spec-code-reviewer.toml` — Spec compliance reviewer
  - `agents/code-reviewer.md` / `codex/agents/quality-code-reviewer.toml` — Code quality reviewer
- **`code-review`** — Single skill covering two-stage review (spec compliance → code quality) and guidance on evaluating reviewer feedback.
- **Decision points standardized** — Worktree location (always `.worktrees/`), execution strategy (always subagent-driven), review flow (always two-stage).

## The Workflow

```
writing-specs → writing-plans → subagent-driven-development → finishing-a-development-branch
```

1. **writing-specs** — Refines ideas through questions, explores alternatives, presents design in sections for validation, and writes the approved spec.
2. **writing-plans** — Breaks work into tasks. Every task has file paths, code, verification steps.
3. **subagent-driven-development** — Dispatches fresh `implementer` subagent per task. Each task gets two-stage review. In Codex these are `spec-code-reviewer` then `quality-code-reviewer`. Implementer uses strict TDD.
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

Codex installation uses Codex's native directory structure. In Codex, the workflow is branded as **double-SDD**: Specification-Driven Development + Subagent-Driven Development. Project-local installation does **not** depend on a custom `CODEX_HOME`; after install, just run `codex` in the project and Codex will pick up `.agents/skills`, `.codex/config.toml`, and `.codex/agents`.

double-SDD does **not** inject Codex prompt text into `AGENTS.md`. Codex-specific orchestration lives in `.codex/config.toml`, and each custom subagent disables inherited skills through its own TOML config.

Codex-native source files live under [`codex/`](codex/README.md).

Requirements:
- macOS / Linux: `bash`, `python3`
- Windows: `PowerShell`, `Python 3`
- No-preclone bootstrap flows also require `git`

macOS / Linux, no-preclone installation:

```bash
cd ~/example_sound
bash <(curl -fsSL https://raw.githubusercontent.com/FYZAFH/superpowers-lite/main/scripts/bootstrap-codex-project.sh)
codex
```

If you want to remove it later:

```bash
./.double-sdd/uninstall
```

macOS / Linux, if you already have a local clone of this repo:

```bash
cd ~/example_sound
/path/to/superpowers-lite/scripts/install-codex-project.sh
codex
```

This installs the double-SDD Codex workflow by merging managed orchestration blocks into `.codex/config.toml`, installing skills into `.agents/skills/`, installing custom subagents into `.codex/agents/`, and creating `.double-sdd/uninstall` as a self-contained remover. In git repos, `.double-sdd/` is also added to `.git/info/exclude`.

To remove the project-local installation:

```bash
cd ~/example_sound
/path/to/superpowers-lite/scripts/uninstall-codex-project.sh
```

Windows PowerShell, no-preclone installation:

```powershell
cd ~\example_sound
powershell -NoProfile -ExecutionPolicy Bypass -Command "$tmp = Join-Path $env:TEMP 'bootstrap-codex-project.ps1'; Invoke-RestMethod 'https://raw.githubusercontent.com/FYZAFH/superpowers-lite/main/scripts/bootstrap-codex-project.ps1' -OutFile $tmp; & $tmp"
codex
```

Shorter version, if you're OK with executing the fetched script directly:

```powershell
cd ~\example_sound
irm https://raw.githubusercontent.com/FYZAFH/superpowers-lite/main/scripts/bootstrap-codex-project.ps1 | iex
codex
```

To remove the project-local installation on Windows:

```powershell
.\.double-sdd\uninstall.ps1
```

Windows PowerShell, if you already have a local clone of this repo:

```powershell
cd ~\example_sound
powershell -NoProfile -ExecutionPolicy Bypass -File C:\path\to\superpowers-lite\scripts\install-codex-project.ps1 -ProjectRoot (Get-Location).Path
codex
```

The Windows project-local install creates `uninstall.ps1` and `uninstall.cmd` inside `.double-sdd/`.

Global installation, shared by all projects:

macOS / Linux, no-preclone global installation:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FYZAFH/superpowers-lite/main/scripts/bootstrap-codex-global.sh)
codex
```

Windows PowerShell, no-preclone global installation:

```powershell
irm https://raw.githubusercontent.com/FYZAFH/superpowers-lite/main/scripts/bootstrap-codex-global.ps1 | iex
codex
```

This installs directly into Codex's native user-scoped directories:
- `${CODEX_HOME:-~/.codex}/config.toml`
- `${CODEX_HOME:-~/.codex}/agents/`
- `~/.agents/skills/`

After it completes you can just run `codex` in any directory.

If you want to remove the global installation later:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FYZAFH/superpowers-lite/main/scripts/bootstrap-codex-global.sh) --uninstall
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$tmp = Join-Path $env:TEMP 'bootstrap-codex-global.ps1'; Invoke-RestMethod 'https://raw.githubusercontent.com/FYZAFH/superpowers-lite/main/scripts/bootstrap-codex-global.ps1' -OutFile $tmp; & $tmp -Uninstall"
```

If you prefer a local clone, use:

```bash
git clone https://github.com/FYZAFH/superpowers-lite.git
cd superpowers-lite
./scripts/install-codex.sh
```

By default this updates `${CODEX_HOME:-~/.codex}/config.toml`, installs custom subagents into `${CODEX_HOME:-~/.codex}/agents`, and installs skills into `~/.agents/skills`.

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
python3 ./scripts/render-platform-bundle.py --platform codex --output /tmp/double-sdd-codex
```

The rendered Codex bundle contains:
- `.agents/skills/...`
- `.codex/config.toml`
- `.codex/agents/*.toml`

## Skills

| Skill | Purpose |
|-------|---------|
| `writing-specs` | Clarify requirements, validate design, and write the approved spec |
| `writing-plans` | Detailed implementation plans |
| `subagent-driven-development` | Serial task execution with two-stage review |
| `code-review` | Dispatch reviewers + evaluate feedback |
| `finishing-a-development-branch` | Merge/PR decision workflow |
| `systematic-debugging` | 4-phase root cause process |
| `verification-before-completion` | Final safety net before claiming "done" |
| `using-double-sdd` | Introduction to the double-SDD skills system |

## Agents

| Agent | Dispatched by | Role |
|-------|--------------|------|
| `implementer` | subagent-driven-development | Implements tasks using TDD |
| `spec-reviewer` / `spec-code-reviewer` | code-review | Verifies implementation matches spec |
| `code-reviewer` / `quality-code-reviewer` | code-review | Reviews code quality and production readiness |
| `spec-document-reviewer` | writing-specs | Reviews specs before planning |
| `plan-document-reviewer` | writing-plans | Reviews plan chunks before execution |

For Codex, these custom agents are registered from `.codex/config.toml`.

## Philosophy

- **Test-Driven Development** — Write tests first, always (enforced in implementer agent)
- **Systematic over ad-hoc** — Process over guessing
- **Simplicity** — Fewer decisions, more focus
- **Evidence over claims** — Verify before declaring success

## Credits

Based on [superpowers](https://github.com/obra/superpowers) by [Jesse Vincent](https://github.com/obra).

## License

MIT License — see LICENSE file for details.

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/superpowers-lite-bundle.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

python3 "${REPO_ROOT}/scripts/render-platform-bundle.py" --platform codex --output "${TMP_DIR}/codex"

test -f "${TMP_DIR}/codex/AGENTS.md"
test -f "${TMP_DIR}/codex/.agents/skills/using-superpowers/SKILL.md"
test -f "${TMP_DIR}/codex/.agents/skills/subagent-driven-development/SKILL.md"
test -f "${TMP_DIR}/codex/.agents/skills/code-review/SKILL.md"
test -f "${TMP_DIR}/codex/.agents/skills/writing-plans/SKILL.md"
test -f "${TMP_DIR}/codex/.agents/skills/brainstorming/spec-document-reviewer-prompt.md"
test -f "${TMP_DIR}/codex/.agents/skills/writing-plans/plan-document-reviewer-prompt.md"
test -f "${TMP_DIR}/codex/.codex/agents/implementer.toml"
test -f "${TMP_DIR}/codex/.codex/agents/spec-reviewer.toml"
test -f "${TMP_DIR}/codex/.codex/agents/code-reviewer.toml"

grep -q "AGENTS.md" "${TMP_DIR}/codex/AGENTS.md"
grep -q "Codex's native skills system" "${TMP_DIR}/codex/AGENTS.md"
grep -q "using-superpowers" "${TMP_DIR}/codex/AGENTS.md"
grep -q "update_plan" "${TMP_DIR}/codex/.agents/skills/subagent-driven-development/SKILL.md"
grep -q "spawn_agent" "${TMP_DIR}/codex/.agents/skills/subagent-driven-development/SKILL.md"
grep -q "agent_type: implementer" "${TMP_DIR}/codex/.agents/skills/subagent-driven-development/SKILL.md"
grep -q "agent_type: spec-reviewer" "${TMP_DIR}/codex/.agents/skills/code-review/SKILL.md"
grep -q "agent_type: code-reviewer" "${TMP_DIR}/codex/.agents/skills/code-review/SKILL.md"
grep -q 'Use the `subagent-driven-development` skill' "${TMP_DIR}/codex/.agents/skills/writing-plans/SKILL.md"
grep -q "Reference relevant skills by name" "${TMP_DIR}/codex/.agents/skills/writing-plans/SKILL.md"
grep -q "spawn_agent" "${TMP_DIR}/codex/.agents/skills/brainstorming/spec-document-reviewer-prompt.md"
grep -q "spawn_agent" "${TMP_DIR}/codex/.agents/skills/writing-plans/plan-document-reviewer-prompt.md"
grep -q 'verification-before-completion' "${TMP_DIR}/codex/.agents/skills/systematic-debugging/SKILL.md"
grep -q '^# superpowers-lite:managed$' "${TMP_DIR}/codex/.codex/agents/implementer.toml"
grep -q '^name = "implementer"$' "${TMP_DIR}/codex/.codex/agents/implementer.toml"
grep -q '^name = "spec-reviewer"$' "${TMP_DIR}/codex/.codex/agents/spec-reviewer.toml"
grep -q '^name = "code-reviewer"$' "${TMP_DIR}/codex/.codex/agents/code-reviewer.toml"
grep -q '^developer_instructions = ' "${TMP_DIR}/codex/.codex/agents/implementer.toml"

python3 - <<'PY'
import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("render_platform_bundle", "scripts/render-platform-bundle.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

variants = [
    "- **superpowers:verification-before-completion** - Verify fix worked before claiming success",
    "- **superpowers-lite:verification-before-completion** - Verify fix worked before claiming success",
]

for variant in variants:
    rendered = module.render_text(
        variant,
        "skills/systematic-debugging/SKILL.md",
        "codex",
    )
    expected = "- **`verification-before-completion`** - Verify fix worked before claiming success"
    assert rendered == expected, (variant, rendered)
PY

for pattern in \
    "bootstrap.md" \
    "CLAUDE.md" \
    "Claude Code" \
    "Skill tool" \
    "Agent tool" \
    "TodoWrite" \
    "subagent_type" \
    "superpowers-lite:" \
    "superpowers:" \
    "\\.claude-plugin" \
    "CLAUDE_PLUGIN_ROOT" \
    "@ syntax" \
    "@file" \
    "Task tool (general-purpose)" \
    "hooks/hooks\\.json" \
    "vendor_imports" \
    "codex-home"
do
    if rg -n "$pattern" -S "${TMP_DIR}/codex" >/dev/null; then
        echo "Codex bundle still contains forbidden pattern: $pattern" >&2
        exit 1
    fi
done

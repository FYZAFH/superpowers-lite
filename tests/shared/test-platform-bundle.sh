#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/superpowers-lite-bundle.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

python3 "${REPO_ROOT}/scripts/render-platform-bundle.py" --platform codex --output "${TMP_DIR}/codex"

test -f "${TMP_DIR}/codex/AGENTS.md"
test -f "${TMP_DIR}/codex/skills/using-superpowers/SKILL.md"
test -f "${TMP_DIR}/codex/skills/subagent-driven-development/SKILL.md"
test -f "${TMP_DIR}/codex/skills/code-review/SKILL.md"
test -f "${TMP_DIR}/codex/skills/writing-plans/SKILL.md"
test -f "${TMP_DIR}/codex/skills/brainstorming/spec-document-reviewer-prompt.md"
test -f "${TMP_DIR}/codex/skills/writing-plans/plan-document-reviewer-prompt.md"

grep -q "AGENTS.md" "${TMP_DIR}/codex/AGENTS.md"
grep -q "Codex's native skills system" "${TMP_DIR}/codex/AGENTS.md"
grep -q "using-superpowers" "${TMP_DIR}/codex/AGENTS.md"
grep -q "update_plan" "${TMP_DIR}/codex/skills/subagent-driven-development/SKILL.md"
grep -q "spawn_agent" "${TMP_DIR}/codex/skills/subagent-driven-development/SKILL.md"
grep -q "${TMP_DIR}/codex/agents/implementer.md" "${TMP_DIR}/codex/skills/subagent-driven-development/SKILL.md"
grep -q "${TMP_DIR}/codex/agents/spec-reviewer.md" "${TMP_DIR}/codex/skills/code-review/SKILL.md"
grep -q "${TMP_DIR}/codex/agents/code-reviewer.md" "${TMP_DIR}/codex/skills/code-review/SKILL.md"
grep -q 'Use the `subagent-driven-development` skill' "${TMP_DIR}/codex/skills/writing-plans/SKILL.md"
grep -q "Reference relevant skills by name" "${TMP_DIR}/codex/skills/writing-plans/SKILL.md"
grep -q "spawn_agent" "${TMP_DIR}/codex/skills/brainstorming/spec-document-reviewer-prompt.md"
grep -q "spawn_agent" "${TMP_DIR}/codex/skills/writing-plans/plan-document-reviewer-prompt.md"

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
    "hooks/hooks\\.json"
do
    if rg -n "$pattern" -S "${TMP_DIR}/codex" >/dev/null; then
        echo "Codex bundle still contains forbidden pattern: $pattern" >&2
        exit 1
    fi
done

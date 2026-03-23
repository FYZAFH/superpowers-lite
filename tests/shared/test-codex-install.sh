#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_HOME="$(mktemp -d /tmp/superpowers-lite-codex-home.XXXXXX)"
trap 'rm -rf "$TEST_HOME"' EXIT

CODEX_HOME_DIR="${TEST_HOME}/custom-config/.codex"

mkdir -p "${CODEX_HOME_DIR}"
cat > "${CODEX_HOME_DIR}/AGENTS.md" <<'EOF'
Keep this line.
EOF

HOME="$TEST_HOME" CODEX_HOME="${CODEX_HOME_DIR}" "${REPO_ROOT}/scripts/install-codex.sh"

test -f "${CODEX_HOME_DIR}/AGENTS.md"
grep -q "Keep this line." "${CODEX_HOME_DIR}/AGENTS.md"
grep -q "<!-- superpowers-lite:start -->" "${CODEX_HOME_DIR}/AGENTS.md"
grep -q "Codex's native skills system" "${CODEX_HOME_DIR}/AGENTS.md"
test -d "${TEST_HOME}/.agents/skills/brainstorming"
test -d "${TEST_HOME}/.agents/skills/code-review"
grep -qx 'superpowers-lite' "${TEST_HOME}/.agents/skills/brainstorming/.superpowers-lite-owner"
grep -q 'agent_type: implementer' "${TEST_HOME}/.agents/skills/subagent-driven-development/SKILL.md"
test -f "${CODEX_HOME_DIR}/agents/implementer.toml"
test -f "${CODEX_HOME_DIR}/agents/spec-reviewer.toml"
grep -q '^# superpowers-lite:managed$' "${CODEX_HOME_DIR}/agents/implementer.toml"

HOME="$TEST_HOME" CODEX_HOME="${CODEX_HOME_DIR}" "${REPO_ROOT}/scripts/uninstall-codex.sh"

if [ -e "${TEST_HOME}/.agents/skills/brainstorming" ]; then
    echo "brainstorming skill still exists after uninstall" >&2
    exit 1
fi

if [ -e "${CODEX_HOME_DIR}/agents/implementer.toml" ]; then
    echo "implementer subagent still exists after uninstall" >&2
    exit 1
fi

grep -q "Keep this line." "${CODEX_HOME_DIR}/AGENTS.md"
if grep -q "superpowers-lite:start" "${CODEX_HOME_DIR}/AGENTS.md"; then
    echo "managed AGENTS block still exists after uninstall" >&2
    exit 1
fi

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_HOME="$(mktemp -d /tmp/superpowers-lite-codex-python-home.XXXXXX)"
trap 'rm -rf "$TEST_HOME"' EXIT

CODEX_HOME_DIR="${TEST_HOME}/custom-config/.codex"
SKILLS_ROOT="${TEST_HOME}/.agents/skills"
AGENTS_ROOT="${CODEX_HOME_DIR}/agents"
mkdir -p "$CODEX_HOME_DIR"

cat > "${CODEX_HOME_DIR}/AGENTS.md" <<'EOF'
Keep this line.
EOF

HOME="$TEST_HOME" python3 "${REPO_ROOT}/scripts/codex_installer.py" install-global \
    --repo-root "${REPO_ROOT}" \
    --codex-home "${CODEX_HOME_DIR}"

test -f "${CODEX_HOME_DIR}/AGENTS.md"
grep -q "Keep this line." "${CODEX_HOME_DIR}/AGENTS.md"
grep -q "<!-- superpowers-lite:start -->" "${CODEX_HOME_DIR}/AGENTS.md"
grep -q "Codex's native skills system" "${CODEX_HOME_DIR}/AGENTS.md"
test -d "${SKILLS_ROOT}/brainstorming"
test -d "${SKILLS_ROOT}/code-review"
grep -qx 'superpowers-lite' "${SKILLS_ROOT}/brainstorming/.superpowers-lite-owner"
test -f "${AGENTS_ROOT}/implementer.toml"
test -f "${AGENTS_ROOT}/spec-reviewer.toml"
grep -q '^# superpowers-lite:managed$' "${AGENTS_ROOT}/implementer.toml"

HOME="$TEST_HOME" python3 "${REPO_ROOT}/scripts/codex_installer.py" uninstall-global \
    --codex-home "${CODEX_HOME_DIR}"

if [ -e "${SKILLS_ROOT}/brainstorming" ]; then
    echo "brainstorming skill still exists after uninstall" >&2
    exit 1
fi

if [ -e "${AGENTS_ROOT}/implementer.toml" ]; then
    echo "implementer subagent still exists after uninstall" >&2
    exit 1
fi

grep -q "Keep this line." "${CODEX_HOME_DIR}/AGENTS.md"
if grep -q "superpowers-lite:start" "${CODEX_HOME_DIR}/AGENTS.md"; then
    echo "managed AGENTS block still exists after uninstall" >&2
    exit 1
fi

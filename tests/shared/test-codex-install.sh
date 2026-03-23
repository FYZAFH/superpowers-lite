#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_HOME="$(mktemp -d /tmp/superpowers-lite-codex-home.XXXXXX)"
trap 'rm -rf "$TEST_HOME"' EXIT

mkdir -p "${TEST_HOME}/.codex"
cat > "${TEST_HOME}/.codex/AGENTS.md" <<'EOF'
Keep this line.
EOF

HOME="$TEST_HOME" CODEX_HOME="${TEST_HOME}/.codex" "${REPO_ROOT}/scripts/install-codex.sh"

test -f "${TEST_HOME}/.codex/AGENTS.md"
grep -q "Keep this line." "${TEST_HOME}/.codex/AGENTS.md"
grep -q "<!-- superpowers-lite:start -->" "${TEST_HOME}/.codex/AGENTS.md"
grep -q "Codex's native skills system" "${TEST_HOME}/.codex/AGENTS.md"
test -L "${TEST_HOME}/.codex/skills/brainstorming"
test -L "${TEST_HOME}/.codex/skills/code-review"
grep -q "${TEST_HOME}/.codex/vendor_imports/superpowers-lite/agents/implementer.md" \
    "${TEST_HOME}/.codex/vendor_imports/superpowers-lite/skills/subagent-driven-development/SKILL.md"

HOME="$TEST_HOME" CODEX_HOME="${TEST_HOME}/.codex" "${REPO_ROOT}/scripts/uninstall-codex.sh"

if [ -e "${TEST_HOME}/.codex/skills/brainstorming" ]; then
    echo "brainstorming symlink still exists after uninstall" >&2
    exit 1
fi

if [ -d "${TEST_HOME}/.codex/vendor_imports/superpowers-lite" ]; then
    echo "install root still exists after uninstall" >&2
    exit 1
fi

grep -q "Keep this line." "${TEST_HOME}/.codex/AGENTS.md"
if grep -q "superpowers-lite:start" "${TEST_HOME}/.codex/AGENTS.md"; then
    echo "managed AGENTS block still exists after uninstall" >&2
    exit 1
fi

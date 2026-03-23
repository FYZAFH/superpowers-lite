#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/superpowers-lite-codex-bootstrap-global.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

TEST_HOME="${TEST_ROOT}/home"
SOURCE_REPO="${TEST_ROOT}/source-repo"
CACHE_DIR="${TEST_ROOT}/cache/repo"
mkdir -p "${TEST_HOME}/.codex" "$SOURCE_REPO"

cat > "${TEST_HOME}/.codex/AGENTS.md" <<'EOF'
Keep this line.
EOF

cp -R "${REPO_ROOT}/." "${SOURCE_REPO}"
rm -rf "${SOURCE_REPO}/.git"
git -C "$SOURCE_REPO" init >/dev/null 2>&1
git -C "$SOURCE_REPO" config user.name test >/dev/null 2>&1
git -C "$SOURCE_REPO" config user.email test@example.com >/dev/null 2>&1
git -C "$SOURCE_REPO" add . >/dev/null 2>&1
git -C "$SOURCE_REPO" commit -m "snapshot" >/dev/null 2>&1

HOME="$TEST_HOME" CODEX_HOME="${TEST_HOME}/.codex" "${REPO_ROOT}/scripts/bootstrap-codex-global.sh" \
    --repo-url "$SOURCE_REPO" \
    --checkout-dir "$CACHE_DIR"

test -d "${CACHE_DIR}/.git"
test -f "${TEST_HOME}/.codex/AGENTS.md"
grep -q "Keep this line." "${TEST_HOME}/.codex/AGENTS.md"
grep -q "<!-- superpowers-lite:start -->" "${TEST_HOME}/.codex/AGENTS.md"
grep -q "Codex's native skills system" "${TEST_HOME}/.codex/AGENTS.md"
test -L "${TEST_HOME}/.codex/skills/brainstorming"
test -L "${TEST_HOME}/.codex/skills/code-review"

HOME="$TEST_HOME" CODEX_HOME="${TEST_HOME}/.codex" "${REPO_ROOT}/scripts/uninstall-codex.sh"

if [ -e "${TEST_HOME}/.codex/skills/brainstorming" ]; then
    echo "brainstorming symlink still exists after uninstall" >&2
    exit 1
fi

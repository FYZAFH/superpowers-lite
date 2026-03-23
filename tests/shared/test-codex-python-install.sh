#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_HOME="$(mktemp -d /tmp/superpowers-lite-codex-python-home.XXXXXX)"
trap 'rm -rf "$TEST_HOME"' EXIT

CODEX_HOME_DIR="${TEST_HOME}/.codex"
INSTALL_ROOT="${CODEX_HOME_DIR}/vendor_imports/superpowers-lite"
mkdir -p "$CODEX_HOME_DIR"

assert_managed_skill_target() {
    local skill_name="$1"
    local target="${CODEX_HOME_DIR}/skills/${skill_name}"
    local source="${INSTALL_ROOT}/skills/${skill_name}"

    if [ -L "$target" ]; then
        [ "$(readlink "$target")" = "$source" ]
        return 0
    fi

    if [ -d "$target" ]; then
        grep -qx "$source" "${target}/.superpowers-lite-owner"
        return 0
    fi

    echo "managed skill target missing: $target" >&2
    exit 1
}

cat > "${CODEX_HOME_DIR}/AGENTS.md" <<'EOF'
Keep this line.
EOF

python3 "${REPO_ROOT}/scripts/codex_installer.py" install-global \
    --repo-root "${REPO_ROOT}" \
    --codex-home "${CODEX_HOME_DIR}"

test -f "${CODEX_HOME_DIR}/AGENTS.md"
grep -q "Keep this line." "${CODEX_HOME_DIR}/AGENTS.md"
grep -q "<!-- superpowers-lite:start -->" "${CODEX_HOME_DIR}/AGENTS.md"
grep -q "Codex's native skills system" "${CODEX_HOME_DIR}/AGENTS.md"
assert_managed_skill_target brainstorming
assert_managed_skill_target code-review
grep -q "${INSTALL_ROOT}/agents/implementer.md" \
    "${INSTALL_ROOT}/skills/subagent-driven-development/SKILL.md"

python3 "${REPO_ROOT}/scripts/codex_installer.py" uninstall-global \
    --codex-home "${CODEX_HOME_DIR}"

if [ -e "${CODEX_HOME_DIR}/skills/brainstorming" ]; then
    echo "brainstorming target still exists after uninstall" >&2
    exit 1
fi

if [ -d "${INSTALL_ROOT}" ]; then
    echo "install root still exists after uninstall" >&2
    exit 1
fi

grep -q "Keep this line." "${CODEX_HOME_DIR}/AGENTS.md"
if grep -q "superpowers-lite:start" "${CODEX_HOME_DIR}/AGENTS.md"; then
    echo "managed AGENTS block still exists after uninstall" >&2
    exit 1
fi

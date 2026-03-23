#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/superpowers-lite-codex-python-project.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

TEST_HOME="${TEST_ROOT}/home"
PROJECT_ROOT="${TEST_ROOT}/example_sound"
FAKE_BIN="${TEST_ROOT}/bin"
ARTIFACT_ROOT="${PROJECT_ROOT}/.superpowers-lite"
CODEX_HOME_DIR="${ARTIFACT_ROOT}/codex-home"
INSTALL_ROOT="${CODEX_HOME_DIR}/vendor_imports/superpowers-lite"
mkdir -p "${TEST_HOME}/.codex" "$PROJECT_ROOT" "$FAKE_BIN"

assert_link_or_copy_file() {
    local source="$1"
    local destination="$2"

    if [ -L "$destination" ]; then
        [ "$(readlink "$destination")" = "$source" ]
        return 0
    fi

    cmp -s "$source" "$destination"
}

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

cat > "${TEST_HOME}/.codex/config.toml" <<'EOF'
model_provider = "test"
EOF

cat > "${TEST_HOME}/.codex/auth.json" <<'EOF'
{"token":"test"}
EOF

cat > "${FAKE_BIN}/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'PWD=%s\n' "$PWD"
printf 'CODEX_HOME=%s\n' "${CODEX_HOME:-}"
printf 'ARGS=%s\n' "$*"
EOF
chmod +x "${FAKE_BIN}/codex"

git -C "$PROJECT_ROOT" init >/dev/null 2>&1

HOME="$TEST_HOME" python3 "${REPO_ROOT}/scripts/codex_installer.py" install-project \
    --repo-root "${REPO_ROOT}" \
    --project-root "${PROJECT_ROOT}"

test -x "${ARTIFACT_ROOT}/codex"
test -x "${ARTIFACT_ROOT}/uninstall"
test -f "${ARTIFACT_ROOT}/codex.cmd"
test -f "${ARTIFACT_ROOT}/codex.ps1"
test -f "${ARTIFACT_ROOT}/uninstall.cmd"
test -f "${ARTIFACT_ROOT}/uninstall.ps1"
assert_link_or_copy_file "${TEST_HOME}/.codex/config.toml" "${CODEX_HOME_DIR}/config.toml"
assert_link_or_copy_file "${TEST_HOME}/.codex/auth.json" "${CODEX_HOME_DIR}/auth.json"
test -f "${CODEX_HOME_DIR}/AGENTS.md"
grep -q "Codex's native skills system" "${CODEX_HOME_DIR}/AGENTS.md"
assert_managed_skill_target brainstorming
assert_managed_skill_target code-review
grep -q "${INSTALL_ROOT}/agents/implementer.md" \
    "${INSTALL_ROOT}/skills/subagent-driven-development/SKILL.md"
grep -q "# superpowers-lite:start" "${PROJECT_ROOT}/.git/info/exclude"
grep -q ".superpowers-lite/" "${PROJECT_ROOT}/.git/info/exclude"

launcher_output="$(PATH="${FAKE_BIN}:$PATH" "${ARTIFACT_ROOT}/codex" hello world)"
printf '%s\n' "$launcher_output" | grep -q "^PWD=${PROJECT_ROOT}\$"
printf '%s\n' "$launcher_output" | grep -q "^CODEX_HOME=${CODEX_HOME_DIR}\$"
printf '%s\n' "$launcher_output" | grep -q "^ARGS=hello world\$"

generated_uninstall_output="$("${ARTIFACT_ROOT}/uninstall" 2>&1)"
printf '%s\n' "$generated_uninstall_output" | grep -q "Removing project-local Superpowers Lite"

if [ -e "${ARTIFACT_ROOT}" ]; then
    echo ".superpowers-lite still exists after generated uninstall" >&2
    exit 1
fi

if grep -q "superpowers-lite:start" "${PROJECT_ROOT}/.git/info/exclude"; then
    echo "managed exclude block still exists after generated uninstall" >&2
    exit 1
fi

HOME="$TEST_HOME" python3 "${REPO_ROOT}/scripts/codex_installer.py" install-project \
    --repo-root "${REPO_ROOT}" \
    --project-root "${PROJECT_ROOT}"

HOME="$TEST_HOME" python3 "${REPO_ROOT}/scripts/codex_installer.py" uninstall-project \
    --project-root "${PROJECT_ROOT}"

if [ -e "${ARTIFACT_ROOT}" ]; then
    echo ".superpowers-lite still exists after uninstall" >&2
    exit 1
fi

if grep -q "superpowers-lite:start" "${PROJECT_ROOT}/.git/info/exclude"; then
    echo "managed exclude block still exists after uninstall" >&2
    exit 1
fi

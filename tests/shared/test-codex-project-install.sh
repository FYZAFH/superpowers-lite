#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/superpowers-lite-codex-project.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

TEST_HOME="${TEST_ROOT}/home"
PROJECT_ROOT="${TEST_ROOT}/example_sound"
FAKE_BIN="${TEST_ROOT}/bin"
mkdir -p "${TEST_HOME}/.codex" "$PROJECT_ROOT" "$FAKE_BIN"

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

HOME="$TEST_HOME" PATH="${FAKE_BIN}:$PATH" "${REPO_ROOT}/scripts/install-codex-project.sh" --project-root "$PROJECT_ROOT"

test -x "${PROJECT_ROOT}/.superpowers-lite/codex"
test -x "${PROJECT_ROOT}/.superpowers-lite/uninstall"
test -L "${PROJECT_ROOT}/.superpowers-lite/codex-home/config.toml"
test -L "${PROJECT_ROOT}/.superpowers-lite/codex-home/auth.json"
test -f "${PROJECT_ROOT}/.superpowers-lite/codex-home/AGENTS.md"
grep -q "Codex's native skills system" "${PROJECT_ROOT}/.superpowers-lite/codex-home/AGENTS.md"
grep -q "${PROJECT_ROOT}/.superpowers-lite/codex-home/vendor_imports/superpowers-lite/agents/implementer.md" \
    "${PROJECT_ROOT}/.superpowers-lite/codex-home/vendor_imports/superpowers-lite/skills/subagent-driven-development/SKILL.md"
grep -q "# superpowers-lite:start" "${PROJECT_ROOT}/.git/info/exclude"
grep -q ".superpowers-lite/" "${PROJECT_ROOT}/.git/info/exclude"

launcher_output="$(PATH="${FAKE_BIN}:$PATH" "${PROJECT_ROOT}/.superpowers-lite/codex" hello world)"
printf '%s\n' "$launcher_output" | grep -q "^PWD=${PROJECT_ROOT}\$"
printf '%s\n' "$launcher_output" | grep -q "^CODEX_HOME=${PROJECT_ROOT}/.superpowers-lite/codex-home\$"
printf '%s\n' "$launcher_output" | grep -q "^ARGS=hello world\$"

generated_uninstall_output="$("${PROJECT_ROOT}/.superpowers-lite/uninstall" 2>&1)"
printf '%s\n' "$generated_uninstall_output" | grep -q "Removing project-local Superpowers Lite"

if [ -e "${PROJECT_ROOT}/.superpowers-lite" ]; then
    echo ".superpowers-lite still exists after generated uninstall" >&2
    exit 1
fi

if grep -q "superpowers-lite:start" "${PROJECT_ROOT}/.git/info/exclude"; then
    echo "managed exclude block still exists after generated uninstall" >&2
    exit 1
fi

HOME="$TEST_HOME" PATH="${FAKE_BIN}:$PATH" "${REPO_ROOT}/scripts/install-codex-project.sh" --project-root "$PROJECT_ROOT"

HOME="$TEST_HOME" "${REPO_ROOT}/scripts/uninstall-codex-project.sh" --project-root "$PROJECT_ROOT"

if [ -e "${PROJECT_ROOT}/.superpowers-lite" ]; then
    echo ".superpowers-lite still exists after uninstall" >&2
    exit 1
fi

if grep -q "superpowers-lite:start" "${PROJECT_ROOT}/.git/info/exclude"; then
    echo "managed exclude block still exists after uninstall" >&2
    exit 1
fi

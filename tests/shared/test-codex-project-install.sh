#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/superpowers-lite-codex-project.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

PROJECT_ROOT="${TEST_ROOT}/example_sound"
mkdir -p "$PROJECT_ROOT"

git -C "$PROJECT_ROOT" init >/dev/null 2>&1
cat > "${PROJECT_ROOT}/AGENTS.md" <<'EOF'
Keep this line.
EOF

"${REPO_ROOT}/scripts/install-codex-project.sh" --project-root "$PROJECT_ROOT"

test -f "${PROJECT_ROOT}/AGENTS.md"
grep -q "Keep this line." "${PROJECT_ROOT}/AGENTS.md"
grep -q "<!-- superpowers-lite:start -->" "${PROJECT_ROOT}/AGENTS.md"
test -d "${PROJECT_ROOT}/.agents/skills/brainstorming"
test -d "${PROJECT_ROOT}/.agents/skills/code-review"
grep -qx 'superpowers-lite' "${PROJECT_ROOT}/.agents/skills/brainstorming/.superpowers-lite-owner"
test -f "${PROJECT_ROOT}/.codex/agents/implementer.toml"
test -f "${PROJECT_ROOT}/.codex/agents/spec-reviewer.toml"
test -x "${PROJECT_ROOT}/.superpowers-lite/uninstall"
test -f "${PROJECT_ROOT}/.superpowers-lite/uninstall.cmd"
test -f "${PROJECT_ROOT}/.superpowers-lite/uninstall.ps1"
grep -q "# superpowers-lite:start" "${PROJECT_ROOT}/.git/info/exclude"
grep -q ".superpowers-lite/" "${PROJECT_ROOT}/.git/info/exclude"

generated_uninstall_output="$("${PROJECT_ROOT}/.superpowers-lite/uninstall" 2>&1)"
printf '%s\n' "$generated_uninstall_output" | grep -q "Removing project-local Superpowers Lite helpers"

if [ -e "${PROJECT_ROOT}/.agents/skills/brainstorming" ]; then
    echo "brainstorming skill still exists after generated uninstall" >&2
    exit 1
fi

if [ -e "${PROJECT_ROOT}/.codex/agents/implementer.toml" ]; then
    echo "implementer subagent still exists after generated uninstall" >&2
    exit 1
fi

grep -q "Keep this line." "${PROJECT_ROOT}/AGENTS.md"
if grep -q "superpowers-lite:start" "${PROJECT_ROOT}/AGENTS.md"; then
    echo "managed AGENTS block still exists after generated uninstall" >&2
    exit 1
fi

if [ -e "${PROJECT_ROOT}/.superpowers-lite" ]; then
    echo ".superpowers-lite still exists after generated uninstall" >&2
    exit 1
fi

if grep -q "superpowers-lite:start" "${PROJECT_ROOT}/.git/info/exclude"; then
    echo "managed exclude block still exists after generated uninstall" >&2
    exit 1
fi

"${REPO_ROOT}/scripts/install-codex-project.sh" --project-root "$PROJECT_ROOT"
"${REPO_ROOT}/scripts/uninstall-codex-project.sh" --project-root "$PROJECT_ROOT"

if [ -e "${PROJECT_ROOT}/.agents/skills/brainstorming" ]; then
    echo "brainstorming skill still exists after uninstall" >&2
    exit 1
fi

if [ -e "${PROJECT_ROOT}/.codex/agents/implementer.toml" ]; then
    echo "implementer subagent still exists after uninstall" >&2
    exit 1
fi

if [ -e "${PROJECT_ROOT}/.superpowers-lite" ]; then
    echo ".superpowers-lite still exists after uninstall" >&2
    exit 1
fi

if grep -q "superpowers-lite:start" "${PROJECT_ROOT}/AGENTS.md"; then
    echo "managed AGENTS block still exists after uninstall" >&2
    exit 1
fi

if grep -q "superpowers-lite:start" "${PROJECT_ROOT}/.git/info/exclude"; then
    echo "managed exclude block still exists after uninstall" >&2
    exit 1
fi

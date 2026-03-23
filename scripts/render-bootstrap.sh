#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILL_PATH="${REPO_ROOT}/skills/using-superpowers/SKILL.md"
OUTPUT_PATH="${1:-${REPO_ROOT}/bootstrap.md}"

if [ ! -f "$SKILL_PATH" ]; then
    echo "render-bootstrap.sh: missing skill file: $SKILL_PATH" >&2
    exit 1
fi

{
    printf '%s\n' '<EXTREMELY_IMPORTANT>'
    printf '%s\n' 'You have superpowers.'
    printf '\n'
    printf '%s\n' "**Below is the full content of your 'superpowers-lite:using-superpowers' skill - your introduction to using skills. For all other skills, use the 'Skill' tool:**"
    printf '\n'
    cat "$SKILL_PATH"
    printf '\n'
    printf '%s\n' '</EXTREMELY_IMPORTANT>'
} > "$OUTPUT_PATH"

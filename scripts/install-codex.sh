#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CODEX_HOME_DIR="${CODEX_HOME:-${HOME}/.codex}"
INSTALL_ROOT=""
MARKER_START="<!-- superpowers-lite:start -->"
MARKER_END="<!-- superpowers-lite:end -->"

usage() {
    cat <<EOF
Usage: $(basename "$0") [--codex-home PATH] [--install-root PATH]

Installs the Codex-adapted Superpowers Lite bundle into CODEX_HOME and
updates CODEX_HOME/AGENTS.md with a managed block.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --codex-home)
            CODEX_HOME_DIR="${2:?missing path for --codex-home}"
            shift 2
            ;;
        --install-root)
            INSTALL_ROOT="${2:?missing path for --install-root}"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "install-codex.sh: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ -z "$INSTALL_ROOT" ]; then
    INSTALL_ROOT="${CODEX_HOME_DIR}/vendor_imports/superpowers-lite"
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/superpowers-lite-codex.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

STAGING_ROOT="${INSTALL_ROOT}.tmp"

"${REPO_ROOT}/scripts/render-bootstrap.sh"

mkdir -p "${CODEX_HOME_DIR}/skills"
mkdir -p "$(dirname "${INSTALL_ROOT}")"
rm -rf "$STAGING_ROOT"
python3 "${REPO_ROOT}/scripts/render-platform-bundle.py" \
    --platform codex \
    --output "$STAGING_ROOT" \
    --logical-root "$INSTALL_ROOT"

for skill_dir in "${STAGING_ROOT}/skills"/*; do
    skill_name="$(basename "$skill_dir")"
    target="${CODEX_HOME_DIR}/skills/${skill_name}"

    if [ -L "$target" ]; then
        existing_target="$(readlink "$target")"
        case "$existing_target" in
            "${INSTALL_ROOT}"/*) ;;
            *)
                echo "install-codex.sh: refusing to replace existing skill symlink: ${target} -> ${existing_target}" >&2
                exit 1
                ;;
        esac
    elif [ -e "$target" ]; then
        echo "install-codex.sh: refusing to replace existing path: ${target}" >&2
        exit 1
    fi
done

rm -rf "${INSTALL_ROOT}"
mv "${STAGING_ROOT}" "${INSTALL_ROOT}"

for skill_dir in "${INSTALL_ROOT}/skills"/*; do
    skill_name="$(basename "$skill_dir")"
    target="${CODEX_HOME_DIR}/skills/${skill_name}"

    if [ -L "$target" ]; then
        rm "$target"
    fi
    ln -s "$skill_dir" "$target"
done

global_agents="${CODEX_HOME_DIR}/AGENTS.md"
agents_tmp="${TMP_DIR}/AGENTS.cleaned"
if [ -f "$global_agents" ]; then
    awk -v start="$MARKER_START" -v end="$MARKER_END" '
        $0 == start { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "$global_agents" > "$agents_tmp"
else
    : > "$agents_tmp"
fi

{
    cat "$agents_tmp"
    if [ -s "$agents_tmp" ]; then
        printf '\n'
    fi
    printf '%s\n' "$MARKER_START"
    cat "${INSTALL_ROOT}/AGENTS.md"
    printf '%s\n' "$MARKER_END"
} > "$global_agents"

printf 'Installed Codex bundle to %s\n' "$INSTALL_ROOT"
printf 'Linked skills into %s\n' "${CODEX_HOME_DIR}/skills"
printf 'Updated %s with managed Superpowers Lite bootstrap block\n' "$global_agents"

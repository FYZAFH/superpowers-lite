#!/usr/bin/env bash

set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-${HOME}/.codex}"
INSTALL_ROOT=""
MARKER_START="<!-- superpowers-lite:start -->"
MARKER_END="<!-- superpowers-lite:end -->"

usage() {
    cat <<EOF
Usage: $(basename "$0") [--codex-home PATH] [--install-root PATH]

Removes the managed Codex Superpowers Lite installation and AGENTS.md block.
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
            echo "uninstall-codex.sh: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ -z "$INSTALL_ROOT" ]; then
    INSTALL_ROOT="${CODEX_HOME_DIR}/vendor_imports/superpowers-lite"
fi

if [ -d "${INSTALL_ROOT}/skills" ]; then
    for skill_dir in "${INSTALL_ROOT}/skills"/*; do
        [ -e "$skill_dir" ] || continue
        skill_name="$(basename "$skill_dir")"
        target="${CODEX_HOME_DIR}/skills/${skill_name}"
        if [ -L "$target" ]; then
            existing_target="$(readlink "$target")"
            case "$existing_target" in
                "${INSTALL_ROOT}"/*) rm "$target" ;;
            esac
        fi
    done
fi

global_agents="${CODEX_HOME_DIR}/AGENTS.md"
if [ -f "$global_agents" ]; then
    tmp_agents="$(mktemp "${TMPDIR:-/tmp}/superpowers-lite-agents.XXXXXX")"
    trap 'rm -f "$tmp_agents"' EXIT
    awk -v start="$MARKER_START" -v end="$MARKER_END" '
        $0 == start { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "$global_agents" > "$tmp_agents"
    mv "$tmp_agents" "$global_agents"
fi

rm -rf "$INSTALL_ROOT"

printf 'Removed Codex bundle from %s\n' "$INSTALL_ROOT"
printf 'Removed managed Superpowers Lite bootstrap block from %s\n' "$global_agents"

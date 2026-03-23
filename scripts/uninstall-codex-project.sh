#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(pwd)"
ARTIFACT_ROOT=""
CODEX_HOME_DIR=""
LAUNCHER_PATH=""
EXCLUDE_MARKER_START="# superpowers-lite:start"
EXCLUDE_MARKER_END="# superpowers-lite:end"

usage() {
    cat <<EOF
Usage: $(basename "$0") [--project-root PATH] [--artifact-root PATH] [--codex-home PATH] [--launcher PATH]

Removes the project-local Codex home and launcher created by
install-codex-project.sh.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --project-root)
            PROJECT_ROOT="${2:?missing path for --project-root}"
            shift 2
            ;;
        --artifact-root)
            ARTIFACT_ROOT="${2:?missing path for --artifact-root}"
            shift 2
            ;;
        --codex-home)
            CODEX_HOME_DIR="${2:?missing path for --codex-home}"
            shift 2
            ;;
        --launcher)
            LAUNCHER_PATH="${2:?missing path for --launcher}"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "uninstall-codex-project.sh: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
if [ -z "$ARTIFACT_ROOT" ]; then
    ARTIFACT_ROOT="${PROJECT_ROOT}/.superpowers-lite"
fi
if [ -z "$CODEX_HOME_DIR" ]; then
    CODEX_HOME_DIR="${ARTIFACT_ROOT}/codex-home"
fi
if [ -z "$LAUNCHER_PATH" ]; then
    LAUNCHER_PATH="${ARTIFACT_ROOT}/codex"
fi

remove_git_exclude() {
    if ! git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return 0
    fi

    local exclude_file
    local tmp_file
    exclude_file="$(cd "$PROJECT_ROOT" && git rev-parse --git-path info/exclude)"
    case "$exclude_file" in
        /*) ;;
        *) exclude_file="${PROJECT_ROOT}/${exclude_file}" ;;
    esac

    if [ ! -f "$exclude_file" ]; then
        return 0
    fi

    tmp_file="$(mktemp "${TMPDIR:-/tmp}/superpowers-lite-exclude.XXXXXX")"
    awk -v start="$EXCLUDE_MARKER_START" -v end="$EXCLUDE_MARKER_END" '
        $0 == start { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "$exclude_file" > "$tmp_file"
    mv "$tmp_file" "$exclude_file"
}

if [ -d "$CODEX_HOME_DIR" ]; then
    "${REPO_ROOT}/scripts/uninstall-codex.sh" --codex-home "$CODEX_HOME_DIR"
fi

if [ "$LAUNCHER_PATH" != "${ARTIFACT_ROOT}/codex" ] && [ -e "$LAUNCHER_PATH" ]; then
    rm -f "$LAUNCHER_PATH"
fi

rm -rf "$ARTIFACT_ROOT"
remove_git_exclude

printf 'Removed project-local Codex home from %s\n' "$CODEX_HOME_DIR"
printf 'Removed project launcher at %s\n' "$LAUNCHER_PATH"

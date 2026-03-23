#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TMP_OUTPUT="$(mktemp /tmp/superpowers-lite-bootstrap.XXXXXX)"
trap 'rm -f "$TMP_OUTPUT"' EXIT

"${REPO_ROOT}/scripts/render-bootstrap.sh" "$TMP_OUTPUT"
diff -u "${REPO_ROOT}/bootstrap.md" "$TMP_OUTPUT"

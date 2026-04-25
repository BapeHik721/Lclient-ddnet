#!/usr/bin/env bash

# Carefully update local sources from RushieClient upstream and preserve
# selected local custom files during merge conflicts.
#
# Default upstream:
#   https://github.com/RushieClient/RushieClient-ddnet.git (master)
#
# Usage examples:
#   scripts/update_from_rushie_upstream.sh
#   scripts/update_from_rushie_upstream.sh --upstream-branch master
#   scripts/update_from_rushie_upstream.sh --keep-file src/game/client/components/controls.cpp

set -euo pipefail

UPSTREAM_URL="https://github.com/RushieClient/RushieClient-ddnet.git"
UPSTREAM_REMOTE="rushie-upstream"
UPSTREAM_BRANCH="master"
AUTO_COMMIT=1

# Files where local custom behavior is usually intentional.
# If these files conflict during merge, this script keeps local ("ours") version.
KEEP_OURS_FILES=(
  "src/game/client/components/controls.cpp"
  "src/game/client/components/controls.h"
  "src/game/client/components/lclient/menus_lclient.cpp"
  "src/engine/shared/config_variables_tclient.h"
)

print_usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  --upstream-url <url>        Upstream git URL (default: ${UPSTREAM_URL})"
  echo "  --upstream-remote <name>    Upstream remote name (default: ${UPSTREAM_REMOTE})"
  echo "  --upstream-branch <name>    Upstream branch (default: ${UPSTREAM_BRANCH})"
  echo "  --keep-file <path>          Add extra file to always keep from local branch"
  echo "  --no-auto-commit            Do not create merge commit automatically"
  echo "  -h, --help                  Show help"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --upstream-url)
      UPSTREAM_URL="$2"
      shift 2
      ;;
    --upstream-remote)
      UPSTREAM_REMOTE="$2"
      shift 2
      ;;
    --upstream-branch)
      UPSTREAM_BRANCH="$2"
      shift 2
      ;;
    --keep-file)
      KEEP_OURS_FILES+=("$2")
      shift 2
      ;;
    --no-auto-commit)
      AUTO_COMMIT=0
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      print_usage
      exit 1
      ;;
  esac
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: run this script inside a git repository." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: working tree is not clean." >&2
  echo "Commit/stash your changes first, then run again." >&2
  exit 1
fi

CURRENT_BRANCH="$(git symbolic-ref --quiet --short HEAD || true)"
if [[ -z "${CURRENT_BRANCH}" ]]; then
  echo "Error: detached HEAD is not supported for safe update." >&2
  exit 1
fi

if git remote get-url "${UPSTREAM_REMOTE}" >/dev/null 2>&1; then
  git remote set-url "${UPSTREAM_REMOTE}" "${UPSTREAM_URL}"
else
  git remote add "${UPSTREAM_REMOTE}" "${UPSTREAM_URL}"
fi

echo "Fetching upstream (${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH})..."
git fetch --prune "${UPSTREAM_REMOTE}" "${UPSTREAM_BRANCH}"

if ! git show-ref --verify --quiet "refs/remotes/${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}"; then
  echo "Error: upstream branch not found: ${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}" >&2
  exit 1
fi

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_BRANCH="backup/pre-upstream-${TS}"
UPDATE_BRANCH="update/upstream-${TS}"

echo "Creating safety backup branch: ${BACKUP_BRANCH}"
git branch "${BACKUP_BRANCH}" "${CURRENT_BRANCH}"

echo "Creating update branch: ${UPDATE_BRANCH}"
git switch -c "${UPDATE_BRANCH}" "${CURRENT_BRANCH}"

set +e
git merge --no-ff --no-commit "${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}"
MERGE_EXIT=$?
set -e

if [[ ${MERGE_EXIT} -ne 0 ]]; then
  echo "Merge reported conflicts. Trying to keep local versions for protected files..."
fi

for file in "${KEEP_OURS_FILES[@]}"; do
  if git ls-files -u -- "${file}" | rg "." >/dev/null; then
    echo "Keeping local version: ${file}"
    git checkout --ours -- "${file}"
    git add -- "${file}"
  fi
done

if git diff --name-only --diff-filter=U | rg "." >/dev/null; then
  echo
  echo "Unresolved conflicts remain. Resolve manually, then commit."
  echo "Current branch: ${UPDATE_BRANCH}"
  echo "Safety branch:  ${BACKUP_BRANCH}"
  echo
  git status --short
  exit 2
fi

if [[ ${AUTO_COMMIT} -eq 1 ]]; then
  git commit -m "Merge ${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH} into ${CURRENT_BRANCH}

- fetched latest upstream sources
- preserved local custom files on conflict
- created by scripts/update_from_rushie_upstream.sh"
  echo
  echo "Update complete."
  echo "Branch: ${UPDATE_BRANCH}"
  echo "Backup: ${BACKUP_BRANCH}"
else
  echo
  echo "Merge staged but not committed (--no-auto-commit)."
  echo "Branch: ${UPDATE_BRANCH}"
  echo "Backup: ${BACKUP_BRANCH}"
  git status --short
fi

#!/usr/bin/env bash

# Safe helper for committing and pushing current branch to GitHub.
#
# Usage:
#   scripts/push_to_github.sh
#   scripts/push_to_github.sh --branch master
#   scripts/push_to_github.sh --message "update workflows"
#   scripts/push_to_github.sh --skip-commit

set -euo pipefail

TARGET_BRANCH=""
COMMIT_MESSAGE=""
SKIP_COMMIT=0

print_usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  --branch <name>       Push target branch (default: current branch)"
  echo "  --message <text>      Commit message (if there are unstaged changes)"
  echo "  --skip-commit         Do not auto-commit changes before push"
  echo "  -h, --help            Show help"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)
      TARGET_BRANCH="$2"
      shift 2
      ;;
    --message)
      COMMIT_MESSAGE="$2"
      shift 2
      ;;
    --skip-commit)
      SKIP_COMMIT=1
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

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "Error: remote 'origin' is not configured." >&2
  exit 1
fi

CURRENT_BRANCH="$(git symbolic-ref --quiet --short HEAD || true)"
if [[ -z "${CURRENT_BRANCH}" ]]; then
  echo "Error: detached HEAD is not supported." >&2
  exit 1
fi

if [[ -z "${TARGET_BRANCH}" ]]; then
  TARGET_BRANCH="${CURRENT_BRANCH}"
fi

if [[ ${SKIP_COMMIT} -eq 0 ]] && [[ -n "$(git status --porcelain)" ]]; then
  if [[ -z "${COMMIT_MESSAGE}" ]]; then
    COMMIT_MESSAGE="chore: update local changes"
  fi
  echo "Staging and committing local changes..."
  git add -A
  if [[ -n "$(git diff --cached --name-only)" ]]; then
    git commit -m "${COMMIT_MESSAGE}"
  fi
fi

echo "Pushing ${CURRENT_BRANCH} -> origin/${TARGET_BRANCH} ..."
git push -u origin "${CURRENT_BRANCH}:${TARGET_BRANCH}"
echo "Done."

#!/bin/bash
# Owner-only usage proxy: there's no install-count API for Claude Code
# plugins, so this pulls the closest real signal from GitHub instead.
# Traffic data (clone/view counts) needs push access and only covers the
# last 14 days; stars/forks are public and unlimited history.
set -e
REPO="${1:-Samanyu-dev/pr-preflight}"

echo "== $REPO =="
gh api "repos/$REPO" --jq '"Stars: \(.stargazers_count)  Forks: \(.forks_count)  Watchers: \(.subscribers_count)"'

echo
echo "-- Clones (last 14 days) --"
gh api "repos/$REPO/traffic/clones" --jq '"Total: \(.count)  Unique: \(.uniques)"'

echo
echo "-- Views (last 14 days) --"
gh api "repos/$REPO/traffic/views" --jq '"Total: \(.count)  Unique: \(.uniques)"'

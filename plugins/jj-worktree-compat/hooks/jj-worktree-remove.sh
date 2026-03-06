#!/usr/bin/env bash
set -euo pipefail

# WorktreeRemove hook for jj workspaces.
# Input: JSON on stdin with { worktree_path, cwd, ... }
# Output: ignored (just exit 0 on success)

input=$(cat)
worktree_path=$(echo "$input" | jq -r '.worktree_path')
name=$(basename "$worktree_path")

# Serialize against the same lock used by WorktreeCreate to avoid
# racing a create with a concurrent remove on jj repo state.
worktree_base="$HOME/.claude/worktrees"
lockfile="$worktree_base/.jj-workspace-create.lock"
mkdir -p "$worktree_base"
exec 9>"$lockfile"
flock -x 9

# Forget the workspace from within it (jj allows self-forget).
# If the .jj link is broken or the repo is gone, skip gracefully.
if [ -d "$worktree_path/.jj" ]; then
  (cd "$worktree_path" && jj workspace forget "$name" 2>/dev/null) || true
fi

rm -rf "$worktree_path"

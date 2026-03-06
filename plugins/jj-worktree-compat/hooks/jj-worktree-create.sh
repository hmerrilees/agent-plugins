#!/usr/bin/env bash
set -euo pipefail

# WorktreeCreate hook for jj workspaces.
# Input: JSON on stdin with { name, cwd, ... }
# Output: absolute path to created workspace directory on stdout

input=$(cat)
name=$(echo "$input" | jq -r '.name')
cwd=$(echo "$input" | jq -r '.cwd')

# Find the jj repo root from the session's cwd
repo_root=$(cd "$cwd" && jj root)

# Place workspaces under ~/.claude/worktrees/{name}
worktree_base="$HOME/.claude/worktrees"
dest="$worktree_base/$name"

mkdir -p "$worktree_base"

# Serialize workspace creation across concurrent hook invocations.
# `jj workspace add` takes an internal repo lock, but concurrent callers
# can fail rather than queue — and a failed hook causes Claude Code to
# fall back to the caller's cwd, landing multiple agents in the same
# directory. An exclusive flock around the entire create-or-diagnose
# sequence ensures only one hook mutates jj state at a time.
lockfile="$worktree_base/.jj-workspace-create.lock"
exec 9>"$lockfile"
flock -x 9

# Let `jj workspace add` be the atomic arbiter — it will reject duplicate
# workspace names and fail if the destination directory already exists.
if add_err=$( (cd "$repo_root" && jj workspace add "$dest" --name "$name") 2>&1 ); then
  echo "$dest"
  exit 0
fi

# Creation failed — diagnose whether this is a live workspace or a stale leftover.
workspace_tracked=false
if (cd "$repo_root" && jj workspace list 2>/dev/null) | grep -q "^${name}: "; then
  workspace_tracked=true
fi

# jj still tracks the workspace — it's occupied. Refuse to clobber.
if [ "$workspace_tracked" = true ]; then
  echo "error: workspace '$name' is already active — refusing to clobber" >&2
  exit 1
fi

# Directory exists but jj doesn't track the workspace — stale leftover.
# Safe to remove the directory and retry.
if [ -d "$dest" ]; then
  rm -rf "$dest"
  (cd "$repo_root" && jj workspace add "$dest" --name "$name") >&2
  echo "$dest"
  exit 0
fi

# Unknown failure — surface the original error.
echo "error: failed to create workspace '$name'" >&2
echo "$add_err" >&2
exit 1

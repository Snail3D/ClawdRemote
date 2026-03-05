#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <target-dir> [-- <extra claude args...>]" >&2
  exit 2
fi

target_dir="$1"
shift

extra_args=()
if [[ ${1-} == "--" ]]; then
  shift
  extra_args=("$@")
fi

if [[ ! -d "$target_dir" ]]; then
  echo "Target directory not found: $target_dir" >&2
  exit 1
fi

cd "$target_dir"
echo "[clawd-remote] cwd: $(pwd)"
echo "[clawd-remote] starting: claude --dangerously-skip-permissions ${extra_args[*]-}"

if (( ${#extra_args[@]} > 0 )); then
  exec claude --dangerously-skip-permissions "${extra_args[@]}"
else
  exec claude --dangerously-skip-permissions
fi

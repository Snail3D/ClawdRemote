#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  start-claude-session.sh [--foreground|--background] <target-dir> [-- <extra claude args...>]
  start-claude-session.sh [--mode foreground|background] <target-dir> [-- <extra claude args...>]

Modes:
  --background   Run Claude in the current PTY (default)
  --foreground   Open a visible macOS Terminal tab/window and launch Claude there

Model default:
  Uses Opus by default via: --model opus
  You can override it by passing your own model after --

Examples:
  start-claude-session.sh /path/to/project
  start-claude-session.sh --background /path/to/project -- --model sonnet
  start-claude-session.sh --foreground /path/to/project
EOF
  exit 2
}

mode="background"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --foreground)
      mode="foreground"
      shift
      ;;
    --background)
      mode="background"
      shift
      ;;
    --mode)
      [[ $# -ge 2 ]] || usage
      case "$2" in
        foreground|background) mode="$2" ;;
        *) echo "Invalid mode: $2" >&2; usage ;;
      esac
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    --)
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      ;;
    *)
      break
      ;;
  esac
done

[[ $# -ge 1 ]] || usage

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

resolved_dir="$(cd "$target_dir" && pwd)"
claude_cmd=(claude --dangerously-skip-permissions --model opus)
if (( ${#extra_args[@]} > 0 )); then
  claude_cmd+=("${extra_args[@]}")
fi

printf -v command_string '%q ' "${claude_cmd[@]}"
command_string="${command_string% }"

echo "[clawd-remote] mode: $mode"
echo "[clawd-remote] cwd: $resolved_dir"
echo "[clawd-remote] starting: $command_string"
echo "[clawd-remote] exit: /exit"

if [[ "$mode" == "background" ]]; then
  cd "$resolved_dir"
  exec "${claude_cmd[@]}"
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Foreground mode currently requires macOS Terminal automation." >&2
  exit 1
fi

quoted_dir=$(printf '%q' "$resolved_dir")
quoted_command=$(printf '%q' "$command_string")
terminal_line="cd $quoted_dir && clear && echo '[clawd-remote] cwd: $resolved_dir' && echo '[clawd-remote] exit with: /exit' && eval $quoted_command"

/usr/bin/osascript <<APPLESCRIPT
set launchCommand to $(printf '%s' "$terminal_line" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
tell application "Terminal"
  activate
  if (count of windows) = 0 then
    do script launchCommand
  else
    do script launchCommand in front window
  end if
end tell
APPLESCRIPT

echo "[clawd-remote] opened visible Terminal session"

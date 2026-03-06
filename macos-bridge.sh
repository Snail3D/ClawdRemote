#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${CLAWDREMOTE_STATE_DIR:-$HOME/.clawdremote}"
REQ="$STATE_DIR/request.json"
RES="$STATE_DIR/last-result.json"
LOG="$STATE_DIR/bridge.log"
mkdir -p "$STATE_DIR"

log() {
  python3 - "$LOG" "$*" <<'PY'
import sys, datetime
path, msg = sys.argv[1], sys.argv[2]
with open(path, 'a') as f:
    f.write(f"{datetime.datetime.now().astimezone().isoformat()} {msg}\n")
PY
}

write_result() {
  local status="$1" project="$2" mode="$3" link="$4" message="$5"
  python3 - "$status" "$project" "$mode" "$link" "$message" "$RES" <<'PY'
import json, sys, datetime
status, project, mode, link, message, path = sys.argv[1:7]
out = {
  "status": status,
  "project": project,
  "mode": mode,
  "remote_control_link": link or None,
  "message": message,
  "updated_at": datetime.datetime.now().astimezone().isoformat(),
}
with open(path, 'w') as f:
    json.dump(out, f, indent=2)
PY
}

[[ -f "$REQ" ]] || exit 0

tmp_parsed="$STATE_DIR/request-parsed.$$"
python3 - "$REQ" "$tmp_parsed" <<'PY'
import json, sys, shlex
req, out = sys.argv[1], sys.argv[2]
with open(req) as f:
    data = json.load(f)
extra = data.get('extra_args', [])
with open(out, 'w') as f:
    f.write((data.get('project', '') or '') + '\n')
    f.write((data.get('mode', 'foreground') or 'foreground') + '\n')
    f.write(('1' if data.get('remote_control', True) else '0') + '\n')
    f.write(str(int(data.get('remote_control_delay_seconds', 5))) + '\n')
    for item in extra:
        if item:
            f.write('ARG=' + str(item) + '\n')
PY

project="$(sed -n '1p' "$tmp_parsed")"
mode="$(sed -n '2p' "$tmp_parsed")"
remote_control="$(sed -n '3p' "$tmp_parsed")"
delay_seconds="$(sed -n '4p' "$tmp_parsed")"
extra_args=()
while IFS= read -r line; do
  case "$line" in
    ARG=*) extra_args+=("${line#ARG=}") ;;
  esac
done < "$tmp_parsed"
rm -f "$tmp_parsed" "$REQ"

if [[ -z "$project" || ! -d "$project" ]]; then
  log "missing project: $project"
  write_result "error" "$project" "$mode" "" "Project directory not found"
  exit 1
fi

claude_bin="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
if [[ ! -x "$claude_bin" ]]; then
  claude_bin="$(command -v claude || true)"
fi
if [[ -z "$claude_bin" ]]; then
  log "claude binary not found"
  write_result "error" "$project" "$mode" "" "Claude binary not found"
  exit 1
fi

if [[ "$remote_control" == "1" ]]; then
  session_name="$(basename "$project")"
  claude_cmd=("$claude_bin" remote-control --permission-mode bypassPermissions --name "$session_name")
else
  claude_cmd=("$claude_bin" --dangerously-skip-permissions --model opus)
fi
if (( ${#extra_args[@]} > 0 )); then
  claude_cmd+=("${extra_args[@]}")
fi
printf -v command_string '%q ' "${claude_cmd[@]}"
command_string="${command_string% }"
terminal_line="cd $(printf '%q' "$project") && clear && echo '[clawd-remote bridge] cwd: $project' && echo '[clawd-remote bridge] exit with: /exit' && eval $command_string"

export CLAWDREMOTE_LAUNCH_COMMAND="$terminal_line"
launch_output="$(/usr/bin/osascript <<'APPLESCRIPT'
on run
  set launchCommand to system attribute "CLAWDREMOTE_LAUNCH_COMMAND"
  tell application "Terminal"
    activate
    set createdTab to do script launchCommand
    delay 0.5
    set winId to id of front window
    return (tty of createdTab as text) & linefeed & (winId as text)
  end tell
end run
APPLESCRIPT
)"
launch_tty="$(printf '%s' "$launch_output" | sed -n '1p')"
launch_window_id="$(printf '%s' "$launch_output" | sed -n '2p')"
log "launched project=$project mode=$mode tty=$launch_tty window=$launch_window_id"

link=""
message="launched"
if [[ "$remote_control" == "1" ]]; then
  sleep "$delay_seconds"
  count=0
  while [[ "$count" -lt 20 ]]; do
    export CLAWDREMOTE_WINDOW_ID="$launch_window_id"
    tab_text="$(/usr/bin/osascript <<'APPLESCRIPT'
on run
  set targetWindowId to system attribute "CLAWDREMOTE_WINDOW_ID"
  tell application "Terminal"
    try
      return contents of window id (targetWindowId as integer)
    on error
      return ""
    end try
  end tell
end run
APPLESCRIPT
)"
    link="$(printf '%s' "$tab_text" | grep -Eo 'https://claude.ai/code/session_[A-Za-z0-9?=._-]+' | tail -1 || true)"
    if [[ -n "$link" ]]; then
      message="remote control active"
      break
    fi
    count=$((count + 1))
    sleep 2
  done
fi

write_result "ok" "$project" "$mode" "$link" "$message"
log "result project=$project link=${link:-none} message=$message"

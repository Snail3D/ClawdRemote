#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  request-remote-launch.sh <project-dir> [--no-remote-control] [--delay SECONDS] [-- <extra claude args...>]
EOF
  exit 2
}

[[ $# -ge 1 ]] || usage
project="$1"
shift
remote_control=true
delay_seconds=5
extra_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-remote-control)
      remote_control=false
      shift
      ;;
    --delay)
      delay_seconds="$2"
      shift 2
      ;;
    --)
      shift
      extra_args=("$@")
      break
      ;;
    *)
      usage
      ;;
  esac
done

py_args=("$project" "$remote_control" "$delay_seconds")
if (( ${#extra_args[@]} > 0 )); then
  py_args+=("${extra_args[@]}")
fi

python3 - "${py_args[@]}" <<'PY'
import json, os, sys
project = sys.argv[1]
remote_control = sys.argv[2].lower() == 'true'
delay = int(sys.argv[3])
extra = [x for x in sys.argv[4:] if x]
path = os.path.expanduser('~/.clawdremote/request.json')
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, 'w') as f:
    json.dump({
        'project': project,
        'mode': 'foreground',
        'remote_control': remote_control,
        'remote_control_delay_seconds': delay,
        'extra_args': extra,
    }, f)
print(path)
PY

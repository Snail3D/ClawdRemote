#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${CLAWDREMOTE_STATE_DIR:-$HOME/.clawdremote}"
INSTALL_DIR="${CLAWDREMOTE_INSTALL_DIR:-$STATE_DIR/bin}"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/ai.clawdremote.bridge.plist"
SCRIPT_SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
BRIDGE_SCRIPT_SOURCE="$SCRIPT_SOURCE_DIR/macos-bridge.sh"
BRIDGE_SCRIPT_TARGET="$INSTALL_DIR/macos-bridge.sh"

mkdir -p "$STATE_DIR" "$INSTALL_DIR" "$HOME/Library/LaunchAgents"
cp "$BRIDGE_SCRIPT_SOURCE" "$BRIDGE_SCRIPT_TARGET"
chmod +x "$BRIDGE_SCRIPT_TARGET"

cat > "$LAUNCH_AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key><string>ai.clawdremote.bridge</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/bash</string>
      <string>-lc</string>
      <string>$BRIDGE_SCRIPT_TARGET</string>
    </array>
    <key>WatchPaths</key>
    <array>
      <string>$STATE_DIR/request.json</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>StandardOutPath</key><string>$STATE_DIR/launchagent.out</string>
    <key>StandardErrorPath</key><string>$STATE_DIR/launchagent.err</string>
  </dict>
</plist>
PLIST

uid="$(id -u)"
launchctl bootout "gui/$uid/ai.clawdremote.bridge" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$uid" "$LAUNCH_AGENT"
launchctl kickstart -k "gui/$uid/ai.clawdremote.bridge"

echo "Installed ClawdRemote macOS bridge"
echo "State dir: $STATE_DIR"
echo "LaunchAgent: $LAUNCH_AGENT"
echo "Bridge script: $BRIDGE_SCRIPT_TARGET"

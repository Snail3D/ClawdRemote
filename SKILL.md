---
name: clawd-remote
description: Start a Claude Code interactive terminal session in a chosen project directory for remote handoff. Use when the user wants Claude launched inside a folder so they can attach or continue remotely, especially when the session should start with dangerously skipped permissions.
---

# ClawdRemote

Start a live Claude Code terminal session in a target project folder for remote takeover.

## Default workflow

1. Confirm the target directory.
2. Default to a visible foreground Terminal session in a new Terminal window unless the user explicitly wants a background PTY session.
3. Start the launcher script in that folder.
4. Check whether Claude Code shows a remote-control link.
5. Prefer native `claude remote-control` for fresh remote sessions on macOS bridge installs instead of relying on post-launch slash-command automation.
6. Report the mode used, the remote-control link when available, and how to close the session with `/exit`.

## Launcher

Use:

```bash
./start-claude-session.sh [--foreground|--background] <target-dir> [-- <extra claude args...>]
```

Optional extra Claude arguments:

```bash
./start-claude-session.sh --background /path/to/project -- --model sonnet
```

## What the script does

- verifies the target directory exists
- changes into that directory
- starts `claude --dangerously-skip-permissions --model opus`
- supports two modes:
  - `--foreground` (default): opens a new visible macOS Terminal window and launches Claude there
  - `--background`: launches Claude in the current PTY for remote handoff
- passes through any extra Claude CLI arguments after `--`
- prints the clean exit path: `/exit`

## Recommended usage

### Background mode

Use a real PTY and do not set a short timeout. These sessions are meant to stay alive until the user exits Claude with `/exit`.

```bash
./start-claude-session.sh --background /path/to/project
```

### Foreground mode

Use when the user wants the session visible on the Mac in Terminal.

```bash
./start-claude-session.sh --foreground /path/to/project
```

## Notes

- Use an interactive terminal with PTY support.
- Do not use `--print`; this skill is for persistent interactive sessions.
- Prefer `--foreground` by default so the user can see the Terminal window on the Mac.
- Use `--background` only when the user explicitly wants pure remote handoff without a visible Terminal window.
- Default model is **Opus**. Override it by passing your own model after `--`.
- After launch, look for the Claude Code remote-control URL in the terminal output and include it in your handoff reply.
- If remote control is not already active, send `/remote-control` in the Claude session to enable it, then report the link.
- Do not use a short timeout for these sessions. A short timeout will kill the remote Claude session mid-handoff.
- Exit cleanly with `/exit`.
- Stop and ask if the requested folder does not exist.
- Foreground mode currently relies on macOS Terminal automation.

## Remote Mac / Tailscale handoff

If the user wants Claude launched on another Mac without running OpenClaw there, the preferred path is:

1. Put both Macs on the same Tailscale tailnet.
2. Enable **Remote Login** (SSH) on the target Mac.
3. Add the source machine's SSH public key to the target Mac's `~/.ssh/authorized_keys`.
4. Install the lightweight ClawdRemote macOS bridge on the target Mac.
5. Send a launch request to the bridge, then read back `~/.clawdremote/last-result.json` for the remote-control link.

### Important PATH lesson

On some Macs, `claude` is installed but is only visible in an interactive/login shell. A plain non-interactive SSH command may fail to find it.

If `command -v claude` returns nothing over SSH, retry with a login shell:

```bash
ssh user@target-mac 'zsh -lic "command -v claude && claude --version"'
```

When launching Claude remotely over SSH, prefer a login shell form such as:

```bash
ssh user@target-mac 'zsh -lic "cd /path/to/project && claude --dangerously-skip-permissions --model opus"'
```

### Preferred bridge flow

Install on the target Mac:

```bash
./install-macos-bridge.sh
```

Trigger a launch request:

```bash
./request-remote-launch.sh /path/to/project
```

Read the result:

```bash
cat ~/.clawdremote/last-result.json
```

The bridge should:
- open a new visible Terminal window
- launch native `claude remote-control` in the requested project
- capture the resulting link when available
- record status/result without storing secrets in the repo

### Tailscale checklist

- Tailscale installed and connected on both machines
- Target Mac visible in `tailscale status`
- SSH enabled on target Mac
- SSH key auth working
- Confirm Claude with `zsh -lic 'command -v claude; claude --version'`

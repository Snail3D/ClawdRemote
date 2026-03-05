---
name: clawd-remote
description: Start a Claude Code interactive terminal session in a chosen project directory for remote handoff. Use when the user wants Claude launched inside a folder so they can attach or continue remotely, especially when the session should start with dangerously skipped permissions.
---

# ClawdRemote

Start a live Claude Code terminal session in a target project folder for remote takeover.

## Default workflow

1. Confirm the target directory.
2. Choose whether the user wants a visible foreground Terminal session or a background PTY session.
3. Start the launcher script in that folder.
4. Check whether Claude Code shows a remote-control link.
5. If remote control is not active yet, enable it by sending `/remote-control` in the Claude session.
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
  - `--background` (default): launches Claude in the current PTY for remote handoff
  - `--foreground`: opens a visible macOS Terminal tab/window and launches Claude there
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
- Prefer `--background` for pure remote handoff. It remains the default.
- Prefer `--foreground` when the user wants the terminal visible on the Mac.
- Default model is **Opus**. Override it by passing your own model after `--`.
- After launch, look for the Claude Code remote-control URL in the terminal output and include it in your handoff reply.
- If remote control is not already active, send `/remote-control` in the Claude session to enable it, then report the link.
- Do not use a short timeout for these sessions. A short timeout will kill the remote Claude session mid-handoff.
- Exit cleanly with `/exit`.
- Stop and ask if the requested folder does not exist.
- Foreground mode currently relies on macOS Terminal automation.

## Remote Mac / Tailscale handoff

If the user wants Claude launched on another Mac without running OpenClaw there, a practical path is:

1. Put both Macs on the same Tailscale tailnet.
2. Enable **Remote Login** (SSH) on the target Mac.
3. Add the source machine's SSH public key to the target Mac's `~/.ssh/authorized_keys`.
4. SSH into the target Mac and launch Claude from there.

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

### Tailscale checklist

- Tailscale installed and connected on both machines
- Target Mac visible in `tailscale status`
- SSH enabled on target Mac
- SSH key auth working
- Confirm Claude with `zsh -lic 'command -v claude; claude --version'`

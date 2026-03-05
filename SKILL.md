---
name: clawd-remote
description: Start a Claude Code interactive terminal session in a chosen project directory for remote handoff. Use when the user wants Claude launched inside a folder so they can attach or continue remotely, especially when the session should start with dangerously skipped permissions.
---

# ClawdRemote

Start a live Claude Code terminal session in a target project folder for remote takeover.

## Default workflow

1. Confirm the target directory.
2. Run the launcher script in a real terminal/PTY.
3. Leave the session running so the operator can attach remotely.
4. If Claude shows its one-time workspace trust prompt, confirm it only for folders the user explicitly trusts.

## Launcher

Use:

```bash
./start-claude-session.sh /path/to/project
```

Optional extra Claude arguments:

```bash
./start-claude-session.sh /path/to/project -- --model sonnet
```

## What the script does

- verifies the target directory exists
- changes into that directory
- starts `claude --dangerously-skip-permissions`
- passes through any extra Claude CLI arguments after `--`

## Notes

- Use an interactive terminal with PTY support.
- Do not use `--print`; this skill is for persistent interactive sessions.
- Stop and ask if the requested folder does not exist.
- Treat the dangerous-permissions launch as intentional and user-directed only.

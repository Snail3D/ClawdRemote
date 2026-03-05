# ClawdRemote

Start a live Claude Code session in a project folder for remote handoff.

## What it does

ClawdRemote is a tiny launcher + skill that:

- changes into a target project directory
- starts Claude Code in interactive mode
- defaults to **Opus**
- supports either a **background** PTY launch or a visible **foreground** Terminal launch on macOS
- supports clean remote handoff with a Claude remote-control link when available
- exits cleanly with `/exit`

## Files

- `SKILL.md` — OpenClaw skill definition
- `start-claude-session.sh` — launcher script

## Usage

Run the launcher with a target directory:

```bash
./start-claude-session.sh /path/to/project
```

Visible foreground Terminal launch:

```bash
./start-claude-session.sh --foreground /path/to/project
```

Pass extra Claude arguments after `--`:

```bash
./start-claude-session.sh --background /path/to/project -- --model sonnet
```

## Behavior

The script will:

1. verify the target directory exists
2. `cd` into that directory
3. start Claude with dangerous permissions enabled and Opus as the default model
4. support background or foreground launch modes
5. leave the session interactive for remote takeover
6. print the clean shutdown path: `/exit`

## Remote control handoff

After Claude starts, look for the remote-control link in the terminal output.

If remote control is not active yet, send:

```text
/remote-control
```

Then hand off:
- the remote-control URL
- the launch mode used
- the `/exit` shutdown path

## Remote Mac via Tailscale + SSH

You can also launch Claude on another Mac without running OpenClaw there.

Requirements:

- both Macs on the same Tailscale tailnet
- **Remote Login** enabled on the target Mac
- SSH public key added to the target Mac's `~/.ssh/authorized_keys`
- Claude installed on the target Mac

Important: if `claude` is not found over SSH, use a login shell:

```bash
ssh user@target-mac 'zsh -lic "command -v claude && claude --version"'
```

Example remote launch:

```bash
ssh user@target-mac 'zsh -lic "cd /path/to/project && claude --dangerously-skip-permissions --model opus"'
```

## Notes

- This is meant for a real interactive terminal session, not `--print` mode.
- Do not use a short timeout for remote handoff sessions.
- `--dangerously-skip-permissions` is intentionally powerful, so only use it for folders you trust.
- Foreground mode currently relies on macOS Terminal automation.

## Example

```bash
./start-claude-session.sh ~/Desktop/Mesh-Master
```

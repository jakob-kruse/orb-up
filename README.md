# orb-up

A tiny wrapper that keeps an [Amp](https://ampcode.com) runner alive in tmux and up to date.

## Install

The machine needs Bash, tmux, and cron. Then run:

```bash
curl -fsSL https://raw.githubusercontent.com/jakob-kruse/orb-up/main/install.sh | bash
```

The installer:

- installs Amp with its official installer if needed;
- installs `orb-up` in `~/.local/bin`;
- registers a daily Amp update at 04:17 with the user's crontab.

Log in first if needed (`amp login`), then start a runner in the directory where it should accept work:

```bash
orb-up start /path/to/project
```

The runner gets the machine's short hostname as its stable runner ID. Pass normal Amp options to override that or enable remote terminal access:

```bash
orb-up start /path/to/project --runner-id build-01 --remote-control-terminal
```

## Commands

```text
orb-up start [directory] [amp options]
orb-up status
orb-up logs [lines]
orb-up attach
orb-up restart
orb-up stop
orb-up update
orb-up enable-updates
orb-up disable-updates
```

`orb-up update` runs `amp update`. If Amp installs a new version and the runner is started, it restarts the runner so the new binary takes effect. That restart can interrupt an active thread.

Use environment variables to change the tmux session, default runner ID, or cron schedule:

```bash
export ORB_UP_SESSION=my-runner
orb-up enable-updates
orb-up start /srv/project
ORB_UP_RUNNER_ID=build-01 orb-up start /srv/project
ORB_UP_UPDATE_CRON='30 2 * * 0' orb-up enable-updates
```

Update output is written to `~/.local/state/orb-up/update.log` (or `$XDG_STATE_HOME/orb-up/update.log`).

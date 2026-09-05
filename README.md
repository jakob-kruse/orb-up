# orb-up

A tiny wrapper that keeps an [Amp](https://ampcode.com) runner alive in tmux and up to date.

## Install

The machine needs Bash, tmux, and cron. Then run:

```bash
curl -fsSL https://raw.githubusercontent.com/J4K4-Dev/orb-up/main/install.sh | bash
```

The installer:

- installs Amp with its official installer if needed;
- installs `orb-up` in `~/.local/bin`;
- installs a tiny Amp lifecycle plugin used to detect whether the runner is idle;
- registers an hourly update check at 17 minutes past the hour with the user's crontab.

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

`orb-up update` only starts an update when the runner is idle. If a thread is running—or idle state cannot be verified—it defers until the next hourly check. It checks again before restarting and leaves the restart pending if work started during the update.

When upgrading an existing `orb-up` installation, run `orb-up restart` once while its runner is idle so the runner loads the idle-tracking plugin.

Use environment variables to change the tmux session, default runner ID, or cron schedule:

```bash
export ORB_UP_SESSION=my-runner
orb-up enable-updates
orb-up start /srv/project
ORB_UP_RUNNER_ID=build-01 orb-up start /srv/project
ORB_UP_UPDATE_CRON='30 2 * * 0' orb-up enable-updates
```

Update output is written to `~/.local/state/orb-up/update.log` (or `$XDG_STATE_HOME/orb-up/update.log`).

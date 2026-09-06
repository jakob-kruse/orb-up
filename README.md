# orb-up

A small wrapper for keeping an [Amp](https://ampcode.com) runner online, with automatic updates that wait until the runner is idle. Bash is used on Linux and macOS; PowerShell is used on Windows.

## Install on Linux or macOS

You'll need Bash, tmux, cron, and curl on the machine that will host the runner:

```bash
curl -fsSL https://raw.githubusercontent.com/J4K4-Dev/orb-up/main/install.sh | bash
```

## Install on Windows

Run the installer in PowerShell:

```powershell
irm https://raw.githubusercontent.com/J4K4-Dev/orb-up/main/install.ps1 | iex
```

To test a branch before it is merged, set its name for the installer:

```powershell
$env:ORB_UP_REF = 'windows-support'
irm https://raw.githubusercontent.com/J4K4-Dev/orb-up/windows-support/install.ps1 | iex
```

The Windows version runs the runner as a hidden background process and uses Windows Task Scheduler for update checks. It requires a logged-in user session.

The installer:

- Installs Amp using its official installer if it isn't already available.
- Installs `orb-up` in `~/.local/bin` on Unix or `%LOCALAPPDATA%\Programs\orb-up` on Windows.
- Installs an Amp lifecycle plugin to track whether the runner is idle.
- Adds an update check at 17 minutes past every hour using cron or Windows Task Scheduler.

## Start a runner

Make sure `~/.local/bin` is on your `PATH`. Log in with `amp login` if you haven't already, then start the runner in the project directory where it should accept work:

```bash
orb-up start /path/to/project
```

On Windows, use PowerShell:

```powershell
orb-up.ps1 start C:\path\to\project
```

By default, the runner uses the machine's short hostname as its stable runner ID. You can pass Amp options after the directory to choose a different ID or enable remote terminal access:

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

Use `orb-up.ps1` instead of `orb-up` for each command on Windows. The `attach` command is Unix-only; use `logs` to inspect a Windows runner.

## Automatic updates

The hourly check runs `orb-up update` to update Amp and restart the runner if Amp has changed. You can also run the command manually.

If the runner is busy, or its idle state can't be verified, the update waits until the next check. Before restarting, `orb-up` checks again: if work began during the update, the restart stays pending until a later idle check.

When upgrading an existing `orb-up` installation, run `orb-up restart` once while the runner is idle to load the idle-tracking plugin.

Update output is written to `~/.local/state/orb-up/update.log` on Unix and `%LOCALAPPDATA%\orb-up\update.log` on Windows. `XDG_STATE_HOME` changes the Unix location; `ORB_UP_STATE_DIR` overrides it on either platform.

## Configuration

Use environment variables to customize the tmux session, default runner ID, or update schedule. For a custom session, use the same setting when registering updates and starting the runner:

```bash
export ORB_UP_SESSION=my-runner
orb-up enable-updates
orb-up start /srv/project
```

To choose a default runner ID:

```bash
ORB_UP_RUNNER_ID=build-01 orb-up start /srv/project
```

To check for updates at 02:30 every Sunday instead of hourly:

```bash
ORB_UP_UPDATE_CRON='30 2 * * 0' orb-up enable-updates
```

Custom update schedules are currently available only in the Unix version. Windows checks hourly at 17 minutes past the hour.

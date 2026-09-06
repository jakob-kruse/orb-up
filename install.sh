#!/usr/bin/env bash
set -euo pipefail

REPOSITORY="${ORB_UP_REPOSITORY:-J4K4-Dev/orb-up}"
REF="${ORB_UP_REF:-main}"
SOURCE_URL="${ORB_UP_SOURCE_URL:-https://raw.githubusercontent.com/$REPOSITORY/$REF/orb-up}"
PLUGIN_SOURCE_URL="${ORB_UP_PLUGIN_SOURCE_URL:-https://raw.githubusercontent.com/$REPOSITORY/$REF/orb-up-idle.ts}"

die() {
	printf 'orb-up installer: %s\n' "$*" >&2
	exit 1
}

need() {
	command -v "$1" >/dev/null 2>&1 || die "'$1' is required"
}

download() {
	local url="$1"
	local destination="$2"
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL "$url" -o "$destination"
	elif command -v wget >/dev/null 2>&1; then
		wget -q "$url" -O "$destination"
	else
		die "'curl' or 'wget' is required"
	fi
}

find_amp() {
	if command -v amp >/dev/null 2>&1; then
		command -v amp
	elif [[ -x "${AMP_HOME:-$HOME/.amp}/bin/amp" ]]; then
		printf '%s/bin/amp\n' "${AMP_HOME:-$HOME/.amp}"
	else
		return 1
	fi
}

need bash
need install
need mktemp
command -v tmux >/dev/null 2>&1 || die "'tmux' is required (install the tmux package)"
command -v crontab >/dev/null 2>&1 || die "'crontab' is required (install the cron or cronie package)"
command -v pgrep >/dev/null 2>&1 || die "'pgrep' is required (install the procps package)"

temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

if ! amp_bin="$(find_amp)"; then
	printf 'Installing Amp CLI...\n'
	download https://ampcode.com/install.sh "$temporary_directory/install-amp.sh"
	bash "$temporary_directory/install-amp.sh"
	amp_bin="$(find_amp)" || die "Amp installation finished, but the executable was not found"
fi

install_directory="${ORB_UP_INSTALL_DIR:-$HOME/.local/bin}"
mkdir -p "$install_directory"
plugin_directory="${ORB_UP_PLUGIN_DIR:-$HOME/.config/amp/plugins}"
mkdir -p "$plugin_directory"

printf 'Installing orb-up...\n'
download "$SOURCE_URL" "$temporary_directory/orb-up"
download "$PLUGIN_SOURCE_URL" "$temporary_directory/orb-up-idle.ts"
install -m 0755 "$temporary_directory/orb-up" "$install_directory/orb-up"
install -m 0644 "$temporary_directory/orb-up-idle.ts" "$plugin_directory/orb-up-idle.ts"

AMP_BIN="$amp_bin" "$install_directory/orb-up" enable-updates

printf '\norb-up is installed at %s/orb-up.\n' "$install_directory"
if tmux has-session -t "${ORB_UP_SESSION:-amp-runner}" 2>/dev/null; then
	printf 'An existing runner must be restarted once while idle to enable idle tracking.\n'
fi
if [[ ":$PATH:" != *":$install_directory:"* ]]; then
	printf 'Add it to this shell now with:\n  export PATH="%s:$PATH"\n' "$install_directory"
fi
printf 'Start a runner with:\n  "%s/orb-up" start /path/to/project\n' "$install_directory"

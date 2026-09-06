#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP="$(mktemp -d)"
FAKE_AMP_PID=""

cleanup() {
	if [[ -n "$FAKE_AMP_PID" ]]; then
		kill "$FAKE_AMP_PID" 2>/dev/null || true
		wait "$FAKE_AMP_PID" 2>/dev/null || true
	fi
	rm -rf "$TEMP"
}
trap cleanup EXIT

cp "${BASH:-$(command -v bash)}" "$TEMP/amp"
cat > "$TEMP/tmux" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TMUX_LOG"
[[ "${1:-}" != "has-session" ]]
EOF
cat > "$TEMP/pgrep" <<'EOF'
#!/usr/bin/env bash
[[ ! -s "$FAKE_PGREP_OUTPUT" ]] || cat "$FAKE_PGREP_OUTPUT"
EOF
chmod +x "$TEMP/tmux" "$TEMP/pgrep"

export PATH="$TEMP:$PATH"
export AMP_BIN="$TEMP/amp"
export ORB_UP_STATE_DIR="$TEMP/state"
export TMUX_LOG="$TEMP/tmux.log"
export FAKE_PGREP_OUTPUT="$TEMP/pgrep.out"

"$ROOT/orb-up" start "$TEMP"
grep -q -- "--no-tui.*--runner-id" "$TMUX_LOG"
printf 'PASS: start with no Amp options\n'

: > "$TMUX_LOG"
"$TEMP/amp" -c 'trap "exit 0" TERM; while :; do sleep 0.1; done' --no-tui &
FAKE_AMP_PID=$!
printf '%s\n' "$FAKE_AMP_PID" > "$FAKE_PGREP_OUTPUT"

if printf 'n\n' | "$ROOT/orb-up" start "$TEMP" > "$TEMP/decline.out" 2>&1; then
	printf 'FAIL: declining cleanup unexpectedly started a runner\n' >&2
	exit 1
fi
kill -0 "$FAKE_AMP_PID"
if grep -q '^new-session ' "$TMUX_LOG"; then
	printf 'FAIL: declining cleanup created a tmux session\n' >&2
	exit 1
fi
grep -q 'existing runner was not stopped' "$TEMP/decline.out"
printf 'PASS: declining cleanup preserves the unmanaged runner\n'

: > "$TMUX_LOG"
printf 'y\n' | "$ROOT/orb-up" start "$TEMP" > "$TEMP/confirm.out" 2>&1
grep -q 'Stopped unmanaged Amp runner' "$TEMP/confirm.out"
grep -q '^new-session ' "$TMUX_LOG"
if kill -0 "$FAKE_AMP_PID" 2>/dev/null; then
	state="$(ps -p "$FAKE_AMP_PID" -o stat= 2>/dev/null || true)"
	[[ "$state" == Z* ]]
fi
wait "$FAKE_AMP_PID" 2>/dev/null || true
FAKE_AMP_PID=""
printf 'PASS: confirmed cleanup stops the unmanaged runner\n'

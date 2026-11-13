#!/usr/bin/env bash
set -Eeuo pipefail

DISPLAY_NUMBER="${KAYRALRICS_DISPLAY_NUMBER:-99}"
DISPLAY=":${DISPLAY_NUMBER}"
SCREEN="${KAYRALRICS_SCREEN:-1600x900x24}"
WEB_PORT="${KAYRALRICS_WEB_PORT:-1337}"
VNC_PORT="${KAYRALRICS_VNC_PORT:-5901}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/kayralrics"
VNC_PASSWORD_FILE="$HOME/.vnc/passwd"
AUTH_FILE="$STATE_DIR/Xauthority"
X_SOCKET="/tmp/.X11-unix/X${DISPLAY_NUMBER}"

mkdir -p "$STATE_DIR" "$HOME/.vnc"
chmod 700 "$STATE_DIR" "$HOME/.vnc"

for app in Xvfb xauth mcookie startxfce4 dbus-run-session xset x11vnc novnc_proxy; do
    if ! command -v "$app" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$app" >&2
        exit 1
    fi
done

if [[ ! -s "$VNC_PASSWORD_FILE" ]]; then
    printf 'VNC password file not found: %s\n' "$VNC_PASSWORD_FILE" >&2
    printf 'Run: x11vnc -storepasswd\n' >&2
    exit 1
fi

if [[ -e "$X_SOCKET" || -e "/tmp/.X${DISPLAY_NUMBER}-lock" ]]; then
    printf 'X display %s appears to be in use. Stop the old Xvfb instance first.\n' "$DISPLAY" >&2
    exit 1
fi

if ss -H -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${WEB_PORT}$|(^|:)${VNC_PORT}$"; then
    printf 'Port %s or %s is already in use.\n' "$WEB_PORT" "$VNC_PORT" >&2
    exit 1
fi

PIDS=()

cleanup() {
    trap - EXIT INT TERM
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    for pid in "${PIDS[@]}"; do
        wait "$pid" 2>/dev/null || true
    done
}

trap cleanup EXIT
trap 'exit 0' INT TERM

rm -f "$AUTH_FILE"
touch "$AUTH_FILE"
chmod 600 "$AUTH_FILE"
xauth -f "$AUTH_FILE" add "$DISPLAY" MIT-MAGIC-COOKIE-1 "$(mcookie)"

Xvfb "$DISPLAY" -auth "$AUTH_FILE" -screen 0 "$SCREEN" -nolisten tcp >"$STATE_DIR/xvfb.log" 2>&1 &
PIDS+=("$!")

for _ in {1..60}; do
    [[ -S "$X_SOCKET" ]] && break
    sleep 0.25
done

if [[ ! -S "$X_SOCKET" ]]; then
    printf 'Xvfb did not create display socket %s.\n' "$X_SOCKET" >&2
    exit 1
fi

export DISPLAY XAUTHORITY="$AUTH_FILE"
xset s off || true
xset s noblank || true
xset -dpms || true

(
    unset WAYLAND_DISPLAY SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS
    export DISPLAY XAUTHORITY
    export XDG_SESSION_TYPE=x11
    export XDG_CURRENT_DESKTOP=XFCE
    export XDG_SESSION_DESKTOP=xfce
    exec dbus-run-session -- startxfce4
) >"$STATE_DIR/xfce.log" 2>&1 &
PIDS+=("$!")

sleep 2

x11vnc \
    -display "$DISPLAY" \
    -auth "$AUTH_FILE" \
    -rfbauth "$VNC_PASSWORD_FILE" \
    -localhost \
    -forever \
    -shared \
    -noxdamage \
    -rfbport "$VNC_PORT" \
    >"$STATE_DIR/vnc.log" 2>&1 &
PIDS+=("$!")

for _ in {1..40}; do
    if ss -H -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${VNC_PORT}$"; then
        break
    fi
    sleep 0.25
done

if ! ss -H -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${VNC_PORT}$"; then
    printf 'x11vnc did not listen on port %s.\n' "$VNC_PORT" >&2
    exit 1
fi

novnc_proxy --listen "127.0.0.1:${WEB_PORT}" --vnc "127.0.0.1:${VNC_PORT}" >"$STATE_DIR/novnc.log" 2>&1 &
PIDS+=("$!")

wait -n "${PIDS[@]}"

#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
    printf 'Do not run this script as root. Run it as your normal Fedora user.\n' >&2
    exit 1
fi

systemctl --user disable --now kayralrics.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/kayralrics.service"
rm -f "$HOME/.local/bin/kayralrics"
rm -rf "$HOME/.local/lib/kayralrics"
systemctl --user daemon-reload
systemctl --user reset-failed kayralrics.service 2>/dev/null || true

printf 'Kayralrics service and command removed.\n'
printf 'VNC password and state files were kept: %s/.vnc/passwd and %s/.local/state/kayralrics\n' "$HOME" "$HOME"
printf 'To disable boot-time lingering (only if you no longer need other user services): sudo loginctl disable-linger %s\n' "$USER"
printf 'Installed Fedora packages were not removed.\n'

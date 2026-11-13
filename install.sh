#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
    printf 'Do not run this installer as root. Run it as your normal Fedora user.\n' >&2
    exit 1
fi

if [[ ! -f /etc/fedora-release ]]; then
    printf 'This installer targets Fedora.\n' >&2
    exit 1
fi

ROOT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"

sudo dnf install -y \
    xorg-x11-server-Xvfb \
    xorg-x11-xauth \
    x11vnc \
    novnc \
    xfce4-session \
    xfce4-panel \
    xfdesktop \
    xfwm4 \
    xfconf \
    xfce4-settings \
    xfce4-terminal \
    xfce4-power-manager \
    dbus-daemon \
    util-linux \
    xset \
    xdg-utils \
    iproute

mkdir -p "$HOME/.local/lib/kayralrics" "$HOME/.local/bin" "$HOME/.config/systemd/user" "$HOME/.vnc"
chmod 700 "$HOME/.vnc"

install -m 755 "$ROOT_DIR/lib/run-desktop.sh" "$HOME/.local/lib/kayralrics/run-desktop.sh"
install -m 755 "$ROOT_DIR/bin/kayralrics" "$HOME/.local/bin/kayralrics"
install -m 644 "$ROOT_DIR/systemd/kayralrics.service" "$HOME/.config/systemd/user/kayralrics.service"

if [[ ! -s "$HOME/.vnc/passwd" ]]; then
    printf '\nCreate a VNC password. x11vnc classic password authentication uses only the first 8 characters.\n'
    x11vnc -storepasswd
fi

if [[ ! -s "$HOME/.vnc/passwd" ]]; then
    printf 'VNC password file was not created. Installation cannot continue.\n' >&2
    exit 1
fi

chmod 600 "$HOME/.vnc/passwd"
sudo loginctl enable-linger "$USER"
systemctl --user daemon-reload
systemctl --user enable --now kayralrics.service

if ! grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
    printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
fi

printf '\nInstallation complete.\n'
printf 'Log out and back in, or open a new terminal.\n'
printf 'Open the desktop with: kayralrics\n'
printf 'Browser URL: http://127.0.0.1:1337/vnc.html\n'

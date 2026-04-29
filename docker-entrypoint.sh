#!/usr/bin/env bash
set -euo pipefail

DEV_USERNAME="${DEV_USERNAME:-dev}"
MARKER_FILE="/var/lib/devcontainer/sudo-password-set"

if [[ ! -f "$MARKER_FILE" ]]; then
  if ! { exec 3<> /dev/tty; } 2>/dev/null; then
    echo "[ERROR] Sudo password for '$DEV_USERNAME' has not been set yet." >&2
    echo "[ERROR] Start the container interactively once to set it." >&2
    exit 1
  fi

  echo "Set sudo password for '$DEV_USERNAME'." >&3
  while true; do
    read -r -s -p "New sudo password: " password_one <&3
    echo >&3
    read -r -s -p "Retype new sudo password: " password_two <&3
    echo >&3

    if [[ -z "$password_one" ]]; then
      echo "Password cannot be empty." >&2
      continue
    fi

    if [[ "$password_one" != "$password_two" ]]; then
      echo "Passwords do not match; please try again." >&2
      continue
    fi

    printf '%s\n' "$password_one" | sudo -n /usr/local/sbin/set-dev-sudo-password
    unset password_one password_two
    break
  done
  exec 3>&-
fi

exec "$@"

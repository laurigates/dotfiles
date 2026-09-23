#!/bin/sh
set -eu
cd "$(dirname "$0")"
install -m 0755 cpu-watchdog /usr/local/sbin/cpu-watchdog
install -m 0644 cpu-watchdog@.service cpu-watchdog@.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now cpu-watchdog@pop-upgrade.timer
systemctl list-timers 'cpu-watchdog@*' --no-pager

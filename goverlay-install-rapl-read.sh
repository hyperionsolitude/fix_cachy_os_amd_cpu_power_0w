#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Install udev rules so RAPL energy sysfs files are readable without root
# (GOverlay, MangoHud, and similar overlays that show CPU package power).
# On AMD, these counters still live under the intel-rapl powercap nodes.
# Safe to run again (idempotent).
#
# Usage: bash goverlay-install-rapl-read.sh
#     (re-execs with sudo if needed; review any script before curl|bash)
# -----------------------------------------------------------------------------
set -euo pipefail

if [[ ${EUID:-0} -ne 0 ]]; then
  exec sudo -- "$0" "$@"
fi

RULE_DST=/etc/udev/rules.d/99-intel-rapl-energy-read.rules

umask 022
cat >"$RULE_DST" <<'EOF'
# RAPL energy_uj readable by all users (AMD is exposed under intel-rapl too).
ACTION=="add", SUBSYSTEM=="powercap", KERNEL=="intel-rapl:*", RUN+="/bin/sh -c 'for z in /sys/class/powercap/intel-rapl*/energy_uj /sys/class/powercap/intel-rapl*/*/energy_uj; do test -f \"$$z\" && chmod a+r \"$$z\"; done; for z in /sys/class/powercap/intel-rapl*/*/max_energy_range_uj /sys/class/powercap/intel-rapl*/max_energy_range_uj; do test -f \"$$z\" && chmod a+r \"$$z\"; done; :'"
EOF
chmod 644 "$RULE_DST"

udevadm control --reload-rules
udevadm trigger -s powercap -c add 2>/dev/null || true

echo "[OK] Installed $RULE_DST — reboot if CPU power is still missing."

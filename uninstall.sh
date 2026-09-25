#!/usr/bin/env bash
# Removes linux-x11-recorder-fix. Recordings and settings in ~/.config/Recordly are kept.
set -euo pipefail

rm -rf "${HOME}/.local/opt/recordly-x11-fix"
rm -f "${HOME}/.local/bin/recordly-x11-fix" \
	"${HOME}/.local/share/applications/recordly-x11-fix.desktop" \
	"${HOME}/.local/share/icons/recordly-x11-fix.png"
command -v update-desktop-database >/dev/null && update-desktop-database "${HOME}/.local/share/applications" >/dev/null 2>&1 || true

echo "Removed. Your recordings and settings in ~/.config/Recordly were not touched."

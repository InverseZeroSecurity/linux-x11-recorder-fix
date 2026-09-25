#!/usr/bin/env bash
# linux-x11-recorder-fix — unofficial fixes for Recordly 1.4.0 on Linux (X11)
# Copyright (C) 2026 InverseZero Security
# Licensed under the GNU AGPL v3 (see LICENSE). Recordly is by webadderall:
# https://github.com/webadderallorg/Recordly — this project is not affiliated with it.
set -euo pipefail

RECORDLY_VERSION="1.4.0"
APPIMAGE_URL="https://github.com/webadderallorg/Recordly/releases/download/v${RECORDLY_VERSION}/Recordly-linux-x64.AppImage"
APPIMAGE_SHA256="37b16c416ee9970e0117a9839abe0b7e024f3f02db767f1a6122528b84704a41"

INSTALL_DIR="${HOME}/.local/opt/recordly-x11-fix"
BIN_DIR="${HOME}/.local/bin"
LAUNCHER="${BIN_DIR}/recordly-x11-fix"
DESKTOP_FILE="${HOME}/.local/share/applications/recordly-x11-fix.desktop"
ICON_FILE="${HOME}/.local/share/icons/recordly-x11-fix.png"

appimage=""
use_swiftshader=0

usage() {
	cat <<EOF
Usage: ./install.sh [--appimage PATH] [--swiftshader]

  --appimage PATH   Use an already-downloaded Recordly-linux-x64.AppImage (v${RECORDLY_VERSION})
                    instead of downloading it from the official GitHub release.
  --swiftshader     Launch with software GPU rendering (--use-angle=swiftshader).
                    Only needed if recording fails with "could not find video source"
                    and the log shows "Exiting GPU process due to errors during initialization".
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--appimage) appimage="${2:?--appimage needs a path}"; shift 2 ;;
		--swiftshader) use_swiftshader=1; shift ;;
		-h|--help) usage; exit 0 ;;
		*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
	esac
done

die() { echo "error: $*" >&2; exit 1; }
info() { echo "==> $*"; }

[[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]] || die "only Linux x86_64 is supported."
for cmd in python3 sha256sum; do
	command -v "$cmd" >/dev/null || die "'$cmd' is required but not installed."
done

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

if [[ -z "$appimage" ]]; then
	appimage="${work_dir}/Recordly-linux-x64.AppImage"
	info "Downloading official Recordly ${RECORDLY_VERSION} AppImage"
	if command -v curl >/dev/null; then
		curl -fL --progress-bar -o "$appimage" "$APPIMAGE_URL"
	elif command -v wget >/dev/null; then
		wget -q --show-progress -O "$appimage" "$APPIMAGE_URL"
	else
		die "need curl or wget to download, or pass --appimage PATH."
	fi
fi
[[ -f "$appimage" ]] || die "AppImage not found: $appimage"

info "Verifying checksum"
actual_sha="$(sha256sum "$appimage" | cut -d' ' -f1)"
if [[ "$actual_sha" != "$APPIMAGE_SHA256" ]]; then
	die "checksum mismatch. These patches only fit the official Recordly ${RECORDLY_VERSION} AppImage.
       expected ${APPIMAGE_SHA256}
       got      ${actual_sha}"
fi

info "Extracting AppImage"
cp "$appimage" "${work_dir}/recordly.AppImage"
chmod +x "${work_dir}/recordly.AppImage"
(cd "$work_dir" && ./recordly.AppImage --appimage-extract >/dev/null)
[[ -f "${work_dir}/squashfs-root/resources/app.asar" ]] || die "extraction failed."

info "Applying fixes"
python3 - "${work_dir}/squashfs-root/resources/app.asar" <<'PY'
import sys

path = sys.argv[1]
data = open(path, "rb").read()

# Each patch is a same-length byte replacement in Recordly 1.4.0's bundled main process.
patches = [
    (
        "X11 screen capture: only use the Wayland portal placeholder on Wayland sessions",
        b'(o==="screen:linux-portal"||!o)',
        b'(bx(process.env)              )',
    ),
    (
        "Cursor data: keep cursor telemetry for the screen recording when the webcam is on",
        b'samples:Sn},null,2),"utf-8"),go([])}',
        b'samples:Sn},null,2),"utf-8"),void 0}',
    ),
    (
        "HUD menus: let the recording bar grow while a menu is open on Linux",
        b'process.platform!=="linux"&&wC(!e)',
        b'process.platform!=="never"&&wC(!e)',
    ),
]

for name, old, new in patches:
    assert len(old) == len(new), name
    count = data.count(old)
    if count != 1:
        sys.exit(f"patch target not found exactly once ({count}x): {name}")
    data = data.replace(old, new)
    print(f"    fixed: {name}")

open(path, "wb").write(data)
PY

info "Installing to ${INSTALL_DIR}"
rm -rf "$INSTALL_DIR"
mkdir -p "$(dirname "$INSTALL_DIR")" "$BIN_DIR" "$(dirname "$DESKTOP_FILE")" "$(dirname "$ICON_FILE")"
mv "${work_dir}/squashfs-root" "$INSTALL_DIR"
cp "${INSTALL_DIR}/recordly.png" "$ICON_FILE"

extra_flags=""
[[ "$use_swiftshader" -eq 1 ]] && extra_flags=" --use-angle=swiftshader"

cat >"$LAUNCHER" <<EOF
#!/bin/sh
# Launches Recordly ${RECORDLY_VERSION} with unofficial Linux X11 fixes (linux-x11-recorder-fix).
APPDIR="${INSTALL_DIR}" exec "${INSTALL_DIR}/AppRun" --no-sandbox${extra_flags} "\$@"
EOF
chmod +x "$LAUNCHER"

cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Recordly (X11 fixes)
Comment=Recordly ${RECORDLY_VERSION} with unofficial Linux X11 fixes
Exec=${LAUNCHER} %U
Icon=${ICON_FILE}
Terminal=false
Type=Application
StartupWMClass=Recordly
Categories=AudioVideo;
EOF
command -v update-desktop-database >/dev/null && update-desktop-database "$(dirname "$DESKTOP_FILE")" >/dev/null 2>&1 || true

cat <<EOF

Done. Start it from your app menu ("Recordly (X11 fixes)") or run:
    ${LAUNCHER}

Recordings and settings are shared with the official app (~/.config/Recordly).
When Recordly ships these fixes upstream, uninstall with ./uninstall.sh and use the official release.
EOF

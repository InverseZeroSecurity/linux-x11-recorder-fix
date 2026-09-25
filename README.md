# linux-x11-recorder-fix

Unofficial fixes that make **[Recordly](https://github.com/webadderallorg/Recordly) 1.4.0** record properly on **Linux with X11** (Kali, Ubuntu/Debian on Xorg, XFCE, and similar).

> **Not affiliated with Recordly.** Recordly is made by webadderall and licensed under AGPLv3. This repo contains only an install script. It downloads the **official** Recordly AppImage from Recordly's GitHub release, verifies its checksum, applies four small fixes, and adds a launcher. Once Recordly ships these fixes, uninstall this and use the official release.

Made by **[InverseZero Security](https://github.com/InverseZeroSecurity)**.

## What it fixes

| Symptom | Cause |
|---|---|
| **"Failed to start recording: Could not start video source"** | On Linux, Recordly always asks Chromium for the Wayland screen-portal placeholder (`screen:0:0`), even on X11, where that source doesn't exist. The fix uses the portal only on real Wayland sessions and uses your actual screen on X11. |
| **Auto-zoom and cursor effects don't work** (with webcam on) | The webcam video is saved before the screen video, and saving it takes all of the session's cursor data. The screen recording ends up with none. The fix keeps the cursor data for the screen recording. |
| **Menus on the recording bar are cut off** (the ⋯ menu only shows languages, so "Recordings Path" is missing) | On Linux the recording bar is a small window that is never enlarged while a menu is open. The fix lets it grow while a menu is open, as it does on other platforms. |
| **GPU errors in the terminal** (`Requested GL implementation (gl=egl-gles2…)`, `Exiting GPU process due to errors during initialization`), with capture or the editor preview failing ("could not find video source", "No supported Pixi preview renderer") | On X11, Recordly forces Chromium's `--use-gl=egl` mode, but its Electron build only allows ANGLE. The GPU process exits, and rendering falls back to disabled. The fix stops forcing EGL, so your real graphics card is used. Credit to [@Adedamolas](https://github.com/Adedamolas) for [finding this](https://github.com/webadderallorg/Recordly/issues/1001). |

Related upstream reports: X11 capture, [#1001](https://github.com/webadderallorg/Recordly/issues/1001) and [#364](https://github.com/webadderallorg/Recordly/issues/364); clipped menus, [#944](https://github.com/webadderallorg/Recordly/issues/944). Several community PRs are already open for those two. The cursor-data bug is reported in [#1038](https://github.com/webadderallorg/Recordly/issues/1038), with a fix submitted in [#1039](https://github.com/webadderallorg/Recordly/pull/1039).

## Install

Requirements: Linux x86_64, `python3`, `sha256sum`, and `curl` or `wget`.

```bash
git clone https://github.com/InverseZeroSecurity/linux-x11-recorder-fix.git
cd linux-x11-recorder-fix
./install.sh
```

Then start **"Recordly (X11 fixes)"** from your app menu, or run `~/.local/bin/recordly-x11-fix`.

Already downloaded the AppImage? `./install.sh --appimage ~/Downloads/Recordly-linux-x64.AppImage`

The script only accepts the official Recordly 1.4.0 AppImage, SHA-256 `37b16c41…04a41`. Any other file is rejected, because the fixes are byte-exact patches for that build.

## GPU still failing? (fallback)

The GPU fix above lets Recordly use your graphics card (tested on an NVIDIA RTX 3050 with the proprietary 550 driver). If running `~/.local/bin/recordly-x11-fix` from a terminal still prints `Exiting GPU process due to errors during initialization`, reinstall with software rendering. It's slower, but it works without the GPU:

```bash
./install.sh --swiftshader
```

## Other things worth checking

- **"Could not start video source" for the webcam:** another app, often OBS, is using the camera. Only one app can use a webcam at a time on Linux. Check with `fuser -v /dev/video0`.
- **Static or hiss on the mic:** Recordly may have picked your motherboard's analog input. Choose your real microphone in the mic menu on the recording bar.
- **Auto-cleanup:** after each recording, Recordly deletes `recording-*` videos in the recordings folder that are older than 14 days or beyond the 20 newest, unless they belong to a saved project. That's upstream behaviour and this script doesn't change it.

## Uninstall

```bash
./uninstall.sh
```

Your recordings and settings in `~/.config/Recordly` are kept, and they are shared with the official app.

## Upstream status

Once these fixes are released in Recordly, please use the official app instead:
- Cursor data with webcam: reported in [#1038](https://github.com/webadderallorg/Recordly/issues/1038), fix submitted in [#1039](https://github.com/webadderallorg/Recordly/pull/1039)
- X11 screen capture and forced EGL GPU mode: [#1001](https://github.com/webadderallorg/Recordly/issues/1001), [#364](https://github.com/webadderallorg/Recordly/issues/364) (community fix PRs pending)
- Clipped HUD menus: [#944](https://github.com/webadderallorg/Recordly/issues/944) (community fix PRs pending)

## License

AGPLv3. See [LICENSE](LICENSE). Recordly itself is © webadderall, AGPLv3, and started as a fork of OpenScreen by Siddharth Vaddem.

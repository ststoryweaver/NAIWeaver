#!/usr/bin/env bash
# CI-only smoke test: run in a fresh dbus-run-session and Xvfb display after
# installing the bundle. This checks window creation, not interactive features.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG="$PROJECT_ROOT/build/flatpak/smoke-test.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee "$LOG") 2>&1

: "${DISPLAY:?Run this test under xvfb-run}"
: "${DBUS_SESSION_BUS_ADDRESS:?Run this test under dbus-run-session}"
for tool in flatpak xdotool gnome-keyring-daemon; do
    command -v "$tool" >/dev/null || { echo "Missing test tool: $tool"; exit 1; }
done

gnome-keyring-daemon --start --components=secrets
flatpak run --user --branch=experimental \
    --socket=x11 --nosocket=wayland \
    --env=GDK_BACKEND=x11 --env=LIBGL_ALWAYS_SOFTWARE=1 \
    dev.naiweaver.app &
APP_PID=$!
cleanup() {
    flatpak kill dev.naiweaver.app 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
}
trap cleanup EXIT

# An early exit, even with status 0, is not a successful launch.
WINDOW_FOUND=false
for ((attempt = 0; attempt < 30; attempt++)); do
    if ! kill -0 "$APP_PID" 2>/dev/null; then
        echo "FAIL: Flatpak exited before creating its window."
        exit 1
    fi
    if xdotool search --onlyvisible --name '^NAIWeaver$' >/dev/null 2>&1; then
        WINDOW_FOUND=true
        break
    fi
    sleep 1
done
if [[ "$WINDOW_FOUND" != true ]]; then
    echo "FAIL: No visible NAIWeaver window within 30 seconds."
    exit 1
fi
sleep 10
if ! kill -0 "$APP_PID" 2>/dev/null || \
    ! xdotool search --onlyvisible --name '^NAIWeaver$' >/dev/null 2>&1; then
    echo "FAIL: Application closed during startup."
    exit 1
fi
echo "PASS: Installed Flatpak created a window and stayed running."

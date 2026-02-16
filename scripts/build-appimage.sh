#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUNDLE_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
APPDIR="$PROJECT_ROOT/NAIWeaver.AppDir"
ICON_SRC="$PROJECT_ROOT/assets/logo.png"
DESKTOP_SRC="$PROJECT_ROOT/linux/packaging/naiweaver.desktop"

# Forward all arguments (e.g. --dart-define=...) to flutter build
FLUTTER_ARGS=("$@")

echo "==> Building Flutter Linux release..."
cd "$PROJECT_ROOT"
flutter build linux --release "${FLUTTER_ARGS[@]}"

echo "==> Creating AppDir layout..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Copy the entire bundle preserving its layout (binary expects lib/ and data/
# as sibling directories), so the AppDir becomes:
#   NAIWeaver.AppDir/
#   ├── AppRun
#   ├── naiweaver.desktop
#   ├── naiweaver.png
#   ├── naiweaver          (binary)
#   ├── lib/               (.so files)
#   └── data/              (flutter_assets, icudtl.dat)
cp -a "$BUNDLE_DIR/"* "$APPDIR/"

# Copy .desktop file and icon into AppDir root (required by AppImage spec)
cp "$DESKTOP_SRC" "$APPDIR/naiweaver.desktop"
cp "$ICON_SRC" "$APPDIR/naiweaver.png"
cp "$ICON_SRC" "$APPDIR/usr/share/icons/hicolor/256x256/apps/naiweaver.png"

# Create AppRun wrapper
cat > "$APPDIR/AppRun" << 'APPRUN_EOF'
#!/usr/bin/env bash
SELF_DIR="$(dirname "$(readlink -f "$0")")"
exec "$SELF_DIR/naiweaver" "$@"
APPRUN_EOF
chmod +x "$APPDIR/AppRun"

# Download appimagetool if not present
APPIMAGETOOL="$PROJECT_ROOT/appimagetool"
if [ ! -f "$APPIMAGETOOL" ]; then
    echo "==> Downloading appimagetool..."
    curl -fSL -o "$APPIMAGETOOL" \
        "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$APPIMAGETOOL"
fi

echo "==> Building AppImage..."
ARCH=x86_64 "$APPIMAGETOOL" "$APPDIR" "$PROJECT_ROOT/NAIWeaver-x86_64.AppImage"

echo "==> Done: $PROJECT_ROOT/NAIWeaver-x86_64.AppImage"

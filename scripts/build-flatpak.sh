#!/usr/bin/env bash
# Package an existing Flutter Linux release bundle; run flutter build first.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUNDLE_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
MANIFEST="$PROJECT_ROOT/linux/packaging/flatpak/dev.naiweaver.app.json"

if [[ $# -gt 1 || ( $# -eq 1 && ! "$1" =~ ^(en|ja|zh)$ ) ]]; then
    echo "Usage: $0 [en|ja|zh] (must match the existing bundle's DEFAULT_LOCALE)" >&2
    exit 2
fi
LOCALE="${1:-en}"
SUFFIX=""
[[ "$LOCALE" == en ]] || SUFFIX="-$LOCALE"
OUTPUT="$PROJECT_ROOT/build/flatpak/NAIWeaver${SUFFIX}-x86_64.flatpak"

if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
    echo "Flatpak packaging requires an x86_64 Linux build host." >&2
    exit 1
fi
for tool in flatpak flatpak-builder python3; do
    command -v "$tool" >/dev/null || { echo "Missing build tool: $tool" >&2; exit 1; }
done
if [[ ! -x "$BUNDLE_DIR/naiweaver" || ! -d "$BUNDLE_DIR/data" ]]; then
    echo "Run flutter build linux --release before packaging." >&2
    exit 1
fi
bash "$SCRIPT_DIR/check-linux-onnx.sh" "$BUNDLE_DIR"

# Keep each run separate so a previous locale or stale build cannot leak in.
mkdir -p "$PROJECT_ROOT/build/flatpak"
WORK_DIR="$(mktemp -d "$PROJECT_ROOT/build/flatpak/work.XXXXXX")"
cd "$PROJECT_ROOT"
flatpak-builder --user --force-clean --disable-cache \
    --state-dir="$WORK_DIR/state" "$WORK_DIR/app" "$MANIFEST"

# Use the end-user runtime, not the SDK or the Ubuntu host. This catches missing
# shared libraries and GLIBC/GLIBCXX requirements in the precompiled bundle.
flatpak build --runtime "$WORK_DIR/app" sh -eu -c '
    which zenity
    for binary in /app/naiweaver/naiweaver /app/naiweaver/lib/*.so* /app/bin/zenity; do
        [ -f "$binary" ] || continue
        deps=$(ldd "$binary" 2>&1) || {
            case "$deps" in *"statically linked"*) continue ;; esac
            printf "%s\n%s\n" "$binary" "$deps" >&2
            exit 1
        }
        case "$deps" in
            *"not found"*) printf "%s\n%s\n" "$binary" "$deps" >&2; exit 1 ;;
        esac
    done
    /app/bin/zenity --version
'
# Also exercise the ONNX C API after relocation into /app (Python is in the SDK).
flatpak build "$WORK_DIR/app" bash -s -- /app/naiweaver \
    < "$SCRIPT_DIR/check-linux-onnx.sh"
flatpak build-export "$WORK_DIR/repo" "$WORK_DIR/app" experimental
flatpak build-bundle --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo \
    "$WORK_DIR/repo" "$OUTPUT" dev.naiweaver.app experimental
echo "Created $OUTPUT"

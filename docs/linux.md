# Linux installation and troubleshooting

## Steam Deck

Use Desktop Mode for installation and initial testing. A double-click that does
nothing does not identify the cause: launch the AppImage in Konsole and copy the
complete output. Executable permission is only one requirement. FUSE, a missing
shared library (including ONNX Runtime), or a GLIBC/GLIBCXX version mismatch can
also prevent startup.

For a FUSE error, try the extraction commands below; they do not require changing
SteamOS system packages or disabling its read-only filesystem. Extraction does
not fix missing libraries. Include your SteamOS version and the terminal error
when reporting a failure.

An [experimental Flatpak build](#experimental-flatpak) is available in the source
tree for testing. It has not yet been verified on Steam Deck hardware.

## Experimental Flatpak

The **Experimental Flatpak** GitHub Actions workflow builds
an x86_64 `.flatpak` artifact for the selected default language. It does not
publish a release or submit the application to Flathub. Until a tested build is
attached to a release, obtain it from a successful workflow run's artifacts and
extract the artifact ZIP first. Run it manually to select a language; relevant
pull requests also trigger an English build.

On Steam Deck in Desktop Mode, install the downloaded file in Konsole:

```bash
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user ./NAIWeaver-x86_64.flatpak
flatpak run dev.naiweaver.app//experimental
```

Use the actual filename for `-ja` or `-zh` builds. All variants share the same
application ID and replace one another. The first install needs internet access
to obtain the GNOME 49 runtime. Flatpak avoids AppImage's FUSE requirement and
provides the desktop libraries through that runtime. See
[Valve's desktop FAQ](https://help.steampowered.com/en/faqs/view/671A-4453-E8D2-323C)
for Steam Deck's Flatpak support.

The sandbox permits networking, graphics, audio, and access to the desktop's
Secret Service for secure API-key storage. A working, unlocked host keyring is
still needed. It includes Zenity because the current file-picker plugin launches
an external dialog tool. Home-folder access supports existing imports, exports,
and drag-and-drop; removable drives are not included by default. For SD-card
exports, grant the specific mounted directory, substituting its real path:

```bash
flatpak override --user --filesystem=/run/media/deck/YOUR_CARD dev.naiweaver.app
```

App data and preferences live under `~/.var/app/dev.naiweaver.app/` and are
separate from the AppImage's data. Existing presets, model downloads, and settings
are not automatically migrated. Bundle-only distribution also means installing
each newer `.flatpak` manually; there is no app update repository yet.

### Building and validating the Flatpak

On an x86_64 Linux build host, install the Flutter prerequisites below plus
`flatpak` and `flatpak-builder`, then:

```bash
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.gnome.Platform//49 org.gnome.Sdk//49
flutter pub get
flutter build linux --release --dart-define=DEFAULT_LOCALE=en
bash scripts/build-flatpak.sh en
```

The result is `build/flatpak/NAIWeaver-x86_64.flatpak`. Pass matching `ja` or `zh`
values to both commands for a localized build. The manifest packages the existing
Flutter bundle and builds a checksum-pinned Zenity from source. The workflow uses
Ubuntu 24.04; the script checks library resolution inside the GNOME **runtime**
and exercises the relocated ONNX C API in the SDK before exporting the bundle.
CI then installs the actual bundle and checks that it creates a visible window
and stays running under Xvfb with software rendering and a fresh D-Bus session.
The launch log is uploaded even if that step fails. This catches installation
and basic startup failures, but a visible window alone does not prove that the
Flutter UI initialized correctly or that interactive features work.
This is an experimental binary packaging route, not a Flathub source-build
manifest. Staging files remain under `build/flatpak/` for diagnosis.

Before adding Flatpak to regular releases, test on a Steam Deck: cold launch,
API-key save and reload, generation, file open/save and drag-and-drop, clipboard,
custom export folders/SD cards, ONNX model inference, and any supported audio
features. Check both the default Wayland session and X11 where available. The
dependency checks do not verify graphics, portals, keyring behavior, or these
interactive features.

## Running an AppImage

Download `NAIWeaver-x86_64.AppImage` (or a localized variant) from
[Releases](https://github.com/ststoryweaver/NAIWeaver/releases). The published
Linux AppImages target x86_64, not ARM64. You do not need Flutter to run them.

```bash
chmod +x NAIWeaver-x86_64.AppImage
./NAIWeaver-x86_64.AppImage
```

Run from a terminal when diagnosing startup failures so you can see the error.
The host needs GTK 3, libsecret, and a desktop keyring service for secure API-key
storage. On Ubuntu 24.04, install the runtime packages with:

```bash
sudo apt update
sudo apt install libgtk-3-0t64 libsecret-1-0 libfuse2t64 gnome-keyring
```

On Ubuntu 22.04 the corresponding GTK and FUSE package names are `libgtk-3-0`
and `libfuse2`. Other distributions use different package names.

If the error mentions FUSE or `libfuse.so.2`, you can also extract and run without
FUSE (substitute the actual downloaded filename):

```bash
./NAIWeaver-x86_64.AppImage --appimage-extract
./squashfs-root/AppRun
```

## ONNX Runtime versions

The committed `pubspec.lock` selects the Dart plugin **flutter_onnxruntime 1.6.3**.
Its supported native runtime is **Microsoft ONNX Runtime 1.22.0**. These are
separate version numbers; an `onnx`/`libonnx` package or a Python `onnxruntime`
installation is not a substitute for the native `libonnxruntime.so` library.

Linux builds from this source download the official CPU runtime during CMake
configuration and bundle it in `lib/`, including its versioned filenames and
symlinks. The app uses that copy without changing system packages. Internet
access to GitHub is needed on the first build. Installing CUDA alone does not
enable GPU inference with this CPU build.

Earlier builds could select a system runtime during compilation or package only
the unversioned `.so` name. If startup reports `libonnxruntime.so...: cannot open
shared object file`, that is a native-library loading failure. A system library
with a different version may not satisfy the build. Do not rename or symlink an
unrelated version to the requested name.

Prefer rebuilding from the corrected source below or using a release containing
the packaging fix. For an older AppImage that specifically requires **1.22.0**,
you can try an isolated workaround without downgrading system packages:

```bash
mkdir -p "$HOME/.local/opt/naiweaver-onnx"
cd "$HOME/.local/opt/naiweaver-onnx"
curl -fL -o onnxruntime-linux-x64-1.22.0.tgz \
  https://github.com/microsoft/onnxruntime/releases/download/v1.22.0/onnxruntime-linux-x64-1.22.0.tgz
tar -xzf onnxruntime-linux-x64-1.22.0.tgz
LD_LIBRARY_PATH="$PWD/onnxruntime-linux-x64-1.22.0/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  /absolute/path/to/NAIWeaver-x86_64.AppImage
```

Replace the final path with your downloaded AppImage. This sets the library
search path for that launch only. If the error names another version, or reports
a missing `GLIBC`/`GLIBCXX` version, keep the exact error for a bug report instead
of assuming a runtime downgrade will fix it.

## Building from source

Install [Flutter's Linux development prerequisites](https://docs.flutter.dev/platform-integration/linux/setup)
and a stable Flutter SDK that includes Dart **^3.10.7**. On Ubuntu/Debian:

```bash
sudo apt update
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev libsecret-1-dev curl python3
git clone https://github.com/ststoryweaver/NAIWeaver.git
cd NAIWeaver
flutter doctor -v
flutter pub get
flutter run -d linux
```

Use the committed lockfile; `flutter pub upgrade` may change the plugin and its
native runtime requirements. You do not need a system ONNX development package.
If rebuilding an older checkout, run `flutter clean` followed by `flutter pub get`
to clear its generated build files before building again.

For a release bundle or x86_64 AppImage:

```bash
flutter build linux --release
bash scripts/check-linux-onnx.sh build/linux/x64/release/bundle
bash scripts/build-appimage.sh
```

AppImage packaging also requires FUSE 2 to run `appimagetool` (`libfuse2t64` on
Ubuntu 24.04, `libfuse2` on Ubuntu 22.04). The packaging script downloads
`appimagetool` and checks that the relocated ONNX plugin resolves its runtime
inside the AppDir and exposes C API version 22 before creating the AppImage.

For a plain bundle, launch `build/linux/x64/release/bundle/naiweaver` and keep
its sibling `lib/` and `data/` directories. Copying only the executable will fail.

## What to include in a bug report

- Distribution and version (`cat /etc/os-release`) and architecture (`uname -m`).
- NAIWeaver version and whether you used an AppImage or built from source.
- The complete terminal error, especially the exact `.so` filename or version.
- For source builds, `flutter --version` and the output of the ONNX check above.

Upstream references: [flutter_onnxruntime](https://github.com/masicai/flutter_onnxruntime),
[ONNX Runtime 1.22.0](https://github.com/microsoft/onnxruntime/releases/tag/v1.22.0),
[AppImage FUSE troubleshooting](https://docs.appimage.org/user-guide/troubleshooting/fuse.html).

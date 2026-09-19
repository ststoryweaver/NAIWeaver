#!/usr/bin/env bash
# Check a relocated Flutter bundle/AppDir before publishing it.
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <bundle-or-AppDir>" >&2
    exit 2
fi

LIB_DIR="$(cd "$1/lib" && pwd -P)"
PLUGIN="$LIB_DIR/libflutter_onnxruntime_plugin.so"

# Clear inherited search paths: a system or developer runtime must not hide a
# missing bundled library. Check the plugin, whose dependencies are transitive
# from the executable and cannot rely on the executable's RUNPATH.
DEPS="$(env -u LD_LIBRARY_PATH -u LD_PRELOAD ldd "$PLUGIN")"
printf '%s\n' "$DEPS"
if [[ "$DEPS" == *"not found"* ]]; then
    echo "Linux bundle has unresolved plugin dependencies." >&2
    exit 1
fi
ORT_PATH="$(awk '/libonnxruntime\.so/ {print $3}' <<< "$DEPS")"
if [[ -z "$ORT_PATH" || "$(realpath "$ORT_PATH")" != "$LIB_DIR/"* ]]; then
    echo "ONNX Runtime must resolve inside the bundle's lib directory." >&2
    exit 1
fi

# Exercise the real C API without needing a display server or a model download.
env -u LD_LIBRARY_PATH -u LD_PRELOAD python3 - "$ORT_PATH" <<'PY'
import ctypes
import sys

get_api_type = ctypes.CFUNCTYPE(ctypes.c_void_p, ctypes.c_uint32)
get_version_type = ctypes.CFUNCTYPE(ctypes.c_char_p)

class OrtApiBase(ctypes.Structure):
    _fields_ = [("GetApi", get_api_type), ("GetVersionString", get_version_type)]

runtime = ctypes.CDLL(sys.argv[1])
runtime.OrtGetApiBase.restype = ctypes.POINTER(OrtApiBase)
api = runtime.OrtGetApiBase().contents
if not api.GetApi(22):
    raise SystemExit("Bundled ONNX Runtime does not support C API version 22.")
print("Bundled ONNX Runtime:", api.GetVersionString().decode())
PY

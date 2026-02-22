# Bundled DLLs

These DLLs are required at runtime for the Jukebox (MIDI playback) feature on Windows.
They are copied to the build output directory during the CMake build step.

## Files

| DLL | Library | Purpose |
|-----|---------|---------|
| `libfluidsynth-3.dll` | [FluidSynth](https://www.fluidsynth.org/) | Software SoundFont synthesizer for MIDI playback |
| `SDL3.dll` | [SDL 3](https://www.libsdl.org/) | Audio output backend used by FluidSynth |
| `sndfile.dll` | [libsndfile](https://libsndfile.github.io/libsndfile/) | Audio file I/O used by FluidSynth |

## Provenance

- **FluidSynth**: Open-source (LGPL-2.1). Pre-built from the FluidSynth GitHub releases.
- **SDL 3**: Open-source (zlib license). Pre-built from the SDL GitHub releases.
- **libsndfile**: Open-source (LGPL-2.1). Pre-built from the libsndfile GitHub releases.

## Updating

To update these DLLs:

1. Download the latest release builds from each project's GitHub releases page
2. Replace the DLLs in this directory
3. Test that MIDI playback still works: Tools > Slideshow > enable music, or open Jukebox

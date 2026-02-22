# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(naiweaver LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "naiweaver")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# --- ONNX Runtime GPU (CUDA) build override ---
# Download the GPU-enabled ONNX Runtime so flutter_onnxruntime picks up CUDA support.
set(ORT_VERSION "1.22.0")
set(ORT_GPU_ZIP "onnxruntime-win-x64-gpu-${ORT_VERSION}.zip")
set(ORT_GPU_URL "https://github.com/microsoft/onnxruntime/releases/download/v${ORT_VERSION}/${ORT_GPU_ZIP}")
set(ORT_GPU_DIR "${CMAKE_BINARY_DIR}/ort_gpu")
set(ORT_GPU_EXTRACT_DIR "${ORT_GPU_DIR}/onnxruntime-win-x64-gpu-${ORT_VERSION}")

if(NOT EXISTS "${ORT_GPU_EXTRACT_DIR}")
  message(STATUS "Downloading ONNX Runtime GPU ${ORT_VERSION}...")
  file(DOWNLOAD "${ORT_GPU_URL}" "${ORT_GPU_DIR}/${ORT_GPU_ZIP}"
    SHOW_PROGRESS
    STATUS ORT_DOWNLOAD_STATUS)
  list(GET ORT_DOWNLOAD_STATUS 0 ORT_DOWNLOAD_ERROR)
  if(ORT_DOWNLOAD_ERROR)
    message(WARNING "Failed to download ONNX Runtime GPU: ${ORT_DOWNLOAD_STATUS}")
  else()
    message(STATUS "Extracting ONNX Runtime GPU...")
    file(ARCHIVE_EXTRACT INPUT "${ORT_GPU_DIR}/${ORT_GPU_ZIP}"
      DESTINATION "${ORT_GPU_DIR}")
  endif()
endif()

if(EXISTS "${ORT_GPU_EXTRACT_DIR}")
  # Point flutter_onnxruntime at the GPU build instead of CPU
  set(ONNXRUNTIME_ROOT_DIR "${ORT_GPU_EXTRACT_DIR}" CACHE PATH "" FORCE)
  # Clear stale cached paths so find_library/find_path re-evaluate
  unset(ONNXRUNTIME_LIBRARY CACHE)
  unset(ONNXRUNTIME_INCLUDE_DIR CACHE)
  message(STATUS "ONNX Runtime GPU root: ${ORT_GPU_EXTRACT_DIR}")
endif()

# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)

# FluidSynth DLL for MIDI Jukebox
set(FLUIDSYNTH_DLL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dlls")
if(EXISTS "${FLUIDSYNTH_DLL_DIR}")
  file(GLOB FLUIDSYNTH_DLLS "${FLUIDSYNTH_DLL_DIR}/*.dll")
  if(FLUIDSYNTH_DLLS)
    install(FILES ${FLUIDSYNTH_DLLS}
      DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
      COMPONENT Runtime)
  endif()
endif()

# ONNX Runtime GPU DLLs (onnxruntime.dll, providers_shared, providers_cuda)
if(EXISTS "${ORT_GPU_EXTRACT_DIR}/lib")
  file(GLOB ORT_GPU_DLLS "${ORT_GPU_EXTRACT_DIR}/lib/*.dll")
  if(ORT_GPU_DLLS)
    install(FILES ${ORT_GPU_DLLS}
      DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
      COMPONENT Runtime)
  endif()
endif()

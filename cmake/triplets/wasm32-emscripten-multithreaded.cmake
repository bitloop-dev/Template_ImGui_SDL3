# SDL3's Emscripten Debug export references a removed debug/include directory.
set(VCPKG_BUILD_TYPE release)
include("${CMAKE_CURRENT_LIST_DIR}/../../vcpkg/triplets/community/wasm32-emscripten.cmake")

# Compile every dependency with the same shared-memory ABI as the application.
set(ENV{EMCC_CFLAGS} "$ENV{EMCC_CFLAGS} -pthread")

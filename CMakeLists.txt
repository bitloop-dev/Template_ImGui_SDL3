cmake_minimum_required(VERSION 3.21)
project(CGui LANGUAGES CXX)

set(APP "MyApp")
set(APP_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/include")

file(GLOB APP_HEADERS CONFIGURE_DEPENDS "${APP_INCLUDE_DIR}/*.h")
file(GLOB APP_SOURCE CONFIGURE_DEPENDS "${APP_INCLUDE_DIR}/*.cpp")

file(GLOB BACKEND_HEADERS CONFIGURE_DEPENDS "${APP_INCLUDE_DIR}/backend/*.h")
file(GLOB BACKEND_SOURCE CONFIGURE_DEPENDS "${APP_INCLUDE_DIR}/backend/*.cpp")

set_property(GLOBAL PROPERTY USE_FOLDERS ON)
source_group("backend" FILES ${BACKEND_HEADERS} ${BACKEND_SOURCE})

add_executable(${APP}
    ${APP_HEADERS}
    ${APP_SOURCE}
    ${BACKEND_HEADERS}
    ${BACKEND_SOURCE}
)

target_compile_features(${APP} PRIVATE cxx_std_23)
target_include_directories(${APP} PRIVATE ${APP_INCLUDE_DIR})
target_compile_definitions(${APP} PRIVATE APP_NAME="${APP}")

find_package(Freetype CONFIG REQUIRED)
find_package(SDL3 CONFIG REQUIRED)
find_package(imgui CONFIG REQUIRED)
find_package(NanoSVG CONFIG REQUIRED)
find_package(WebP CONFIG REQUIRED)
find_package(Stb REQUIRED)

target_link_libraries(${APP} PRIVATE 
    Freetype::Freetype
    SDL3::SDL3
    imgui::imgui
    NanoSVG::nanosvg NanoSVG::nanosvgrast
    WebP::webpdemux
)

target_include_directories(${APP} PRIVATE ${Stb_INCLUDE_DIR})

if (NOT EMSCRIPTEN)
    find_package(glad CONFIG REQUIRED)
    target_link_libraries(${APP} PRIVATE glad::glad)
    add_custom_target(app_data
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_CURRENT_SOURCE_DIR}/data"
            "$<TARGET_FILE_DIR:${APP}>/data"
        VERBATIM
    )
    add_dependencies(${APP} app_data)
endif()

if (WIN32)
    set_target_properties(${APP} PROPERTIES WIN32_EXECUTABLE TRUE)
endif()

if (MSVC)
    target_compile_options(${APP} PRIVATE /permissive- /W3 /WX /utf-8 /D_CRT_SECURE_NO_WARNINGS)
endif()

if (EMSCRIPTEN)
    target_compile_options(${APP} PRIVATE
        -O3
        -pthread
        -matomics
        -mbulk-memory

        $<$<CONFIG:RelWithDebInfo>:-g2>
        $<$<CONFIG:RelWithDebInfo>:-ffunction-sections>
        $<$<CONFIG:RelWithDebInfo>:-fdata-sections>
        $<$<CONFIG:RelWithDebInfo>:-flto>
    )

    file(GLOB_RECURSE APP_ASSETS CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/data/*")

    set_property(TARGET ${APP} APPEND PROPERTY LINK_DEPENDS
        ${APP_ASSETS} "${CMAKE_CURRENT_SOURCE_DIR}/static/shell.html")
    set_target_properties(${APP} PROPERTIES OUTPUT_NAME "index" SUFFIX ".html")

    target_link_options(${APP} PRIVATE
        -pthread
        -sFULL_ES3=1
        -sPTHREAD_POOL_SIZE=32
        -sPTHREAD_POOL_SIZE_STRICT=0
        -sPTHREADS_DEBUG=0
        "--embed-file=${CMAKE_CURRENT_SOURCE_DIR}/data@/data"
        "--shell-file=${CMAKE_CURRENT_SOURCE_DIR}/static/shell.html"
        -sMIN_WEBGL_VERSION=2
        -sMAX_WEBGL_VERSION=2
        -sALLOW_MEMORY_GROWTH=1
        "-sEXPORTED_RUNTIME_METHODS=['ccall','UTF8ToString','stringToUTF8','lengthBytesUTF8']"

        $<$<CONFIG:RelWithDebInfo>:--profiling-funcs>
        $<$<CONFIG:RelWithDebInfo>:-Wl,--gc-sections>
        $<$<CONFIG:RelWithDebInfo>:-flto>
        $<$<CONFIG:RelWithDebInfo>:-sASSERTIONS>
    )
endif()

cmake_minimum_required(VERSION 3.24 FATAL_ERROR)

project(objectool VERSION 1.20 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

set(OBJECTOOL_LIBRARIES "")
set(OBJECTOOL_SOURCE "")

add_subdirectory("include")

list(APPEND OBJECTOOL_SOURCE
    "objectool.cpp"

    "include/misc.cpp"
    "include/tooltip.cpp"
    "include/rom.cpp"
    "include/settings.cpp"

    "resources/objectool.rc"
)

if(ASAR_DYNAMIC_LINK)
    list(APPEND OBJECTOOL_SOURCE
        "include/asar/asardll.h"
        "include/asar/asardll.c"
    )
endif()

add_executable(objectool ${OBJECTOOL_SOURCE})

list(APPEND OBJECTOOL_LIBRARIES PRIVATE fmt::fmt)
if(NOT ASAR_DYNAMIC_LINK)
    target_link_libraries(objectool PRIVATE asar-static)
else()
    target_compile_definitions(objectool PRIVATE ASAR_DYNAMIC_LINK)
endif()

target_link_libraries(objectool ${OBJECTOOL_LIBRARIES})

if (CMAKE_BUILD_TYPE STREQUAL "Debug" AND LINUX)
    target_compile_options(objectool PRIVATE -fsanitize=address)
    target_link_options(objectool PRIVATE -fsanitize=address)
endif()


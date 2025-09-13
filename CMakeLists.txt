cmake_minimum_required(VERSION 3.13)
project(metalib)

#https://github.com/andrew-hardin/cmake-git-version-tracking

include(CheckIPOSupported)
check_ipo_supported(RESULT lto_supported OUTPUT error)

# Define the two required variables before including
# the source code for watching a git repository.
set(PRE_CONFIGURE_FILE "git.cc.in")
set(POST_CONFIGURE_FILE "${CMAKE_CURRENT_BINARY_DIR}/git.cc")
include(git_watcher.cmake)

# Create a library out of the compiled post-configure file.
add_library(git STATIC ${POST_CONFIGURE_FILE})
target_include_directories(git PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
set_target_properties (git PROPERTIES FOLDER ${PROJECT_NAME})
add_dependencies(git check_git)

# Setup a demo executable that links to the git library.
add_executable(demo EXCLUDE_FROM_ALL main.cc)
target_link_libraries(demo git)
set_target_properties (demo PROPERTIES FOLDER ${PROJECT_NAME})

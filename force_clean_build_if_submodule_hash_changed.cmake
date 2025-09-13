# Function to get the combined hash of all submodules
function(get_combined_submodule_hash COMBINED_HASH_VAR)
    find_package(Git QUIET)
    if(GIT_FOUND)
        # Get the list of all submodule hashes
        execute_process(
            COMMAND ${GIT_EXECUTABLE} submodule status --recursive
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE SUBMODULE_STATUS
        )
        # Extract the hashes from the status output
        string(REGEX MATCHALL "[^ ]+ ([a-f0-9]+)" SUBMODULE_HASHES "${SUBMODULE_STATUS}")
        string(REGEX REPLACE "[^ ]+ " "" SUBMODULE_HASHES "${SUBMODULE_HASHES}")
        # Combine all hashes into a single string
        string(REPLACE ";" "" COMBINED_HASH "${SUBMODULE_HASHES}")
        set(${COMBINED_HASH_VAR} ${COMBINED_HASH} PARENT_SCOPE)
    else()
        message(WARNING "Git not found. Cannot detect submodule changes.")
        set(${COMBINED_HASH_VAR} "unknown" PARENT_SCOPE)
    endif()
endfunction()

# Get the combined hash of all submodules
get_combined_submodule_hash(CURRENT_COMBINED_HASH)

# File to store the previous combined hash
set(HASH_FILE "${CMAKE_BINARY_DIR}/submodule_combined_hash.txt")

# Read the previous combined hash from the file (if it exists)
if(EXISTS ${HASH_FILE})
    file(READ ${HASH_FILE} PREVIOUS_COMBINED_HASH)
    string(STRIP ${PREVIOUS_COMBINED_HASH} PREVIOUS_COMBINED_HASH)
else()
    if (ON_BUILD_SERVER)
        set(PREVIOUS_COMBINED_HASH "unknown")
    else()
        message("No previous submodule hash cache, assuming new build and submodules don't need to be cleaned")
        set(PREVIOUS_COMBINED_HASH ${CURRENT_COMBINED_HASH})
        file(WRITE ${HASH_FILE} ${CURRENT_COMBINED_HASH})
    endif()
endif()

# Compare the combined hashes
if(NOT ${CURRENT_COMBINED_HASH} STREQUAL ${PREVIOUS_COMBINED_HASH})
    if (ON_BUILD_SERVER)
        message(STATUS "Submodules have changed. Forcing a clean build.")
        execute_process(
            COMMAND ${GIT_EXECUTABLE} clean -X -f -d  -- ${CMAKE_BINARY_DIR}
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            )

        # Write the new combined hash to the file
        file(WRITE ${HASH_FILE} ${CURRENT_COMBINED_HASH})
        message(FATAL_ERROR "Build dir cleaned due to submodules changing, please rerun cmake")
    else()
        message(WARNING "Submodule checkins have changed.  I strongly recommend a clean build, including 3rdparty/build")
    endif()
else()
    message(STATUS "Submodules are up to date. Proceeding with the build.")
endif()

# Small downstream corrections, compiled from generated copies. Keep pinned
# submodule checkouts untouched and fail if upstream source no longer matches.
function(northrend_correct_source target relative_path before after)
    set(original "${CMAKE_SOURCE_DIR}/${relative_path}")
    file(READ "${original}" contents)
    string(FIND "${contents}" "${before}" match)
    if (match EQUAL -1)
        message(FATAL_ERROR "Dependency correction no longer applies: ${relative_path}")
    endif ()
    string(REPLACE "${before}" "${after}" contents "${contents}")
    set(corrected "${CMAKE_BINARY_DIR}/dependency-fixes/${relative_path}")
    get_filename_component(directory "${corrected}" DIRECTORY)
    file(MAKE_DIRECTORY "${directory}")
    file(WRITE "${corrected}" "${contents}")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${original}")
    get_target_property(sources ${target} SOURCES)
    list(REMOVE_ITEM sources "${original}")
    set_property(TARGET ${target} PROPERTY SOURCES "${sources};${corrected}")
    get_filename_component(original_directory "${original}" DIRECTORY)
    target_include_directories(${target} PRIVATE "${original_directory}")
endfunction()

# PrependDefaultDir can return the input filename without filling newfilename.
# Create the parent directory of the actual filename in either case.
northrend_correct_source(storm lib/squall/storm/Log.cpp
    "CreateFileDirectory(newfilename);" "CreateFileDirectory(fileName);")

# Assertions use a registered callback, not an automatically discovered symbol.
northrend_correct_source(BcTest lib/bc/test/Debug.cpp
    "        BC_ASSERT(0);"
    "        s_assertion_failed = false;\n        Blizzard::Debug::SetAssertHandler(AssertCallback);\n        BC_ASSERT(0);\n        Blizzard::Debug::SetAssertHandler(nullptr);")

# maxChars includes the terminator. Keep testing both truncation and cursor.
northrend_correct_source(CommonTest lib/common/test/DataStore.cpp
    "SStrCmp(readVal, \"foo\", STORM_MAX_STR)"
    "SStrCmp(readVal, \"fo\", STORM_MAX_STR)")

# GCC does not obtain memset through the unrelated transitive headers.
northrend_correct_source(common lib/common/common/memory/CDataAllocator.cpp
    "#include <algorithm>" "#include <algorithm>\n#include <cstring>")

# Fatal functions promise not to return. Preserve platform error presentation,
# then provide a terminal diagnostic and terminate if that handler returns.
northrend_correct_source(storm lib/squall/storm/error/Error.cpp
    "    SErrDisplayError(STORM_ERROR_APPLICATION_FATAL, s_appFatInfo.filename, s_appFatInfo.linenumber, buffer, 0, 1, 0);"
    "    SErrDisplayError(STORM_ERROR_APPLICATION_FATAL, s_appFatInfo.filename, s_appFatInfo.linenumber, buffer, 0, 1, 0);\n    std::fprintf(stderr, \"Fatal initialization error: %s\\n\", buffer);\n    std::abort();")

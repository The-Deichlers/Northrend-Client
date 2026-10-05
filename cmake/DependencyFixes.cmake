# Small downstream corrections, compiled from generated copies. Keep pinned
# submodule checkouts untouched and fail if upstream source no longer matches.
function(northrend_write_correction path contents)
    file(WRITE "${path}.in" "${contents}")
    configure_file("${path}.in" "${path}" COPYONLY)
endfunction()

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
    northrend_write_correction("${corrected}" "${contents}")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${original}")
    get_target_property(sources ${target} SOURCES)
    list(REMOVE_ITEM sources "${original}")
    set_property(TARGET ${target} PROPERTY SOURCES "${sources};${corrected}")
    get_filename_component(original_directory "${original}" DIRECTORY)
    target_include_directories(${target} PRIVATE "${original_directory}")
endfunction()

# VFormat must use the translated format, not uninitialized destination bytes.
# File lookup diagnostics exercise this on every MPQ fallback during startup.
northrend_correct_source(bc lib/bc/bc/string/Format.cpp
    "    formatNative = buffer;"
    "    formatNative = translatedformat;")

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

# C++ destroys members automatically after the destructor body. An explicit
# member destructor here causes a second destruction and a GCC Release double free.
set(sorted_array_original "${CMAKE_SOURCE_DIR}/lib/common/common/array/CSimpleSortedArray.hpp")
file(READ "${sorted_array_original}" sorted_array_contents)
string(FIND "${sorted_array_contents}" "    m_array.~TSGrowableArray();" sorted_array_match)
if (sorted_array_match EQUAL -1)
    message(FATAL_ERROR "Sorted-array destructor correction no longer applies")
endif ()
string(REPLACE "    m_array.~TSGrowableArray();" "    // m_array is destroyed automatically after this body." sorted_array_contents "${sorted_array_contents}")
set(sorted_array_include "${CMAKE_BINARY_DIR}/dependency-fixes/lib/common")
file(MAKE_DIRECTORY "${sorted_array_include}/common/array")
northrend_write_correction("${sorted_array_include}/common/array/CSimpleSortedArray.hpp" "${sorted_array_contents}")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${sorted_array_original}")
target_include_directories(common BEFORE PUBLIC "${sorted_array_include}")
target_include_directories(CommonTest BEFORE PRIVATE "${sorted_array_include}")

# Clear must release storage without ending the lifetime of this polymorphic
# object. Calling Constructor after an explicit destructor is undefined behavior.
set(fixed_array_original "${CMAKE_SOURCE_DIR}/lib/squall/storm/array/TSFixedArray.hpp")
file(READ "${fixed_array_original}" fixed_array_contents)
set(fixed_array_before "    this->~TSFixedArray<T>();\n    this->Constructor();")
string(FIND "${fixed_array_contents}" "${fixed_array_before}" fixed_array_match)
if (fixed_array_match EQUAL -1)
    message(FATAL_ERROR "Fixed-array Clear correction no longer applies")
endif ()
set(fixed_array_after "    for (uint32_t i = 0; i < this->Count(); ++i) {\n        auto element = &this->operator[](i);\n        element->~T();\n    }\n    if (this->Ptr()) {\n        SMemFree(this->Ptr(), this->MemFileName(), this->MemLineNo(), 0x0);\n    }\n    this->Constructor();")
string(REPLACE "${fixed_array_before}" "${fixed_array_after}" fixed_array_contents "${fixed_array_contents}")
set(fixed_array_include "${CMAKE_BINARY_DIR}/dependency-fixes/lib/squall")
file(MAKE_DIRECTORY "${fixed_array_include}/storm/array")
northrend_write_correction("${fixed_array_include}/storm/array/TSFixedArray.hpp" "${fixed_array_contents}")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${fixed_array_original}")
target_include_directories(storm BEFORE PUBLIC "${fixed_array_include}")
target_include_directories(StormTest BEFORE PRIVATE "${fixed_array_include}")

# Zero has no binary bytes and therefore no backing buffer. Even a zero-byte
# memcpy requires nonnull pointers under the standard library's contract.
northrend_correct_source(storm lib/squall/storm/Big.cpp
    "    memcpy(data, output.Ptr(), n);"
    "    if (n) {\n        memcpy(data, output.Ptr(), n);\n    }")

# Decimal digit weights form a 20-by-10 table. Flattening through row zero
# crosses that row's bounds even when the address lies within the whole table.
northrend_correct_source(storm lib/squall/storm/String.cpp
    "s_realDigit[0][v25 + v23]" "s_realDigit[v24][v23]")

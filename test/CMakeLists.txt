if (WHOA_SYSTEM_MAC)
    file(GLOB PRIVATE_SOURCES "Test.cpp" "stub/Mac.mm" "gx/*.cpp" "util/*.cpp")

    set_source_files_properties(${PRIVATE_SOURCES}
        PROPERTIES COMPILE_FLAGS "-x objective-c++"
    )

    add_executable(WhoaTest ${PRIVATE_SOURCES})

    target_link_libraries(WhoaTest
        PRIVATE
            event
            client
            gx
            util
            "-framework AppKit"
            "-framework Carbon"
            "-framework IOKit"
    )
endif ()

if (WHOA_SYSTEM_WIN OR WHOA_SYSTEM_LINUX)
    file(GLOB PRIVATE_SOURCES "Test.cpp" "gx/*.cpp" "util/*.cpp")

    add_executable(WhoaTest ${PRIVATE_SOURCES})

    target_link_libraries(WhoaTest
        PRIVATE
            event
            client
            gx
            util
    )
endif ()

target_include_directories(WhoaTest
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src
        ${CMAKE_SOURCE_DIR}/vendor/catch2-2.13.10
)

install(TARGETS WhoaTest DESTINATION "bin")

if (BUILD_TESTING)
    foreach (test_target WhoaTest BcTest StormTest TempestTest CommonTest)
        add_test(NAME ${test_target} COMMAND ${test_target})
    endforeach ()
    foreach (startup_case missing-value invalid-directory unknown-option missing-data)
        add_test(NAME startup-${startup_case}
            COMMAND ${CMAKE_COMMAND}
                -DCLIENT=$<TARGET_FILE:Northrend>
                -DCASE=${startup_case}
                -DSCRATCH=${CMAKE_CURRENT_BINARY_DIR}/startup-${startup_case}
                -P ${CMAKE_CURRENT_SOURCE_DIR}/StartupFailure.cmake)
    endforeach ()
endif ()

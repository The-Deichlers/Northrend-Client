if (WHOA_SYSTEM_WIN)
    file(GLOB PRIVATE_SOURCES "win/*.cpp" "win/Whoa.rc")

    add_executable(Northrend WIN32 ${PRIVATE_SOURCES})

    # Set debug icon and description if in debug mode
    if (CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(CMAKE_RC_FLAGS ${CMAKE_RC_FLAGS} -DWHOA_APP_DEBUG)
    endif ()

    target_link_libraries(Northrend
        PRIVATE
            client
            event
            gx
            net
            util
        )
endif ()

if (WHOA_SYSTEM_MAC)
    file(GLOB PRIVATE_SOURCES "mac/*.cpp" "mac/*.mm")

    set_source_files_properties(${PRIVATE_SOURCES}
        PROPERTIES COMPILE_FLAGS "-x objective-c++"
    )

    add_executable(Northrend ${PRIVATE_SOURCES})

    target_link_libraries(Northrend
        PRIVATE
            client
            event
            gx
            net
            util
            "-framework AppKit"
            "-framework Carbon"
            "-framework IOKit"
    )

    find_program(IBTOOL_EXECUTABLE ibtool)
    if (NOT IBTOOL_EXECUTABLE)
        message(FATAL_ERROR "ibtool is required to compile Northrend menu resources; install Xcode")
    endif ()
    set(NORTHREND_MENU_NIB "${CMAKE_CURRENT_BINARY_DIR}/MainMenu.nib")
    add_custom_command(OUTPUT "${NORTHREND_MENU_NIB}"
        COMMAND "${IBTOOL_EXECUTABLE}" --compile "${NORTHREND_MENU_NIB}"
            "${CMAKE_CURRENT_SOURCE_DIR}/mac/MainMenu.xib"
            --minimum-deployment-target "${CMAKE_OSX_DEPLOYMENT_TARGET}"
        DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/mac/MainMenu.xib"
        VERBATIM)
    add_custom_target(northrend_menu DEPENDS "${NORTHREND_MENU_NIB}")
    add_dependencies(Northrend northrend_menu)
    add_custom_command(TARGET Northrend POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${NORTHREND_MENU_NIB}"
            "$<TARGET_FILE_DIR:Northrend>/MainMenu.nib")
    install(DIRECTORY "${NORTHREND_MENU_NIB}" DESTINATION "bin")
endif ()

if (WHOA_SYSTEM_LINUX)
    file(GLOB PRIVATE_SOURCES "linux/*.cpp")

    add_executable(Northrend ${PRIVATE_SOURCES})

    target_link_libraries(Northrend
        PRIVATE
            client
            event
            gx
            net
            util
    )
endif ()

target_include_directories(Northrend
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

install(TARGETS Northrend DESTINATION "bin")

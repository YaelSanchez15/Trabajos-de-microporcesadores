
cmake_minimum_required(VERSION 3.12)

set(PICO_BOARD pico_w)

# Pull in SDK (must be before project)
include(pico_sdk_import.cmake)

project(proyectos-pico)


# Initialize the SDK
pico_sdk_init()


add_executable(OLEDY
        OLEDY.c
        )

target_include_directories(OLEDY PRIVATE
        ${CMAKE_CURRENT_LIST_DIR}# for our common lwipopts
        )



# create map/bin/hex file etc.
# pico_enable_stdio_usb(OLEDY 1)
# create map/bin/hex file etc.
pico_add_extra_outputs(OLEDY)




target_link_libraries(OLEDY
        pico_stdlib
	hardware_i2c
        )



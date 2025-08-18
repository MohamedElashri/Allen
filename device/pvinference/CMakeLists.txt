###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB pvinference_sources "src/*cu" "src/*cpp")

include_directories(include)
include_directories(${PROJECT_SOURCE_DIR}/device/velo/common/include)
include_directories(${PROJECT_SOURCE_DIR}/device/event_model/common/include)
include_directories(${PROJECT_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${PROJECT_SOURCE_DIR}/main/include)
include_directories(${PROJECT_SOURCE_DIR}/stream/gear/include)
include_directories(${PROJECT_SOURCE_DIR}/stream/sequence/include)

# Embed binary weights file
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/include/pvfinder_weights.bin" weights_content HEX)
string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1," weights_content ${weights_content})
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/include/pvfinder_weights.bin"
    "${CMAKE_CURRENT_BINARY_DIR}/pvfinder_weights.bin"
    COPYONLY
)

# Use objcopy to embed binary as object file
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/pvfinder_weights.o
    COMMAND ${CMAKE_OBJCOPY} -I binary -O elf64-x86-64 -B i386:x86-64
            --rename-section .data=.rodata,alloc,load,readonly,data,contents
            --redefine-sym _binary_pvfinder_weights_bin_start=_binary_pvfinder_weights_bin_start
            --redefine-sym _binary_pvfinder_weights_bin_end=_binary_pvfinder_weights_bin_end
            ${CMAKE_CURRENT_BINARY_DIR}/pvfinder_weights.bin
            ${CMAKE_CURRENT_BINARY_DIR}/pvfinder_weights.o
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/pvfinder_weights.bin
    COMMENT "Embedding binary weights"
)

add_custom_target(pvinference_weights_embed
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/pvfinder_weights.o
)

allen_add_device_library(pvinference STATIC
    ${pvinference_sources}
    ${CMAKE_CURRENT_BINARY_DIR}/pvfinder_weights.o
)

add_dependencies(pvinference pvinference_weights_embed)

target_link_libraries(pvinference PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(pvinference PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

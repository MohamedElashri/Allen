###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
# Gear interface library
add_library(Gear INTERFACE)
target_include_directories(Gear INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/gear/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/store/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/sequence/include>)
target_link_libraries(Gear INTERFACE Boost::boost)
install(TARGETS Gear EXPORT Allen)

include(GenerateConfiguration)

file(GLOB stream_src "sequence/src/*cpp")

allen_add_host_library(Stream STATIC ${stream_src})

target_link_libraries(Stream
  PRIVATE
    HostEventModel
    EventModel
    Backend
    AllenCommon
    Gear
    track_matching
    MuonCommon
  )

if(STANDALONE)
  add_dependencies(Stream checkout_lhcb checkout_gaudi)
endif()

foreach(sequence ${BUILD_SEQUENCES})
  generate_sequence(${sequence})
endforeach()

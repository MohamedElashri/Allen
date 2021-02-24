###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB selection_checker_sources "src/*.cpp")

allen_add_host_library(SelChecking STATIC
  ${selection_checker_sources}
)
set_target_properties(SelChecking PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(SelChecking PUBLIC include)
target_link_libraries(SelChecking PRIVATE HostEventModel EventModel Gear Backend Common TrackChecking)

if(USE_ROOT AND ROOT_FOUND)
  target_compile_definitions(SelChecking PRIVATE ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(SelChecking SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
endif()

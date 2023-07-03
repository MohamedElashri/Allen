###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
if (NOT STANDALONE)
  allen_add_host_library(ZMQSvc SHARED src/svc.cpp)
  target_include_directories(ZMQSvc PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/compat>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/svc>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/serialize>)
  target_link_libraries(ZMQSvc PUBLIC
    AIDA::aida
    Boost::filesystem
    Gaudi::GaudiKernel
    LHCb::ZMQLib
    LHCbEvent
    PRIVATE
    EventModel
    AllenCommon)

  add_library(AllenZMQ INTERFACE)
  install(TARGETS AllenZMQ EXPORT Allen)
  target_link_libraries(AllenZMQ INTERFACE ZMQSvc LHCb::ZMQLib)
else()
  allen_add_host_library(AllenZMQ SHARED src/functions.cpp src/svc.cpp)
  target_include_directories(AllenZMQ PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/serialize>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/compat>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/svc>
    ${PROJECT_SOURCE_DIR}/main/include)
  target_compile_definitions(AllenZMQ PUBLIC STANDALONE)
  target_link_libraries(AllenZMQ PUBLIC AllenCommon PkgConfig::zmq PkgConfig::sodium Boost::headers LHCbEvent)
endif()

function(zmq_program)
  cmake_parse_arguments(PARSED_ARGS "" "NAME;SRC" "" ${ARGN})
  add_executable(${PARSED_ARGS_NAME} ${PARSED_ARGS_SRC})
  target_include_directories(${PARSED_ARGS_NAME} PRIVATE
    ${PROJECT_SOURCE_DIR}/mdf/include)

  find_package(Threads REQUIRED)
  target_link_libraries(${PARSED_ARGS_NAME} PRIVATE Boost::program_options AllenZMQ mdf AllenFS Threads::Threads LHCbEvent EventModel AllenCommon)
  if (NOT STANDALONE)
    find_package(fmt REQUIRED)
    target_link_libraries(${PARSED_ARGS_NAME} PRIVATE fmt::fmt)
  endif()

  install(TARGETS ${PARSED_ARGS_NAME} RUNTIME DESTINATION bin OPTIONAL)
endfunction()

# MDF receiver to receive output events from integration test
zmq_program(NAME allen_mdf_receiver SRC src/MDFReceiver.cpp)

if (BUILD_TESTING)
  # Simple MDF sender to test MDF receiver
  zmq_program(NAME allen_mdf_sender SRC test/mdf_sender.cpp)
endif()

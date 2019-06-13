set(ZMQ_VERSION 4.1.3)


find_package(ZMQ QUIET)
if (ZMQ_FOUND)
  message(STATUS "Found zmq: ${ZMQ_INCLUDE_DIRS}")
  set(ZMQ_BUILTIN FALSE)
else()
  set(ZMQ_BUILTIN TRUE)
  message(STATUS "Building internal 0MQ version ${ZMQ_VERSION}")
  set(ZMQ_DESTDIR "${CMAKE_BINARY_DIR}/${EXTERNAL_DIR}")

  ExternalProject_Add(ZMQ
    URL "https://github.com/zeromq/libzmq/archive/v${ZMQ_VERSOIN}.tar.gz"
    URL_HASH SHA256=e1dec061725b55d791e0c6952b8c220846c8cd901c09d1283a6e902898205b9d
    BUILD_IN_SOURCE 0
    INSTALL_DIR ${ZMQ_DESTDIR}
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    CMAKE_ARGS -G ${CMAKE_GENERATOR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
    -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    STEP_TARGETS install)

endif()

file(GLOB SOURCES "src/*.cpp")
add_library(AllenZMQ ${SOURCES})
target_include_directories(AllenZMQ PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include ${ZMQ_INCLUDE_DIRS})
target_link_libraries(AllenZMQ PUBLIC ${ZMQ_LIBRARIES})

if (ZMQ_BUILTIN)
  add_dependencies(AllenZMQ ZMQ-install)
endif()

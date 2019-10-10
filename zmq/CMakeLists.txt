set(ZMQ_VERSION 4.3.2)

find_package(ZMQ QUIET)
if (ZMQ_FOUND)
  message(STATUS "Found ZMQ: ${ZMQ_INCLUDE_DIRS}")
  set(ZMQ_BUILTIN FALSE)
else()
  set(ZMQ_BUILTIN TRUE)
  message(STATUS "Building internal ZMQ version ${ZMQ_VERSION}")
  set(ZMQ_DESTDIR "${CMAKE_BINARY_DIR}/${EXTERNAL_DIR}")

  include(ExternalProject)
  include(FindPackageHandleStandardArgs)
  ExternalProject_Add(BuiltinZMQ
    URL "https://github.com/zeromq/libzmq/archive/v${ZMQ_VERSION}.tar.gz"
    URL_HASH SHA256=02ecc88466ae38cf2c8d79f09cfd2675ba299a439680b64ade733e26a349edeb
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
    -DBUILD_TESTS=OFF
    STEP_TARGETS install)

  set(ZMQ_LIBRARIES "-L${ZMQ_DESTDIR}/lib64" zmq)
  set(ZMQ_INCLUDE_DIRS "${ZMQ_DESTDIR}/include")

  find_package_handle_standard_args(ZMQ
    FOUND_VAR ZMQ_FOUND
    REQUIRED_VARS ZMQ_INCLUDE_DIRS ZMQ_LIBRARIES
    VERSION_VAR ZMQ_VERSION)

endif()

find_package(Boost COMPONENTS serialization iostreams)

file(GLOB SOURCES "src/*.cpp")
allen_add_library(AllenZMQ ${SOURCES})
target_include_directories(AllenZMQ PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_include_directories(AllenZMQ PUBLIC ${CMAKE_SOURCE_DIR}/main/include)
target_include_directories(AllenZMQ SYSTEM PUBLIC ${ZMQ_INCLUDE_DIRS} ${Boost_INCLUDE_DIR})
target_link_libraries(AllenZMQ PUBLIC ${ZMQ_LIBRARIES})

if (ZMQ_BUILTIN)
  add_dependencies(AllenZMQ BuiltinZMQ-install)
elseif(GaudiProject_FOUND)
  find_library(SODIUM_LIBRARY NAMES sodium
               HINTS $ENV{libsodium_ROOT_DIR}/lib ${libsodium_ROOT_DIR}/lib)
  if(SODIUM_LIBRARY)
    message(STATUS "Found ${SODIUM_LIBRARY}")
    get_filename_component(SODIUM_LIBRARY_DIR "${SODIUM_LIBRARY}" PATH)
    gaudi_env(PREPEND LD_LIBRARY_PATH "${SODIUM_LIBRARY_DIR}")
    target_link_libraries(AllenZMQ PUBLIC ${SODIUM_LIBRARY})
  endif()
endif()

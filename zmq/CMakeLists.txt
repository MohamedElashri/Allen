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

find_package(Boost COMPONENTS serialization iostreams program_options filesystem)

if (GaudiProject_FOUND)
  find_package(AIDA REQUIRED)
  find_package(ROOT REQUIRED)
  add_library(AllenZMQ INTERFACE)
  allen_add_host_library(ZMQSvc SHARED src/svc.cpp)
  target_include_directories(ZMQSvc PUBLIC compat include)
  target_include_directories(ZMQSvc SYSTEM PUBLIC
    ${ROOT_INCLUDE_DIRS}
    ${ZMQ_INCLUDE_DIRS}
    ${Boost_INCLUDE_DIR}
    ${AIDA_INCLUDE_DIRS})
  target_link_libraries(ZMQSvc PUBLIC GaudiKernel
    Boost::filesystem
    ${ZMQ_LIBRARIES}
    ${ALLEN_ROOT_LIBRARIES})

  find_library(SODIUM_LIBRARY NAMES sodium
               HINTS $ENV{libsodium_ROOT_DIR}/lib ${libsodium_ROOT_DIR}/lib)
  if(SODIUM_LIBRARY)
    message(STATUS "Found ${SODIUM_LIBRARY}")
    get_filename_component(SODIUM_LIBRARY_DIR "${SODIUM_LIBRARY}" PATH)
    gaudi_env(PREPEND LD_LIBRARY_PATH "${SODIUM_LIBRARY_DIR}")
    target_link_libraries(ZMQSvc PUBLIC ${SODIUM_LIBRARY})
  endif()

  target_link_libraries(AllenZMQ INTERFACE ZMQSvc ZMQLib)
else()
  allen_add_host_library(AllenZMQ src/functions.cpp src/svc.cpp)
  target_include_directories(AllenZMQ PUBLIC
    include
    compat
    ${CMAKE_SOURCE_DIR}/main/include)
  target_include_directories(AllenZMQ PUBLIC SYSTEM ${ZMQ_INCLUDE_DIRS} ${Boost_INCLUDE_DIR})
  target_compile_definitions(AllenZMQ PUBLIC STANDALONE)
  target_link_libraries(AllenZMQ PUBLIC ${ZMQ_LIBRARIES})

  if (WITH_ROOT AND USE_ROOT)
    target_include_directories(AllenZMQ SYSTEM PUBLIC ${ROOT_INCLUDE_DIRS})
  endif()

  if (ZMQ_BUILTIN)
    add_dependencies(AllenZMQ BuiltinZMQ-install)
  endif()
endif()

function(zmq_program)
  cmake_parse_arguments(PARSED_ARGS "" "NAME;SRC" "" ${ARGN})
  add_executable(${PARSED_ARGS_NAME} ${PARSED_ARGS_SRC})
  target_include_directories(${PARSED_ARGS_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/mdf/include)
  target_link_libraries(${PARSED_ARGS_NAME} PRIVATE Boost::program_options AllenZMQ mdf allen_fs)
  install(TARGETS ${PARSED_ARGS_NAME} RUNTIME DESTINATION bin OPTIONAL)
endfunction()

# MDF receiver to receive output events from integration test
zmq_program(NAME allen_mdf_receiver SRC src/MDFReceiver.cpp)

if (BUILD_TESTS)
  # Simple MDF sender to test MDF receiver
  zmq_program(NAME allen_mdf_sender SRC test/mdf_sender.cpp)
endif()

include_directories(${CPPGSL_INCLUDE_DIR})

set(EXTERNAL_DIR "external")

set(pybind11_VERSION 2.2.4)

find_package(pybind11 QUIET)
if (pybind11_FOUND)
  message(STATUS "Found pybind11: ${pybind11_INCLUDE_DIRS}/pybind11")
  set(pybind11_BUILTIN FALSE)
else()
  include(ExternalProject)
  set(pybind11_BUILTIN TRUE)
  message(STATUS "Building internal pybind11 version ${pybind11_VERSION}")
  set(pybind11_DESTDIR "${CMAKE_BINARY_DIR}/${EXTERNAL_DIR}")

  ExternalProject_Add(pybind11
    URL "https://github.com/pybind/pybind11/archive/v${pybind11_VERSION}.tar.gz"
    URL_HASH SHA256=b69e83658513215b8d1443544d0549b7d231b9f201f6fc787a2b2218b408181e
    BUILD_IN_SOURCE 0
    INSTALL_DIR ${pybind11_DESTDIR}
    LOG_DOWNLOAD 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
    CMAKE_ARGS -G ${CMAKE_GENERATOR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
    -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
    -DPYBIND11_TEST=OFF
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    STEP_TARGETS install)
endif()

include(pybind11Tools)
pybind11_add_module(PyAllen "src/bindings.cpp")
# C++17 + python2.7 warnings about register keyword
target_compile_options(PyAllen PRIVATE "-Wno-register")

target_include_directories(PyAllen PUBLIC ${pybind11_DESTDIR}/include)
target_link_libraries(PyAllen PRIVATE AllenLib)

# Make this easily importable from the build dir
file(TOUCH "${CMAKE_BINARY_DIR}/bindings/__init__.py")

if(pybind11_BUILTIN)
  add_dependencies(PyAllen pybind11-install)
endif()

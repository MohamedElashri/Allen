# Install script for directory: /home/brij/dcampora_hip_compilation/Allen/cuda

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/usr/local")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "0")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/home/brij/dcampora_hip_compilation/Allen/Release/cuda/utils/cmake_install.cmake")
  include("/home/brij/dcampora_hip_compilation/Allen/Release/cuda/global_event_cut/cmake_install.cmake")
  include("/home/brij/dcampora_hip_compilation/Allen/Release/cuda/velo/cmake_install.cmake")
  include("/home/brij/dcampora_hip_compilation/Allen/Release/cuda/PV/patPV/cmake_install.cmake")
  include("/home/brij/dcampora_hip_compilation/Allen/Release/cuda/PV/beamlinePV/cmake_install.cmake")
  include("/home/brij/dcampora_hip_compilation/Allen/Release/cuda/associate/cmake_install.cmake")
  include("/home/brij/dcampora_hip_compilation/Allen/Release/cuda/UT/cmake_install.cmake")
  include("/home/brij/dcampora_hip_compilation/Allen/Release/cuda/SciFi/cmake_install.cmake")
  include("/home/brij/dcampora_hip_compilation/Allen/Release/cuda/muon/cmake_install.cmake")
  include("/home/brij/dcampora_hip_compilation/Allen/Release/cuda/kalman/cmake_install.cmake")
  include("/home/brij/dcampora_hip_compilation/Allen/Release/cuda/vertex_fit/cmake_install.cmake")
  include("/home/brij/dcampora_hip_compilation/Allen/Release/cuda/selections/cmake_install.cmake")

endif()


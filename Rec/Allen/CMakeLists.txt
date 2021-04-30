###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
#[========================================[.rst:
Rec/Allen
------------------
Utility algorithms to run the Allen
sequence as part of an Gaudi/LHCb
application
#]========================================]

set(ALLEN_INSTALL_DIR ${CMAKE_INSTALL_PREFIX})
_make_relocatable(ALLEN_INSTALL_DIR MAPPINGS "${CMAKE_SOURCE_DIR}" "\${ALLEN_PROJECT_ROOT}")
message(STATUS "Setting Allen install dir env variable to ${ALLEN_INSTALL_DIR}")
gaudi_env(SET ALLEN_INSTALL_DIR ${ALLEN_INSTALL_DIR})

include(GenerateConfiguration)

gaudi_add_module(AllenWrapper
                 src/*.cpp
                 LINK AllenLib DAQEventLib DAQKernelLib GaudiAlgLib
                      PrKernel VPDetLib UTDetLib UTKernelLib CaloDetLib
                      FTDetLib HltDAQLib MCEvent)

gaudi_add_module(AllenAlgorithms
                 ${WRAPPED_ALGORITHM_SOURCES}
                 LINK AllenLib DAQEventLib DAQKernelLib GaudiAlgLib
                      PrKernel VPDetLib UTDetLib UTKernelLib CaloDetLib
                      FTDetLib HltDAQLib MCEvent)

target_include_directories(AllenAlgorithms PRIVATE Allen)

add_custom_target(gaudi_wrappers_of_allen_algorithms DEPENDS ${WRAPPED_ALGORITHM_SOURCES})
add_dependencies(AllenAlgorithms gaudi_wrappers_of_allen_algorithms)

if(CMAKE_BUILD_TYPE STREQUAL Debug)
  target_compile_definitions(AllenWrapper PRIVATE ALLEN_DEBUG)
endif()
target_compile_definitions(AllenWrapper PRIVATE -D${TARGET_DEFINITION})
target_compile_definitions(AllenAlgorithms PRIVATE -D${TARGET_DEFINITION})

gaudi_install(PYTHON)

gaudi_add_tests(QMTest)

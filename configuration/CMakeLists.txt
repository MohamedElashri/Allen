###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
if (NOT STANDALONE)
    add_test(NAME Allen:pytest
      COMMAND ${CMAKE_BINARY_DIR}/run bash ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_configuration.sh ${CMAKE_CURRENT_SOURCE_DIR})
    gaudi_install(PYTHON)

    # Configuration library
    allen_add_host_library(Configuration
      STATIC
        src/TCK.cpp)
    target_include_directories(Configuration
      PUBLIC
      $<BUILD_INTERFACE:${DETECTOR_PREFIX_DIR}/include>  # for DETECTOR_VERSION.h
      $<BUILD_INTERFACE:${LBCOM_PREFIX_DIR}/include>  # for LBCOM_VERSION.h
      $<BUILD_INTERFACE:${REC_PREFIX_DIR}/include>  # for REC_VERSION.h
      $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/include>  # for ALLEN_VERSION.h
      include)

    # Link privately to HltServicesLib here, it will be propagated by
    # linking AllenLib to it as well
    target_link_libraries(Configuration
      PUBLIC
        AllenCommon
        Boost::headers
        LHCb::HltServicesLib)

    # Install the header so it can be used in AllenOnline
    install(FILES include/TCK.h
      DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/Allen)

    pybind11_add_module(TCK NO_EXTRAS src/bindings.cpp)
    target_link_libraries(TCK
      PRIVATE
        Configuration
      PUBLIC
        pybind11::pybind11
        ${Python_LIBRARIES})
    install(TARGETS TCK
      EXPORT
        Allen
      LIBRARY DESTINATION
        ${GAUDI_INSTALL_PYTHONDIR}/Allen)
endif()

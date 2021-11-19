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
    add_test(Allen:pytest
      COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_configuration.sh ${CMAKE_CURRENT_SOURCE_DIR})
    gaudi_install(PYTHON)
endif()

# Configuration interface library
add_library(Configuration INTERFACE)
target_include_directories(Configuration INTERFACE ${CMAKE_BINARY_DIR}/configuration/sequences)

if (NOT STANDALONE)
    gaudi_add_test(pytest
      COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/test_configuration.sh ${CMAKE_CURRENT_SOURCE_DIR})
endif()

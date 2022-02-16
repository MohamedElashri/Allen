###############################################################################
# (c) Copyright 2018-2021 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
set_property(GLOBAL PROPERTY STREAM_DEPENDENT_SOURCES "")

function(filter_sequence_sources target)
  get_target_property(sources ${target} SOURCES)
  set(sources_updated FALSE)
  get_property(stream_dependent_sources GLOBAL PROPERTY STREAM_DEPENDENT_SOURCES)
  foreach(source_file ${sources})
    get_source_file_property(stream_dependent ${source_file} DIRECTORY ${PROJECT_SOURCE_DIR} STREAM_DEPENDENT)
    if (stream_dependent)
      list(REMOVE_ITEM sources ${source_file})
      list(APPEND stream_dependent_sources ${source_file})
      set(sources_updated TRUE)
    endif()
  endforeach()
  if (${sources_updated})
    set_property(TARGET ${target} PROPERTY SOURCES ${sources})
    set_property(GLOBAL PROPERTY STREAM_DEPENDENT_SOURCES ${stream_dependent_sources})
  endif()
endfunction()

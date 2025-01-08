/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "ODINEventTypeWithDecodingLine.cuh"
#include "ODINBank.cuh"
#include "Event/ODIN.h"

// Explicit instantiation
INSTANTIATE_LINE(
  odin_event_type_with_decoding_line::odin_event_type_with_decoding_line_t,
  odin_event_type_with_decoding_line::Parameters)

__device__ bool odin_event_type_with_decoding_line::odin_event_type_with_decoding_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const ODINData> input)
{
  const auto event_type = LHCb::ODIN {std::get<0>(input)}.eventType();
  return event_type & properties.odin_event_type;
}

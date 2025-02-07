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
#pragma once

#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "ODINLine.cuh"

namespace beam_crossing_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    DEVICE_INPUT(dev_odin_data_t, ODINData) dev_odin_data;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
  };

  struct beam_crossing_line_t : public SelectionAlgorithm, Parameters, ODINLine<beam_crossing_line_t, Parameters> {
    struct DeviceProperties {
      unsigned beam_crossing_type;
      DeviceProperties(const beam_crossing_line_t& algo, const Allen::Context&) :
        beam_crossing_type(algo.m_beam_crossing_type)
      {}
    };
    __device__ static bool select(const Parameters&, const DeviceProperties&, std::tuple<const ODINData&> input);

  private:
    Allen::Property<unsigned> m_beam_crossing_type {this, "beam_crossing_type", 0, "ODIN beam crossing type [0-3]"};
  };
} // namespace beam_crossing_line

/*****************************************************************************\
 * (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
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
#include "Line.cuh"
#include "States.cuh"

namespace SMOG2_minimum_bias_line {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_tracks_container_t, Allen::Views::Velo::Consolidated::Tracks) dev_tracks_container;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_tracks_container_t), char) host_fn_parameters;
  };

  // SelectionAlgorithm definition
  struct SMOG2_minimum_bias_line_t : public SelectionAlgorithm,
                                     Parameters,
                                     Line<SMOG2_minimum_bias_line_t, Parameters> {

    struct DeviceProperties {
      unsigned minNHits;
      float minZ;
      float maxZ;
      DeviceProperties(const SMOG2_minimum_bias_line_t& algo, const Allen::Context&) :
        minNHits(algo.m_minNHits), minZ(algo.m_minZ), maxZ(algo.m_maxZ)
      {}
    };

    // Offset function
    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number);

    // Get decision size function
    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments);

    // Get input size function
    __device__ static unsigned input_size(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_tracks_container[event_number].size();
    }

    // Get input function
    __device__ static std::tuple<const unsigned, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    // Selection function
    __device__ static bool
    select(const Parameters& parameters, const DeviceProperties&, std::tuple<const unsigned, const float> input);

  private:
    // Commonly required properties
    // Line-specific properties
    Allen::Property<unsigned> m_minNHits {this, "minNHits", 12, "min number of hits of velo track"};
    Allen::Property<float> m_minZ {this,
                                   "minZ",
                                   -551.f * Gaudi::Units::mm,
                                   "min z coordinate for accepted reconstructed primary vertex"};
    Allen::Property<float> m_maxZ {this,
                                   "maxZ",
                                   -331.f * Gaudi::Units::mm,
                                   "max z coordinate for accepted reconstructed primary vertex"};
  };
} // namespace SMOG2_minimum_bias_line

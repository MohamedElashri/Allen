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
#include "Line.cuh"
#include "VeloConsolidated.cuh"

namespace single_high_et_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // Velo tracks
    DEVICE_INPUT(dev_velo_tracks_offsets_t, unsigned) dev_velo_tracks_offsets;
    // ECAL
    DEVICE_INPUT(dev_brem_ET_t, float) dev_brem_ET;
    // Outputs
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;

    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    // Properties
  };

  // SelectionAlgorithm definition
  struct single_high_et_line_t : public SelectionAlgorithm, Parameters, Line<single_high_et_line_t, Parameters> {

    struct DeviceProperties {
      float minET;
      DeviceProperties(const single_high_et_line_t& algo, const Allen::Context&) : minET(algo.m_minET) {}
    };

    // Offset function
    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number);

    // Get decision size function
    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments);

    // Get input function
    __device__ static std::tuple<const float> get_input(const Parameters&, const unsigned, const unsigned i);

    // Selection function
    __device__ static bool select(const Parameters&, const DeviceProperties&, std::tuple<const float> input);

  private:
    // Commonly required properties
    // Line-specific properties
    Allen::Property<float> m_minET {this, "minET", 15000.f, "min Et of brem cluster"};
  };
} // namespace single_high_et_line

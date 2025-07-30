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
#include "Line.cuh"
#include "VeloConsolidated.cuh"
#include "ODINBank.cuh"

namespace beam_gas_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_INPUT(dev_offsets_velo_tracks_t, unsigned) dev_offsets_velo_tracks;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number;
    DEVICE_INPUT(dev_odin_data_t, ODINData) dev_odin_data;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
  };

  struct beam_gas_line_t : public SelectionAlgorithm, Parameters, Line<beam_gas_line_t, Parameters> {
    struct DeviceProperties {
      unsigned min_velo_tracks;
      unsigned beam_crossing_type;
      unsigned minNHits;
      float minZ;
      float maxZ;
      DeviceProperties(const beam_gas_line_t& algo, const Allen::Context&) :
        min_velo_tracks(algo.m_min_velo_tracks), beam_crossing_type(algo.m_beam_crossing_type),
        minNHits(algo.m_minNHits), minZ(algo.m_minZ), maxZ(algo.m_maxZ)
      {}
    };
    __device__ static std::tuple<const unsigned, const unsigned, const unsigned, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const unsigned, const unsigned, const unsigned, const float> input);

    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments)
    {
      return first<typename Parameters::host_number_of_reconstructed_velo_tracks_t>(arguments);
    }

    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_offsets_velo_tracks[event_number];
    }

  private:
    Allen::Property<unsigned> m_min_velo_tracks {this, "min_velo_tracks", 1, "Minimum number of VELO tracks"};
    Allen::Property<unsigned> m_beam_crossing_type {this, "beam_crossing_type", 1, "ODIN beam crossing type [0-3]"};
    Allen::Property<unsigned> m_minNHits {this, "minNHits", 12, "min number of hits of velo track"};
    Allen::Property<float> m_minZ {this,
                                   "minZ",
                                   -550.f * Allen::Units::mm,
                                   "min z coordinate for accepted velo track POCA"};
    Allen::Property<float> m_maxZ {this,
                                   "maxZ",
                                   -300.f * Allen::Units::mm,
                                   "max z coordinate for accepted velo track POCA"};
  };
} // namespace beam_gas_line

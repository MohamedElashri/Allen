/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
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
#include "MuonDefinitions.cuh"

namespace one_muon_track_line {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_muon_total_number_of_tracks_t, unsigned) host_muon_total_number_of_tracks;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_muon_tracks_t, MuonTrack) dev_muon_tracks;
    DEVICE_INPUT(dev_muon_tracks_offsets_t, unsigned) dev_muon_tracks_offsets;
  };

  struct one_muon_track_line_t : public SelectionAlgorithm, Parameters, Line<one_muon_track_line_t, Parameters> {

    struct DeviceProperties {
      float max_chi2x;
      float max_chi2y;
      DeviceProperties(const one_muon_track_line_t& algo, const Allen::Context&) :
        max_chi2x(algo.m_max_chi2x), max_chi2y(algo.m_max_chi2y)
      {}
    };

    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_muon_tracks_offsets[event_number];
    }

    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments)
    {
      return first<typename Parameters::host_muon_total_number_of_tracks_t>(arguments);
    }

    __device__ static std::tuple<const MuonTrack>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
    {
      const auto muon_tracks_offsets = parameters.dev_muon_tracks_offsets;
      const auto muon_tracks = parameters.dev_muon_tracks;

      const unsigned track_index = i + muon_tracks_offsets[event_number];

      return std::forward_as_tuple(muon_tracks[track_index]);
    }

    __device__ static bool select(const Parameters&, const DeviceProperties&, std::tuple<const MuonTrack> input);

  private:
    Allen::Property<float> m_max_chi2x {this, "max_chi2x", 1.f, "Maximum chi2 for the xz plane"};
    Allen::Property<float> m_max_chi2y {this, "max_chi2y", 0.3f, "Maximum chi2 for the yz plane"};
  };
} // namespace one_muon_track_line

/*****************************************************************************\
 * (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
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

namespace t_track_cosmic_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_seeding_tracks_t, SciFi::Seeding::Track) dev_seeding_tracks;
    DEVICE_INPUT(dev_seeding_offsets_t, unsigned) dev_seeding_offsets;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
  };

  struct t_track_cosmic_line_t : public SelectionAlgorithm, Parameters, Line<t_track_cosmic_line_t, Parameters> {
    struct DeviceProperties {
      float max_chi2X;
      float max_chi2Y;
      DeviceProperties(const t_track_cosmic_line_t& algo, const Allen::Context&) :
        max_chi2X(algo.m_max_chi2X), max_chi2Y(algo.m_max_chi2Y)
      {}
    };
    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const SciFi::Seeding::Track> input);

    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_seeding_offsets[event_number];
    }

    __device__ static std::tuple<const SciFi::Seeding::Track>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
    {
      const SciFi::Seeding::Track event_scifi_track =
        parameters.dev_seeding_tracks[event_number * SciFi::Constants::Nmax_seeds + i];
      return std::forward_as_tuple(event_scifi_track);
    }

    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments)
    {
      return first<host_number_of_reconstructed_scifi_tracks_t>(arguments);
    }

  private:
    Allen::Property<float> m_max_chi2X {this,
                                        "max_chi2X",
                                        0.26f,
                                        "Max value of chi2X"}; // 95 percentile of chi2X distribution
    Allen::Property<float> m_max_chi2Y {this,
                                        "max_chi2Y",
                                        134.0f,
                                        "Max value of chi2Y"}; // 95 percentile of chi2Y distribution
  };
} // namespace t_track_cosmic_line

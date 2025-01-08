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

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "AlgorithmTypes.cuh"

namespace lf_quality_filter_length {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_input_tracks_t, unsigned) host_number_of_reconstructed_input_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_tracks_view_t, Allen::IMultiEventContainer*) dev_tracks_view;
    DEVICE_INPUT(dev_scifi_lf_tracks_t, SciFi::TrackHits) dev_scifi_lf_tracks;
    DEVICE_INPUT(dev_scifi_lf_atomics_t, unsigned) dev_scifi_lf_atomics;
    DEVICE_INPUT(dev_scifi_lf_parametrization_t, float) dev_scifi_lf_parametrization;
    DEVICE_OUTPUT(dev_scifi_lf_length_filtered_tracks_t, SciFi::TrackHits) dev_scifi_lf_length_filtered_tracks;
    DEVICE_OUTPUT(dev_scifi_lf_length_filtered_atomics_t, unsigned) dev_scifi_lf_length_filtered_atomics;
    DEVICE_OUTPUT(dev_scifi_lf_parametrization_length_filter_t, float) dev_scifi_lf_parametrization_length_filter;
  };

  __global__ void lf_quality_filter_length(
    Parameters,
    const unsigned maximum_number_of_candidates_per_ut_track,
    const unsigned min_tot_scifi_hits,
    const unsigned min_UV_scifi_hits,
    const unsigned min_X_scifi_hits);

  struct lf_quality_filter_length_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
    Allen::Property<unsigned> m_maximum_number_of_candidates_per_ut_track {this,
                                                                           "maximum_number_of_candidates_per_ut_track",
                                                                           12,
                                                                           "maximum_number_of_candidates_per_ut_track"};
    Allen::Property<unsigned> m_min_tot_scifi_hits {this, "min_tot_scifi_hits", 9, "min_tot_scifi_hits"};
    Allen::Property<unsigned> m_min_UV_scifi_hits {this, "min_UV_scifi_hits", 3, "min_UV_scifi_hits"};
    Allen::Property<unsigned> m_min_X_scifi_hits {this, "min_X_scifi_hits", 3, "min_X_scifi_hits"};
  };
} // namespace lf_quality_filter_length

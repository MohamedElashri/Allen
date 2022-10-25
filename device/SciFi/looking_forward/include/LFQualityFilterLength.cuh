/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
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
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(
      maximum_number_of_candidates_per_ut_track_t,
      "maximum_number_of_candidates_per_ut_track",
      "maximum_number_of_candidates_per_ut_track",
      unsigned)
    maximum_number_of_candidates_per_ut_track;
  };

  __global__ void lf_quality_filter_length(Parameters);

  struct lf_quality_filter_length_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
    Property<maximum_number_of_candidates_per_ut_track_t> m_maximum_number_of_candidates_per_ut_track {this, 12};
  };
} // namespace lf_quality_filter_length

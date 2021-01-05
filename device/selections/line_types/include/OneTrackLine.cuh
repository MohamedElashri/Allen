/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "Line.cuh"
#include "ParKalmanFilter.cuh"

/**
 * A OneTrackLine.
 *
 * It assumes an inheriting class will have the following inputs:
 *  HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
 *  HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
 *  DEVICE_INPUT(dev_tracks_t, ParKalmanFilter::FittedTrack) dev_tracks;
 *  DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
 *
 * It also assumes the OneTrackLine will be defined as:
 *  __device__ bool select(const Parameters& parameters, std::tuple<const ParKalmanFilter::FittedTrack&> input) const;
 */
template<typename Derived, typename Parameters>
struct OneTrackLine : public Line<Derived, Parameters> {
  static unsigned get_block_dim_x(const ArgumentReferences<Parameters>&) { return 64; }

  static unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments)
  {
    return first<typename Parameters::host_number_of_reconstructed_scifi_tracks_t>(arguments);
  }

  __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
  {
    return parameters.dev_track_offsets[event_number];
  }

  __device__ static std::tuple<const ParKalmanFilter::FittedTrack&>
  get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
  {
    const ParKalmanFilter::FittedTrack* event_tracks =
      parameters.dev_tracks + parameters.dev_track_offsets[event_number];
    const auto& track = event_tracks[i];
    return std::forward_as_tuple(track);
  }
};

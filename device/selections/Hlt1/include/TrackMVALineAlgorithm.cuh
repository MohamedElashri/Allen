#pragma once

#include "DeviceAlgorithm.cuh"
#include "HostPrefixSum.h"
#include "ConfiguredLines.h"

template<typename T, typename P>
__global__ void onetrackline(
  const ParKalmanFilter::FittedTrack* dev_kf_tracks,
  const unsigned* dev_track_offsets,
  const T& line,
  const P& parameters,
  bool* decisions)
{
  const unsigned event_number = blockIdx.x;

  // Fetch tracks
  const ParKalmanFilter::FittedTrack* event_tracks = dev_kf_tracks + dev_track_offsets[event_number];
  const auto number_of_tracks_in_event = dev_track_offsets[event_number + 1] - dev_track_offsets[event_number];

  // Do the selection and store the decision
  for (unsigned i = threadIdx.x; i < number_of_tracks_in_event; i += blockDim.x) {
    decisions[i] = line.doline(parameters, event_tracks[i]);
  }
}

template<typename Derived, typename Params>
struct OneTrackLine : public DeviceAlgorithm, Params {
  constexpr static unsigned block_dim_x = 256;

  void set_arguments_size(
    ArgumentReferences<Params> arguments,
    const RuntimeOptions&,
    const Constants&,
    const HostBuffers&) const
  {
    set_size<typename Params::decisions_t>(arguments, first<typename Params::host_number_of_reconstructed_scifi_tracks_t>(arguments));
  }

  void operator()(
    const ArgumentReferences<Params>& arguments,
    const RuntimeOptions&,
    const Constants&,
    HostBuffers&,
    cudaStream_t& stream,
    cudaEvent_t&) const
  {
    initialize<typename Params::decisions_t>(arguments, 0, stream);

    global_function(onetrackline<Derived, Params>)(
      first<typename Params::host_number_of_selected_events_t>(arguments), block_dim_x, stream)(
      data<typename Params::dev_kf_tracks_t>(arguments),
      data<typename Params::dev_track_offsets_t>(arguments),
      *static_cast<const Derived*>(this),
      arguments,
      data<typename Params::decisions_t>(arguments));
  }
};

namespace track_mva_line_algorithm {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned), host_number_of_reconstructed_scifi_tracks),
    (DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack), dev_kf_tracks),
    (DEVICE_INPUT(dev_track_offsets_t, unsigned), dev_track_offsets),
    (DEVICE_OUTPUT(decisions_t, bool), decisions), // is that right?
    (PROPERTY(maxChi2Ndof_t, "maxChi2Ndof", "maxChi2Ndof description", float), maxChi2Ndof),
    (PROPERTY(minPt_t, "minPt", "minPt description", float), minPt),
    (PROPERTY(maxPt_t, "maxPt", "maxPt description", float), maxPt),
    (PROPERTY(minIPChi2_t, "minIPChi2", "minIPChi2 description", float), minIPChi2),
    (PROPERTY(param1_t, "param1", "param1 description", float), param1),
    (PROPERTY(param2_t, "param2", "param2 description", float), param2),
    (PROPERTY(param3_t, "param3", "param3 description", float), param3),
    (PROPERTY(alpha_t, "alpha", "alpha description", float), alpha))

  struct track_mva_line_algorithm_t : public OneTrackLine<track_mva_line_algorithm_t, Parameters> {
    __device__ bool doline(const Parameters& ps, const ParKalmanFilter::FittedTrack& track) const;

  private:
    Property<maxChi2Ndof_t> m_maxChi2Ndof {this, 2.5f};
    Property<minPt_t> m_minPt {this, 2000.0f};
    Property<maxPt_t> m_maxPt {this, 26000.0f};
    Property<minIPChi2_t> m_minIPChi2 {this, 7.4f};
    Property<param1_t> m_param1 {this, 1.0f};
    Property<param2_t> m_param2 {this, 2.0f};
    Property<param3_t> m_param3 {this, 1.248f};
    Property<alpha_t> m_alpha {this, 0.f};
  };
} // namespace track_mva_line_algorithm
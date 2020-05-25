#pragma once

#include "DeviceAlgorithm.cuh"
#include "HostPrefixSum.h"
#include "ConfiguredLines.h"

namespace track_mva_line_algorithm {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned), host_number_of_reconstructed_scifi_tracks),
    (HOST_INPUT(host_number_of_svs_t, unsigned), host_number_of_svs),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack), dev_kf_tracks),
    (DEVICE_INPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex), dev_consolidated_svs),
    (DEVICE_INPUT(dev_offsets_forward_tracks_t, unsigned), dev_offsets_forward_tracks),
    (DEVICE_INPUT(dev_sv_offsets_t, unsigned), dev_sv_offsets),
    (DEVICE_INPUT(dev_odin_raw_input_t, char), dev_odin_raw_input),
    (DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned), dev_odin_raw_input_offsets),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_velo_offsets),
    (DEVICE_OUTPUT(dev_sel_results_t, bool), dev_sel_results),
    (PROPERTY(factor_one_track_t, "factor_one_track", "postscale for one-track line", float), factor_one_track),
    (PROPERTY(factor_single_muon_t, "factor_single_muon", "postscale for single-muon line", float), factor_single_muon),
    (PROPERTY(factor_two_tracks_t, "factor_two_tracks", "postscale for two-track line", float), factor_two_tracks),
    (PROPERTY(factor_disp_dimuon_t, "factor_disp_dimuon", "postscale for displaced-dimuon line", float), factor_disp_dimuon),
    (PROPERTY(factor_high_mass_dimuon_t, "factor_high_mass_dimuon", "postscale for high-mass-dimuon line", float), factor_high_mass_dimuon),
    (PROPERTY(factor_dimuon_soft_t, "factor_dimuon_soft", "postscale for soft-dimuon line", float), factor_dimuon_soft),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  template<typename T>
  __global__ bool onetrackline(Parameters parameters, const T& doitmore)
  {
    const unsigned event_number = blockIdx.x;

    // Fetch tracks
    const ParKalmanFilter::FittedTrack* event_tracks =
      parameters.dev_kf_tracks + parameters.dev_offsets_forward_tracks[event_number];
    const auto number_of_tracks_in_event =
      parameters.dev_offsets_forward_tracks[event_number + 1] - parameters.dev_offsets_forward_tracks[event_number];

    for (unsigned i = threadIdx.x; i < number_of_tracks_in_event; i += blockDim.x) {
      decisions[i] = doitmore(event_tracks[i]);
    }
  }

  struct track_mva_line_algorithm_t : public DeviceAlgorithm, Parameters, OneTrackLine<pair<dev_sel_results_t, host_number_of_reconstructed_scifi_tracks_t>> {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const {
      set_size<dev_sel_results_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
    }

    // void operator()(
    //   const ArgumentReferences<Parameters>& arguments,
    //   const RuntimeOptions& runtime_options,
    //   const Constants&,
    //   HostBuffers& host_buffers,
    //   cudaStream_t& cuda_stream,
    //   cudaEvent_t&) const;

    __device__ bool doitmore(const Parameters& parameters, const ParKalmanFilter::FittedTrack& track)
    {
      float ptShift = (track.pt() - alpha) / Gaudi::Units::GeV;
      const bool decision = track.chi2 / track.ndof < maxChi2Ndof &&
                            ((ptShift > maxPt && track.ipChi2 > minIPChi2) ||
                             (ptShift > minPt && ptShift < maxPt &&
                              logf(track.ipChi2) > param1 / (ptShift - param2) / (ptShift - param2) +
                                                     param3 / maxPt * (maxPt - ptShift) + logf(minIPChi2)));
      return decision;
    }

  private:
    Property<factor_one_track_t> m_factor_one_track {this, 1.f};
    Property<factor_single_muon_t> m_factor_single_muon {this, 1.f};
    Property<factor_two_tracks_t> m_factor_two_tracks {this, 1.f};
    Property<factor_disp_dimuon_t> m_factor_disp_dimuon {this, 1.f};
    Property<factor_high_mass_dimuon_t> m_factor_high_mass_dimuon {this, 1.f};
    Property<factor_dimuon_soft_t> m_factor_dimuon_soft {this, 1.f};
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace track_mva_line_algorithm
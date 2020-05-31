/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "DeviceAlgorithm.cuh"
#include "HostPrefixSum.h"
#include "ConfiguredLines.h"

namespace run_hlt1 {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
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
    (DEVICE_OUTPUT(dev_sel_results_offsets_t, unsigned), dev_sel_results_offsets),
    (PROPERTY(factor_one_track_t, "factor_one_track", "postscale for one-track line", float), factor_one_track),
    (PROPERTY(factor_single_muon_t, "factor_single_muon", "postscale for single-muon line", float), factor_single_muon),
    (PROPERTY(factor_two_tracks_t, "factor_two_tracks", "postscale for two-track line", float), factor_two_tracks),
    (PROPERTY(factor_disp_dimuon_t, "factor_disp_dimuon", "postscale for displaced-dimuon line", float), factor_disp_dimuon),
    (PROPERTY(factor_high_mass_dimuon_t, "factor_high_mass_dimuon", "postscale for high-mass-dimuon line", float), factor_high_mass_dimuon),
    (PROPERTY(factor_dimuon_soft_t, "factor_dimuon_soft", "postscale for soft-dimuon line", float), factor_dimuon_soft),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void run_hlt1(Parameters parameters, const unsigned selected_number_of_events, const unsigned event_start);

  __global__ void run_postscale(Parameters, const unsigned selected_number_of_events, const unsigned event_start);

  struct run_hlt1_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& stream,
      cudaEvent_t&) const;

  private:
    Property<factor_one_track_t> m_factor_one_track {this, 1.f};
    Property<factor_single_muon_t> m_factor_single_muon {this, 1.f};
    Property<factor_two_tracks_t> m_factor_two_tracks {this, 1.f};
    Property<factor_disp_dimuon_t> m_factor_disp_dimuon {this, 1.f};
    Property<factor_high_mass_dimuon_t> m_factor_high_mass_dimuon {this, 1.f};
    Property<factor_dimuon_soft_t> m_factor_dimuon_soft {this, 1.f};
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace run_hlt1
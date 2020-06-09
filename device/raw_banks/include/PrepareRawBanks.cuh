#pragma once

#include "HltDecReport.cuh"
#include "HltSelReport.cuh"
#include "RawBanksDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "LineInfo.cuh"
#include "ParKalmanFilter.cuh"
#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "ConfiguredLines.h"

namespace prepare_raw_banks {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint), host_number_of_reconstructed_scifi_tracks),
    (HOST_INPUT(host_number_of_svs_t, uint), host_number_of_svs),
    (DEVICE_INPUT(dev_event_list_t, uint), dev_event_list),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint), dev_atomics_velo),
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint), dev_velo_track_hit_number),
    (DEVICE_INPUT(dev_velo_track_hits_t, char), dev_velo_track_hits),
    (DEVICE_INPUT(dev_offsets_ut_tracks_t, uint), dev_atomics_ut),
    (DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint), dev_ut_track_hit_number),
    (DEVICE_INPUT(dev_ut_qop_t, float), dev_ut_qop),
    (DEVICE_INPUT(dev_ut_track_velo_indices_t, uint), dev_ut_track_velo_indices),
    (DEVICE_INPUT(dev_offsets_scifi_track_hit_number_t, uint), dev_scifi_track_hit_number),
    (DEVICE_INPUT(dev_scifi_qop_t, float), dev_scifi_qop),
    (DEVICE_INPUT(dev_scifi_states_t, MiniState), dev_scifi_states),
    (DEVICE_INPUT(dev_scifi_track_ut_indices_t, uint), dev_scifi_track_ut_indices),
    (DEVICE_INPUT(dev_ut_track_hits_t, char), dev_ut_track_hits),
    (DEVICE_INPUT(dev_scifi_track_hits_t, char), dev_scifi_track_hits),
    (DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack), dev_kf_tracks),
    (DEVICE_INPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex), dev_consolidated_svs),
    (DEVICE_INPUT(dev_offsets_forward_tracks_t, uint), dev_offsets_forward_tracks),
    (DEVICE_INPUT(dev_sv_offsets_t, uint), dev_sv_offsets),
    (DEVICE_INPUT(dev_sel_results_t, bool), dev_sel_results),
    (DEVICE_INPUT(dev_sel_results_offsets_t, uint), dev_sel_results_offsets),
    (DEVICE_OUTPUT(dev_candidate_lists_t, uint), dev_candidate_lists),
    (DEVICE_OUTPUT(dev_candidate_counts_t, uint), dev_candidate_counts),
    (DEVICE_OUTPUT(dev_sel_atomics_t, uint), dev_sel_atomics),
    (DEVICE_OUTPUT(dev_saved_tracks_list_t, uint), dev_saved_tracks_list),
    (DEVICE_OUTPUT(dev_saved_svs_list_t, uint), dev_saved_svs_list),
    (DEVICE_OUTPUT(dev_save_track_t, int), dev_save_track),
    (DEVICE_OUTPUT(dev_save_sv_t, int), dev_save_sv),
    (DEVICE_OUTPUT(dev_dec_reports_t, uint), dev_dec_reports),
    (DEVICE_OUTPUT(dev_sel_rb_hits_t, uint), dev_sel_rb_hits),
    (DEVICE_OUTPUT(dev_sel_rb_stdinfo_t, uint), dev_sel_rb_stdinfo),
    (DEVICE_OUTPUT(dev_sel_rb_objtyp_t, uint), dev_sel_rb_objtyp),
    (DEVICE_OUTPUT(dev_sel_rb_substr_t, uint), dev_sel_rb_substr),
    (DEVICE_OUTPUT(dev_sel_rep_sizes_t, uint), dev_sel_rep_sizes),
    (DEVICE_OUTPUT(dev_passing_event_list_t, bool), dev_passing_event_list),
    (PROPERTY(block_dim_x_t, "block_dim_x", "block dimensions X", uint), block_dim_x))

  __global__ void prepare_decisions(Parameters, const uint selected_number_of_events, const uint event_start);
  
  __global__ void
  prepare_raw_banks(Parameters, const uint number_of_events, const uint total_number_of_events, const uint event_start);

  struct prepare_raw_banks_t : public DeviceAlgorithm, Parameters {
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
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 32};
  };
} // namespace prepare_raw_banks
#pragma once

#include "HltDecReport.cuh"
#include "HltSelReport.cuh"
#include "RawBanksDefinitions.cuh"
#include "LineInfo.cuh"
#include "LineTraverser.cuh"
#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "ParKalmanDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace prepare_decisions {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    HOST_INPUT(host_number_of_svs_t, uint);
    HOST_INPUT(host_number_of_mf_svs_t, uint);
    HOST_INPUT(host_number_of_mf_tracks_t, uint);
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
    DEVICE_INPUT(dev_offsets_ut_tracks_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_INPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_INPUT(dev_ut_track_velo_indices_t, uint) dev_ut_track_velo_indices;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_offsets_forward_tracks;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number, uint) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, uint) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_ut_track_hits_t, char) dev_ut_track_hits;
    DEVICE_INPUT(dev_scifi_track_hits_t, char) dev_scifi_track_hits;
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_mf_tracks_t, ParKalmanFilter::FittedTrack) dev_mf_tracks;
    DEVICE_INPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex) dev_consolidated_svs;
    DEVICE_INPUT(dev_mf_svs_t, VertexFit::TrackMVAVertex) dev_mf_svs;
    DEVICE_INPUT(dev_sv_offsets_t, uint) dev_sv_offsets; // dev_sv_atomics
    DEVICE_INPUT(dev_mf_sv_offsets_t, uint) dev_mf_sv_offsets;
    DEVICE_INPUT(dev_mf_track_offsets_t, uint) dev_mf_track_offsets;
    DEVICE_INPUT(dev_sel_results_t, bool) dev_sel_results;
    DEVICE_INPUT(dev_sel_results_offsets_t, uint) dev_sel_results_offsets;
    DEVICE_OUTPUT(dev_candidate_lists_t, uint) dev_candidate_lists;
    DEVICE_OUTPUT(dev_candidate_counts_t, uint) dev_candidate_counts;
    DEVICE_OUTPUT(dev_n_passing_decisions_t, uint) dev_n_passing_decisions;
    DEVICE_OUTPUT(dev_n_svs_saved_t, uint) dev_n_svs_saved;
    DEVICE_OUTPUT(dev_n_mf_svs_saved_t, uint) dev_n_mf_svs_saved;
    DEVICE_OUTPUT(dev_n_tracks_saved_t, uint) dev_n_tracks_saved;
    DEVICE_OUTPUT(dev_n_mf_tracks_saved_t, uint) dev_n_mf_tracks_saved;
    DEVICE_OUTPUT(dev_n_hits_saved_t, uint) dev_n_hits_saved;
    DEVICE_OUTPUT(dev_saved_tracks_list_t, uint) dev_saved_tracks_list;
    DEVICE_OUTPUT(dev_saved_mf_tracks_list_t, uint) dev_saved_mf_tracks_list;
    DEVICE_OUTPUT(dev_saved_svs_list_t, uint) dev_saved_svs_list;
    DEVICE_OUTPUT(dev_saved_mf_svs_list_t, uint) dev_saved_mf_svs_list;
    DEVICE_OUTPUT(dev_dec_reports_t, uint) dev_dec_reports;
    DEVICE_OUTPUT(dev_save_track_t, int) dev_save_track;
    DEVICE_OUTPUT(dev_save_mf_track_t, int) dev_save_mf_track;
    DEVICE_OUTPUT(dev_save_sv_t, int) dev_save_sv;
    DEVICE_OUTPUT(dev_save_mf_sv_t, int) dev_save_mf_sv;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  template<typename T>
  __global__ void prepare_decisions(Parameters);

  template<typename T, typename U, char... S>
  struct prepare_decisions_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(prepare_decisions<U>)) function {prepare_decisions<U>};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      const auto n_hlt1_lines = std::tuple_size<U>::value;
      set_size<dev_dec_reports_t>(arguments, (2 + n_hlt1_lines) * value<host_number_of_selected_events_t>(arguments));

      // This is not technically enough to save every single track, but
      // should be more than enough in practice.
      // TODO: Implement some check for this.
      set_size<dev_candidate_lists_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Hlt1::maxCandidates * n_hlt1_lines);
      set_size<dev_candidate_counts_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * n_hlt1_lines);
      set_size<dev_saved_tracks_list_t>(arguments, value<host_number_of_reconstructed_scifi_tracks_t>(arguments));
      set_size<dev_saved_mf_tracks_list_t>(arguments, value<host_number_of_mf_tracks_t>(arguments));
      set_size<dev_saved_svs_list_t>(arguments, value<host_number_of_svs_t>(arguments));
      set_size<dev_saved_mf_svs_list_t>(arguments, value<host_number_of_mf_svs_t>(arguments));
      set_size<dev_save_track_t>(arguments, value<host_number_of_reconstructed_scifi_tracks_t>(arguments));
      set_size<dev_save_mf_track_t>(arguments, value<host_number_of_mf_tracks_t>(arguments));
      set_size<dev_save_sv_t>(arguments, value<host_number_of_svs_t>(arguments));
      set_size<dev_save_mf_sv_t>(arguments, value<host_number_of_mf_svs_t>(arguments));
      set_size<dev_n_tracks_saved_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_n_mf_tracks_saved_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_n_svs_saved_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_n_mf_svs_saved_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_n_hits_saved_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_n_passing_decisions_t>(arguments, value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      initialize<dev_candidate_lists_t>(arguments, 0, cuda_stream);
      initialize<dev_candidate_counts_t>(arguments, 0, cuda_stream);
      initialize<dev_dec_reports_t>(arguments, 0, cuda_stream);
      initialize<dev_save_track_t>(arguments, -1, cuda_stream);
      initialize<dev_save_mf_track_t>(arguments, -1, cuda_stream);
      initialize<dev_save_sv_t>(arguments, -1, cuda_stream);
      initialize<dev_save_mf_sv_t>(arguments, -1, cuda_stream);
      initialize<dev_n_tracks_saved_t>(arguments, 0, cuda_stream);
      initialize<dev_n_mf_tracks_saved_t>(arguments, 0, cuda_stream);
      initialize<dev_n_svs_saved_t>(arguments, 0, cuda_stream);
      initialize<dev_n_mf_svs_saved_t>(arguments, 0, cuda_stream);
      initialize<dev_n_hits_saved_t>(arguments, 0, cuda_stream);

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_offsets_all_velo_tracks_t>(arguments),
                    begin<dev_offsets_velo_track_hit_number_t>(arguments),
                    begin<dev_velo_track_hits_t>(arguments),
                    begin<dev_offsets_ut_tracks_t>(arguments),
                    begin<dev_offsets_ut_track_hit_number_t>(arguments),
                    begin<dev_ut_qop_t>(arguments),
                    begin<dev_ut_track_velo_indices_t>(arguments),
                    begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_offsets_scifi_track_hit_number>(arguments),
                    begin<dev_scifi_qop_t>(arguments),
                    begin<dev_scifi_states_t>(arguments),
                    begin<dev_scifi_track_ut_indices_t>(arguments),
                    begin<dev_ut_track_hits_t>(arguments),
                    begin<dev_scifi_track_hits_t>(arguments),
                    begin<dev_kf_tracks_t>(arguments),
                    begin<dev_mf_tracks_t>(arguments),
                    begin<dev_consolidated_svs_t>(arguments),
                    begin<dev_mf_svs_t>(arguments),
                    begin<dev_sv_offsets_t>(arguments),
                    begin<dev_mf_sv_offsets_t>(arguments),
                    begin<dev_mf_track_offsets_t>(arguments),
                    begin<dev_sel_results_t>(arguments),
                    begin<dev_sel_results_offsets_t>(arguments),
                    begin<dev_candidate_lists_t>(arguments),
                    begin<dev_candidate_counts_t>(arguments),
                    begin<dev_n_passing_decisions_t>(arguments),
                    begin<dev_n_svs_saved_t>(arguments),
                    begin<dev_n_mf_svs_saved_t>(arguments),
                    begin<dev_n_tracks_saved_t>(arguments),
                    begin<dev_n_mf_tracks_saved_t>(arguments),
                    begin<dev_n_hits_saved_t>(arguments),
                    begin<dev_saved_tracks_list_t>(arguments),
                    begin<dev_saved_mf_tracks_list_t>(arguments),
                    begin<dev_saved_svs_list_t>(arguments),
                    begin<dev_saved_mf_svs_list_t>(arguments),
                    begin<dev_dec_reports_t>(arguments),
                    begin<dev_save_track_t>(arguments),
                    begin<dev_save_mf_track_t>(arguments),
                    begin<dev_save_sv_t>(arguments),
                    begin<dev_save_mf_sv_t>(arguments)});
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace prepare_decisions

#include "PrepareDecisions.icc"
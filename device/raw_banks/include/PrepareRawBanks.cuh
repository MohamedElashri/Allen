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
#include "LineTraverser.cuh"
#include "ConfiguredLines.h"

namespace prepare_raw_banks {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    HOST_INPUT(host_number_of_svs_t, uint);
    DEVICE_INPUT(dev_event_list_t, uint) dev_event_list;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
    DEVICE_INPUT(dev_offsets_ut_tracks_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_INPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_INPUT(dev_ut_track_velo_indices_t, uint) dev_ut_track_velo_indices;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number_t, uint) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, uint) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_ut_track_hits_t, char) dev_ut_track_hits;
    DEVICE_INPUT(dev_scifi_track_hits_t, char) dev_scifi_track_hits;
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex) dev_consolidated_svs;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_offsets_forward_tracks;
    DEVICE_INPUT(dev_sv_offsets_t, uint) dev_sv_offsets;
    DEVICE_INPUT(dev_sel_results_t, bool) dev_sel_results;
    DEVICE_INPUT(dev_sel_results_offsets_t, uint) dev_sel_results_offsets;
    DEVICE_OUTPUT(dev_candidate_lists_t, uint) dev_candidate_lists;
    DEVICE_OUTPUT(dev_candidate_counts_t, uint) dev_candidate_counts;
    DEVICE_OUTPUT(dev_n_passing_decisions_t, uint) dev_n_passing_decisions;
    DEVICE_OUTPUT(dev_n_svs_saved_t, uint) dev_n_svs_saved;
    DEVICE_OUTPUT(dev_n_tracks_saved_t, uint) dev_n_tracks_saved;
    DEVICE_OUTPUT(dev_n_hits_saved_t, uint) dev_n_hits_saved;
    DEVICE_OUTPUT(dev_saved_tracks_list_t, uint) dev_saved_tracks_list;
    DEVICE_OUTPUT(dev_saved_svs_list_t, uint) dev_saved_svs_list;
    DEVICE_OUTPUT(dev_save_track_t, int) dev_save_track;
    DEVICE_OUTPUT(dev_save_sv_t, int) dev_save_sv;
    DEVICE_OUTPUT(dev_dec_reports_t, uint) dev_dec_reports;
    DEVICE_OUTPUT(dev_sel_rb_hits_t, uint) dev_sel_rb_hits;
    DEVICE_OUTPUT(dev_sel_rb_stdinfo_t, uint) dev_sel_rb_stdinfo;
    DEVICE_OUTPUT(dev_sel_rb_objtyp_t, uint) dev_sel_rb_objtyp;
    DEVICE_OUTPUT(dev_sel_rb_substr_t, uint) dev_sel_rb_substr;
    DEVICE_OUTPUT(dev_sel_rep_sizes_t, uint) dev_sel_rep_sizes;
    DEVICE_OUTPUT(dev_passing_event_list_t, bool) dev_passing_event_list;
    PROPERTY(block_dim_x_t, uint, "block_dim_x", "block dimensions X");
  };

  __global__ void prepare_decisions(Parameters, const uint selected_number_of_events, const uint event_start);
  
  __global__ void
  prepare_raw_banks(Parameters, const uint number_of_events, const uint total_number_of_events, const uint event_start);

  template<typename T>
  struct prepare_raw_banks_t : public DeviceAlgorithm, Parameters {
    decltype(global_function(prepare_raw_banks)) raw_banks_function {prepare_raw_banks};
    decltype(global_function(prepare_decisions)) decisions_function {prepare_decisions};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
    {
      const auto total_number_of_events =
        std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

      const auto padding_size = 3 * first<host_number_of_selected_events_t>(arguments);
      const auto hits_size = ParKalmanFilter::nMaxMeasurements * first<host_number_of_reconstructed_scifi_tracks_t>(arguments);
      set_size<dev_sel_rb_hits_t>(arguments, hits_size + padding_size);
      set_size<dev_sel_rb_stdinfo_t>(arguments, total_number_of_events * Hlt1::maxStdInfoEvent);
      set_size<dev_sel_rb_objtyp_t>(arguments, total_number_of_events * (Hlt1::nObjTyp + 1));
      set_size<dev_sel_rb_substr_t>(arguments, total_number_of_events * Hlt1::subStrDefaultAllocationSize);
      set_size<dev_sel_rep_sizes_t>(arguments, total_number_of_events);
      set_size<dev_passing_event_list_t>(arguments, total_number_of_events);

      const auto n_hlt1_lines = std::tuple_size<configured_lines_t>::value;
      set_size<dev_dec_reports_t>(arguments, (2 + n_hlt1_lines) * total_number_of_events);

      // This is not technically enough to save every single track, but
      // should be more than enough in practice.
      // TODO: Implement some check for this.
      set_size<dev_candidate_lists_t>(arguments, total_number_of_events * Hlt1::maxCandidates * n_hlt1_lines);
      set_size<dev_candidate_counts_t>(arguments, total_number_of_events * n_hlt1_lines);
      set_size<dev_saved_tracks_list_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
      set_size<dev_saved_svs_list_t>(arguments, first<host_number_of_svs_t>(arguments));
      set_size<dev_save_track_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
      set_size<dev_save_sv_t>(arguments, first<host_number_of_svs_t>(arguments));
      set_size<dev_n_tracks_saved_t>(arguments, total_number_of_events);
      set_size<dev_n_svs_saved_t>(arguments, total_number_of_events);
      set_size<dev_n_hits_saved_t>(arguments, total_number_of_events);
      set_size<dev_n_passing_decisions_t>(arguments, total_number_of_events);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      const auto event_start = std::get<0>(runtime_options.event_interval);
      const auto total_number_of_events =
        std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);
      
      initialize<dev_sel_rb_hits_t>(arguments, 0, cuda_stream);
      initialize<dev_sel_rb_stdinfo_t>(arguments, 0, cuda_stream);
      initialize<dev_sel_rb_objtyp_t>(arguments, 0, cuda_stream);
      initialize<dev_sel_rb_substr_t>(arguments, 0, cuda_stream);
      initialize<dev_sel_rep_sizes_t>(arguments, 0, cuda_stream);
      initialize<dev_passing_event_list_t>(arguments, 0, cuda_stream);
      initialize<dev_candidate_lists_t>(arguments, 0, cuda_stream);
      initialize<dev_candidate_counts_t>(arguments, 0, cuda_stream);
      initialize<dev_dec_reports_t>(arguments, 0, cuda_stream);
      initialize<dev_save_track_t>(arguments, -1, cuda_stream);
      initialize<dev_save_sv_t>(arguments, -1, cuda_stream);
      initialize<dev_n_tracks_saved_t>(arguments, 0, cuda_stream);
      initialize<dev_n_svs_saved_t>(arguments, 0, cuda_stream);
      initialize<dev_n_hits_saved_t>(arguments, 0, cuda_stream);

#ifdef CPU
      const uint grid_dim = 1;
      const uint block_dim = 1;
#else
      uint grid_dim = 
        (first<host_number_of_selected_events_t>(arguments) + property<block_dim_x_t>() - 1) /
        property<block_dim_x_t>();
      if (grid_dim == 0) {
        grid_dim = 1;
      }
      const uint block_dim = property<block_dim_x_t>().get();
#endif

      decisions_function(dim3(grid_dim), dim3(block_dim), cuda_stream)(
        Parameters {data<dev_event_list_t>(arguments),
                    data<dev_offsets_all_velo_tracks_t>(arguments),
                    data<dev_offsets_velo_track_hit_number_t>(arguments),
                    data<dev_velo_track_hits_t>(arguments),
                    data<dev_offsets_ut_tracks_t>(arguments),
                    data<dev_offsets_ut_track_hit_number_t>(arguments),
                    data<dev_ut_qop_t>(arguments),
                    data<dev_ut_track_velo_indices_t>(arguments),
                    data<dev_offsets_scifi_track_hit_number_t>(arguments),
                    data<dev_scifi_qop_t>(arguments),
                    data<dev_scifi_states_t>(arguments),
                    data<dev_scifi_track_ut_indices_t>(arguments),
                    data<dev_ut_track_hits_t>(arguments),
                    data<dev_scifi_track_hits_t>(arguments),
                    data<dev_kf_tracks_t>(arguments),
                    data<dev_consolidated_svs_t>(arguments),
                    data<dev_offsets_forward_tracks_t>(arguments),
                    data<dev_sv_offsets_t>(arguments),
                    data<dev_sel_results_t>(arguments),
                    data<dev_sel_results_offsets_t>(arguments),
                    data<dev_candidate_lists_t>(arguments),
                    data<dev_candidate_counts_t>(arguments),
                    data<dev_n_passing_decisions_t>(arguments),
                    data<dev_n_svs_saved_t>(arguments),
                    data<dev_n_tracks_saved_t>(arguments),
                    data<dev_n_hits_saved_t>(arguments),
                    data<dev_saved_tracks_list_t>(arguments),
                    data<dev_saved_svs_list_t>(arguments),
                    data<dev_save_track_t>(arguments),
                    data<dev_save_sv_t>(arguments),
                    data<dev_dec_reports_t>(arguments),
                    data<dev_sel_rb_hits_t>(arguments),
                    data<dev_sel_rb_stdinfo_t>(arguments),
                    data<dev_sel_rb_objtyp_t>(arguments),
                    data<dev_sel_rb_substr_t>(arguments),
                    data<dev_sel_rep_sizes_t>(arguments),
                    data<dev_passing_event_list_t>(arguments)},
        first<host_number_of_selected_events_t>(arguments),
        event_start);

      raw_banks_function(dim3(grid_dim), dim3(block_dim), cuda_stream)(
        Parameters {data<dev_event_list_t>(arguments),
                    data<dev_offsets_all_velo_tracks_t>(arguments),
                    data<dev_offsets_velo_track_hit_number_t>(arguments),
                    data<dev_velo_track_hits_t>(arguments),
                    data<dev_offsets_ut_tracks_t>(arguments),
                    data<dev_offsets_ut_track_hit_number_t>(arguments),
                    data<dev_ut_qop_t>(arguments),
                    data<dev_ut_track_velo_indices_t>(arguments),
                    data<dev_offsets_scifi_track_hit_number_t>(arguments),
                    data<dev_scifi_qop_t>(arguments),
                    data<dev_scifi_states_t>(arguments),
                    data<dev_scifi_track_ut_indices_t>(arguments),
                    data<dev_ut_track_hits_t>(arguments),
                    data<dev_scifi_track_hits_t>(arguments),
                    data<dev_kf_tracks_t>(arguments),
                    data<dev_consolidated_svs_t>(arguments),
                    data<dev_offsets_forward_tracks_t>(arguments),
                    data<dev_sv_offsets_t>(arguments),
                    data<dev_sel_results_t>(arguments),
                    data<dev_sel_results_offsets_t>(arguments),
                    data<dev_candidate_lists_t>(arguments),
                    data<dev_candidate_counts_t>(arguments),
                    data<dev_n_passing_decisions_t>(arguments),
                    data<dev_n_svs_saved_t>(arguments),
                    data<dev_n_tracks_saved_t>(arguments),
                    data<dev_n_hits_saved_t>(arguments),
                    data<dev_saved_tracks_list_t>(arguments),
                    data<dev_saved_svs_list_t>(arguments),
                    data<dev_save_track_t>(arguments),
                    data<dev_save_sv_t>(arguments),
                    data<dev_dec_reports_t>(arguments),
                    data<dev_sel_rb_hits_t>(arguments),
                    data<dev_sel_rb_stdinfo_t>(arguments),
                    data<dev_sel_rb_objtyp_t>(arguments),
                    data<dev_sel_rb_substr_t>(arguments),
                    data<dev_sel_rep_sizes_t>(arguments),
                    data<dev_passing_event_list_t>(arguments)},
        first<host_number_of_selected_events_t>(arguments),
        total_number_of_events,
        event_start);

      // Copy raw bank data.
      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_dec_reports,
        data<dev_dec_reports_t>(arguments),
        size<dev_dec_reports_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));

      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_passing_event_list,
        data<dev_passing_event_list_t>(arguments),
        size<dev_passing_event_list_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));
    }

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 32};
  };
} // namespace prepare_raw_banks
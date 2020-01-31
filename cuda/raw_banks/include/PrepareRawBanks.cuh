#pragma once

#include "HltDecReport.cuh"
#include "HltSelReport.cuh"
#include "RawBanksDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "LineInfo.cuh"
#include "ParKalmanFilter.cuh"

namespace prepare_raw_banks {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
    DEVICE_INPUT(dev_offsets_ut_tracks_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_INPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_INPUT(dev_ut_track_velo_indices_t, uint) dev_ut_track_velo_indices;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number, uint) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, uint) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_ut_track_hits_t, char) dev_ut_track_hits;
    DEVICE_INPUT(dev_scifi_track_hits_t, char) dev_scifi_track_hits;
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex) dev_consolidated_svs;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_offsets_forward_tracks;
    DEVICE_INPUT(dev_sv_offsets_t, uint) dev_sv_offsets;
    DEVICE_INPUT(dev_candidate_lists_t, uint) dev_candidate_lists;
    DEVICE_INPUT(dev_candidate_counts_t, uint) dev_candidate_counts;
    DEVICE_INPUT(dev_n_svs_saved_t, uint) dev_n_svs_saved;
    DEVICE_INPUT(dev_n_tracks_saved_t, uint) dev_n_tracks_saved;
    DEVICE_INPUT(dev_n_hits_saved_t, uint) dev_n_hits_saved;
    DEVICE_INPUT(dev_saved_tracks_list_t, uint) dev_saved_tracks_list;
    DEVICE_INPUT(dev_saved_svs_list_t, uint) dev_saved_svs_list;
    DEVICE_INPUT(dev_save_track_t, int) dev_save_track;
    DEVICE_INPUT(dev_save_sv_t, int) dev_save_sv;
    DEVICE_OUTPUT(dev_dec_reports_t, uint) dev_dec_reports;
    DEVICE_OUTPUT(dev_sel_rb_hits_t, uint) dev_sel_rb_hits;
    DEVICE_OUTPUT(dev_sel_rb_stdinfo_t, uint) dev_sel_rb_stdinfo;
    DEVICE_OUTPUT(dev_sel_rb_objtyp_t, uint) dev_sel_rb_objtyp;
    DEVICE_OUTPUT(dev_sel_rb_substr_t, uint) dev_sel_rb_substr;
    DEVICE_OUTPUT(dev_sel_rep_sizes_t, uint) dev_sel_rep_sizes;
    DEVICE_OUTPUT(dev_number_of_passing_events_t, uint) dev_number_of_passing_events;
    DEVICE_OUTPUT(dev_passing_event_list_t, uint) dev_passing_event_list;
    PROPERTY(block_dim_x_t, uint, "block_dim_x", "block dimensions X", 16);
  };

  template<typename T>
  __global__ void prepare_raw_banks(Parameters, const uint number_of_events);

  template<typename T, typename U, char... S>
  struct prepare_raw_banks_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(prepare_raw_banks<U>)) function {prepare_raw_banks<U>};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_passing_event_list_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_number_of_passing_events_t>(arguments, 1);
      set_size<dev_sel_rb_hits_t>(
        arguments, value<host_number_of_reconstructed_scifi_tracks_t>(arguments) * ParKalmanFilter::nMaxMeasurements);
      set_size<dev_sel_rb_stdinfo_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Hlt1::maxStdInfoEvent);
      set_size<dev_sel_rb_objtyp_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * (Hlt1::nObjTyp + 1));
      set_size<dev_sel_rb_substr_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Hlt1::subStrDefaultAllocationSize);
      set_size<dev_sel_rep_sizes_t>(arguments, value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      initialize<dev_sel_rb_hits_t>(arguments, 0, cuda_stream);
      initialize<dev_sel_rb_stdinfo_t>(arguments, 0, cuda_stream);
      initialize<dev_sel_rb_objtyp_t>(arguments, 0, cuda_stream);
      initialize<dev_sel_rb_substr_t>(arguments, 0, cuda_stream);
      initialize<dev_sel_rep_sizes_t>(arguments, 0, cuda_stream);
      initialize<dev_number_of_passing_events_t>(arguments, 0, cuda_stream);
      initialize<dev_passing_event_list_t>(arguments, 0, cuda_stream);

#ifdef CPU
      const auto grid_dim = dim3(1);
      const auto block_dim = dim3(1);
#else
      const auto grid_dim = dim3(
        (value<host_number_of_selected_events_t>(arguments) + property<block_dim_x_t>() - 1) /
        property<block_dim_x_t>());
      const auto block_dim = dim3(property<block_dim_x_t>().get());
#endif

      function(grid_dim, block_dim, cuda_stream)(
        Parameters {begin<dev_offsets_all_velo_tracks_t>(arguments),
                    begin<dev_offsets_velo_track_hit_number_t>(arguments),
                    begin<dev_velo_track_hits_t>(arguments),
                    begin<dev_offsets_ut_tracks_t>(arguments),
                    begin<dev_offsets_ut_track_hit_number_t>(arguments),
                    begin<dev_ut_qop_t>(arguments),
                    begin<dev_ut_track_velo_indices_t>(arguments),
                    begin<dev_offsets_scifi_track_hit_number>(arguments),
                    begin<dev_scifi_qop_t>(arguments),
                    begin<dev_scifi_states_t>(arguments),
                    begin<dev_scifi_track_ut_indices_t>(arguments),
                    begin<dev_ut_track_hits_t>(arguments),
                    begin<dev_scifi_track_hits_t>(arguments),
                    begin<dev_kf_tracks_t>(arguments),
                    begin<dev_consolidated_svs_t>(arguments),
                    begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_sv_offsets_t>(arguments),
                    begin<dev_candidate_lists_t>(arguments),
                    begin<dev_candidate_counts_t>(arguments),
                    begin<dev_n_svs_saved_t>(arguments),
                    begin<dev_n_tracks_saved_t>(arguments),
                    begin<dev_n_hits_saved_t>(arguments),
                    begin<dev_saved_tracks_list_t>(arguments),
                    begin<dev_saved_svs_list_t>(arguments),
                    begin<dev_save_track_t>(arguments),
                    begin<dev_save_sv_t>(arguments),
                    begin<dev_dec_reports_t>(arguments),
                    begin<dev_sel_rb_hits_t>(arguments),
                    begin<dev_sel_rb_stdinfo_t>(arguments),
                    begin<dev_sel_rb_objtyp_t>(arguments),
                    begin<dev_sel_rb_substr_t>(arguments),
                    begin<dev_sel_rep_sizes_t>(arguments),
                    begin<dev_number_of_passing_events_t>(arguments),
                    begin<dev_passing_event_list_t>(arguments)},
        value<host_number_of_selected_events_t>(arguments));

      // Copy raw bank data.
      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_dec_reports,
        begin<dev_dec_reports_t>(arguments),
        size<dev_dec_reports_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));

      // Copy list of passing events.
      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_number_of_passing_events,
        begin<dev_number_of_passing_events_t>(arguments),
        size<dev_number_of_passing_events_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));

      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_passing_event_list,
        begin<dev_passing_event_list_t>(arguments),
        size<dev_passing_event_list_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));
    }

  private:
    Property<block_dim_x_t> m_block_dim_x {this};
  };
} // namespace prepare_raw_banks

#include "PrepareRawBanks.icc"

#include "ConsolidateSciFi.cuh"

void scifi_consolidate_tracks_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  arguments.set_size<dev_scifi_track_hits>(
    host_buffers.host_accumulated_number_of_hits_in_scifi_tracks[0] * sizeof(SciFi::Hit));
  arguments.set_size<dev_scifi_qop>(host_buffers.host_number_of_reconstructed_scifi_tracks[0]);
  arguments.set_size<dev_scifi_track_ut_indices>(host_buffers.host_number_of_reconstructed_scifi_tracks[0]);
  arguments.set_size<dev_scifi_states>(host_buffers.host_number_of_reconstructed_scifi_tracks[0]);
}

void scifi_consolidate_tracks_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  function.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_scifi_track_hits>(),
    arguments.offset<dev_atomics_scifi>(),
    arguments.offset<dev_scifi_track_hit_number>(),
    arguments.offset<dev_scifi_qop>(),
    arguments.offset<dev_scifi_states>(),
    arguments.offset<dev_scifi_track_ut_indices>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_scifi_tracks>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res,
    arguments.offset<dev_scifi_lf_parametrization_consolidate>());

  // Transmission device to host of Scifi consolidated tracks
  if (runtime_options.do_check) {
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_atomics_scifi,
      arguments.offset<dev_atomics_scifi>(),
      arguments.size<dev_atomics_scifi>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_scifi_track_hit_number,
      arguments.offset<dev_scifi_track_hit_number>(),
      arguments.size<dev_scifi_track_hit_number>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_scifi_track_hits,
      arguments.offset<dev_scifi_track_hits>(),
      arguments.size<dev_scifi_track_hits>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_scifi_qop,
      arguments.offset<dev_scifi_qop>(),
      arguments.size<dev_scifi_qop>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_scifi_track_ut_indices,
      arguments.offset<dev_scifi_track_ut_indices>(),
      arguments.size<dev_scifi_track_ut_indices>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
  }
}

__global__ void scifi_consolidate_tracks(
  uint* dev_scifi_hits,
  uint* dev_scifi_hit_count,
  char* dev_scifi_consolidated_hits,
  uint* dev_atomics_scifi,
  uint* dev_scifi_track_hit_number,
  float* dev_scifi_qop,
  MiniState* dev_scifi_states,
  uint* dev_scifi_track_ut_indices,
  uint* dev_atomics_ut,
  SciFi::TrackHits* dev_scifi_tracks,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const float* dev_scifi_lf_parametrization_consolidate)
{

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  const uint ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  // const SciFi::TrackHits* event_scifi_tracks =
  //   dev_scifi_tracks + ut_event_tracks_offset *
  //   LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter;
  const SciFi::TrackHits* event_scifi_tracks =
    dev_scifi_tracks + ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track;
  
  const uint total_number_of_scifi_hits =
    dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  SciFi::Hits scifi_hits(dev_scifi_hits, total_number_of_scifi_hits, &scifi_geometry, dev_inv_clus_res);
  const SciFi::HitCount scifi_hit_count {dev_scifi_hit_count, event_number};

  // Create consolidated SoAs.
  SciFi::Consolidated::Tracks scifi_tracks {(uint*) dev_atomics_scifi,
                                            dev_scifi_track_hit_number,
                                            dev_scifi_qop,
                                            dev_scifi_states,
                                            dev_scifi_track_ut_indices,
                                            event_number,
                                            number_of_events};
  const uint number_of_tracks_event = scifi_tracks.number_of_tracks(event_number);
  const uint event_offset = scifi_hit_count.event_offset();

  // Loop over tracks.
  for (uint i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    scifi_tracks.ut_track[i] = event_scifi_tracks[i].ut_track_index;
    scifi_tracks.qop[i] = event_scifi_tracks[i].qop;
    const auto scifi_track_index = ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + i;
    
    const auto curvature = dev_scifi_lf_parametrization_consolidate[scifi_track_index];
    const auto tx = dev_scifi_lf_parametrization_consolidate
      [ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track +
       scifi_track_index];
    const auto x0 = dev_scifi_lf_parametrization_consolidate
      [2 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track +
       scifi_track_index];
    const auto d_ratio = dev_scifi_lf_parametrization_consolidate
      [3 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track +
       scifi_track_index];
    const auto y0 = dev_scifi_lf_parametrization_consolidate
      [4 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track +
       scifi_track_index];
    const auto ty = dev_scifi_lf_parametrization_consolidate
      [5 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track +
       scifi_track_index];

    const auto dz = SciFi::Constants::ZEndT - LookingForward::z_mid_t;
    const MiniState scifi_state {
      x0 + tx * dz + curvature * dz * dz * (1.f + d_ratio * dz),
      y0 + ty * SciFi::Constants::ZEndT,
      SciFi::Constants::ZEndT,
      tx + 2.f * dz * curvature + 3.f * dz * dz * curvature * d_ratio,
      ty
    };

    scifi_tracks.states[i] = scifi_state;
    
    SciFi::Consolidated::Hits consolidated_hits =
      scifi_tracks.get_hits(dev_scifi_consolidated_hits, i, &scifi_geometry, dev_inv_clus_res);
    SciFi::TrackHits track = event_scifi_tracks[i];

    // Lambda for populating arrays.
    auto populate = [&track](uint32_t* __restrict__ a, uint32_t* __restrict__ b) {
      for (int i = 0; i < track.hitsNum; i++) {
        const auto hit_index = track.hits[i];
        a[i] = b[hit_index];
      }
    };

    // Populate the consolidated hits.
    populate((uint32_t*) consolidated_hits.x0, (uint32_t*) scifi_hits.x0 + event_offset);
    populate((uint32_t*) consolidated_hits.z0, (uint32_t*) scifi_hits.z0 + event_offset);
    populate((uint32_t*) consolidated_hits.m_endPointY, (uint32_t*) scifi_hits.m_endPointY + event_offset);
    populate((uint32_t*) consolidated_hits.channel, (uint32_t*) scifi_hits.channel + event_offset);
    populate(
      (uint32_t*) consolidated_hits.assembled_datatype, (uint32_t*) scifi_hits.assembled_datatype + event_offset);
  }
}

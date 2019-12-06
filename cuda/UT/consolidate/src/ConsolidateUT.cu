#include "ConsolidateUT.cuh"

void ut_consolidate_tracks_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  arguments.set_size<dev_ut_track_hits>(host_buffers.host_accumulated_number_of_ut_hits[0] * sizeof(UT::Hit));
  arguments.set_size<dev_ut_qop>(host_buffers.host_number_of_reconstructed_ut_tracks[0]);
  arguments.set_size<dev_ut_track_velo_indices>(host_buffers.host_number_of_reconstructed_ut_tracks[0]);
  arguments.set_size<dev_ut_x>(host_buffers.host_number_of_reconstructed_ut_tracks[0]);
  arguments.set_size<dev_ut_z>(host_buffers.host_number_of_reconstructed_ut_tracks[0]);
  arguments.set_size<dev_ut_tx>(host_buffers.host_number_of_reconstructed_ut_tracks[0]);
}

void ut_consolidate_tracks_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  function.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
    arguments.offset<dev_ut_hits>(),
    arguments.offset<dev_ut_hit_offsets>(),
    arguments.offset<dev_ut_track_hits>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_track_hit_number>(),
    arguments.offset<dev_ut_qop>(),
    arguments.offset<dev_ut_x>(),
    arguments.offset<dev_ut_tx>(),
    arguments.offset<dev_ut_z>(),
    arguments.offset<dev_ut_track_velo_indices>(),
    arguments.offset<dev_ut_tracks>(),
    constants.dev_unique_x_sector_layer_offsets.data());

  if (runtime_options.do_check) {
    // Transmission device to host of UT consolidated tracks
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_atomics_ut,
      arguments.offset<dev_atomics_ut>(),
      (2 * host_buffers.host_number_of_selected_events[0] + 1) * sizeof(uint),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_track_hit_number,
      arguments.offset<dev_ut_track_hit_number>(),
      arguments.size<dev_ut_track_hit_number>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_track_hits,
      arguments.offset<dev_ut_track_hits>(),
      host_buffers.host_accumulated_number_of_hits_in_ut_tracks[0] * sizeof(UT::Hit),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_qop,
      arguments.offset<dev_ut_qop>(),
      arguments.size<dev_ut_qop>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_x,
      arguments.offset<dev_ut_x>(),
      arguments.size<dev_ut_x>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_tx,
      arguments.offset<dev_ut_tx>(),
      arguments.size<dev_ut_tx>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_z,
      arguments.offset<dev_ut_z>(),
      arguments.size<dev_ut_z>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));

    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_ut_track_velo_indices,
      arguments.offset<dev_ut_track_velo_indices>(),
      arguments.size<dev_ut_track_velo_indices>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
  }
}

__global__ void ut_consolidate_tracks(
  uint* dev_ut_hits,
  uint* dev_ut_hit_offsets,
  char* dev_ut_track_hits,
  uint* dev_atomics_ut,
  uint* dev_ut_track_hit_number,
  float* dev_ut_qop,
  float* dev_ut_x,
  float* dev_ut_tx,
  float* dev_ut_z,
  uint* dev_ut_track_velo_indices,
  const UT::TrackHits* dev_veloUT_tracks,
  const uint* dev_unique_x_sector_layer_offsets)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  const uint number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[4];
  const uint total_number_of_hits = dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];
  const UT::TrackHits* event_veloUT_tracks = dev_veloUT_tracks + event_number * UT::Constants::max_num_tracks;

  const UT::Hits ut_hits {dev_ut_hits, total_number_of_hits};
  const UT::HitOffsets ut_hit_offsets {
    dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  const auto event_offset = ut_hit_offsets.event_offset();

  // Create consolidated SoAs.
  UT::Consolidated::Tracks ut_tracks {(uint*) dev_atomics_ut,
                                      dev_ut_track_hit_number,
                                      dev_ut_qop,
                                      dev_ut_track_velo_indices,
                                      event_number,
                                      number_of_events};
  const uint number_of_tracks_event = ut_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = ut_tracks.tracks_offset(event_number);

  // Loop over tracks.
  for (uint i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    ut_tracks.velo_track[i] = event_veloUT_tracks[i].velo_track_index;
    ut_tracks.qop[i] = event_veloUT_tracks[i].qop;
    const int track_index = event_tracks_offset + i;
    dev_ut_x[track_index] = event_veloUT_tracks[i].x;
    dev_ut_z[track_index] = event_veloUT_tracks[i].z;
    dev_ut_tx[track_index] = event_veloUT_tracks[i].tx;
    UT::Consolidated::Hits consolidated_hits = ut_tracks.get_hits(dev_ut_track_hits, i);
    const UT::TrackHits track = event_veloUT_tracks[i];

    // Lambda for populating arrays.
    auto populate = [&track](uint32_t* __restrict__ a, uint32_t* __restrict__ b) {
      int hit_number = 0;
      for (uint i = 0; i < UT::Constants::n_layers; ++i) {
        const auto hit_index = track.hits[i];
        if (hit_index != -1) {
          a[hit_number++] = b[hit_index];
        }
      }
    };

    // Populate the plane code.
    auto populate_plane_code = [](uint8_t* __restrict__ a, const UT::TrackHits& track) {
      int hit_number = 0;
      for (uint8_t i = 0; i < UT::Constants::n_layers; ++i) {
        const auto hit_index = track.hits[i];
        if (hit_index != -1) {
          a[hit_number++] = i;
        }
      }
    };

    // Populate the consolidated hits.
    populate((uint32_t*) consolidated_hits.yBegin, (uint32_t*) ut_hits.yBegin + event_offset);
    populate((uint32_t*) consolidated_hits.yEnd, (uint32_t*) ut_hits.yEnd + event_offset);
    populate((uint32_t*) consolidated_hits.zAtYEq0, (uint32_t*) ut_hits.zAtYEq0 + event_offset);
    populate((uint32_t*) consolidated_hits.xAtYEq0, (uint32_t*) ut_hits.xAtYEq0 + event_offset);
    populate((uint32_t*) consolidated_hits.LHCbID, (uint32_t*) ut_hits.LHCbID + event_offset);
    populate((uint32_t*) consolidated_hits.weight, (uint32_t*) ut_hits.weight + event_offset);
    populate_plane_code(consolidated_hits.plane_code, track);
  }
}

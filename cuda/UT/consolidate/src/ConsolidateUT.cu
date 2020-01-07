#include "ConsolidateUT.cuh"

__global__ void ut_consolidate_tracks::ut_consolidate_tracks(
  ut_consolidate_tracks::Arguments arguments,
  const uint* dev_unique_x_sector_layer_offsets)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  const uint number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[4];
  const uint total_number_of_hits = arguments.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];
  const UT::TrackHits* event_veloUT_tracks = arguments.dev_ut_tracks + event_number * UT::Constants::max_num_tracks;

  // TODO: Make const container
  const UT::Hits ut_hits {const_cast<uint*>(arguments.dev_ut_hits.get()), total_number_of_hits};
  const UT::HitOffsets ut_hit_offsets {
    arguments.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  const auto event_offset = ut_hit_offsets.event_offset();

  // Create consolidated SoAs.
  // TODO: Make const container
  UT::Consolidated::Tracks ut_tracks {const_cast<uint*>(arguments.dev_atomics_ut.get()),
                                      const_cast<uint*>(arguments.dev_ut_track_hit_number.get()),
                                      arguments.dev_ut_qop,
                                      arguments.dev_ut_track_velo_indices,
                                      event_number,
                                      number_of_events};
  const uint number_of_tracks_event = ut_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = ut_tracks.tracks_offset(event_number);

  // Loop over tracks.
  for (uint i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    ut_tracks.velo_track[i] = event_veloUT_tracks[i].velo_track_index;
    ut_tracks.qop[i] = event_veloUT_tracks[i].qop;
    const int track_index = event_tracks_offset + i;
    arguments.dev_ut_x[track_index] = event_veloUT_tracks[i].x;
    arguments.dev_ut_z[track_index] = event_veloUT_tracks[i].z;
    arguments.dev_ut_tx[track_index] = event_veloUT_tracks[i].tx;
    UT::Consolidated::Hits consolidated_hits = ut_tracks.get_hits(arguments.dev_ut_track_hits, i);
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

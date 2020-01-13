#include "ConsolidateUT.cuh"

template<typename F>
__device__ void populate(const UT::TrackHits& track, const F& assign)
{
  int hit_number = 0;
  for (uint i = 0; i < UT::Constants::n_layers; ++i) {
    const auto hit_index = track.hits[i];
    if (hit_index != -1) {
      assign(hit_number++, i);
    }
  }
}

__global__ void ut_consolidate_tracks::ut_consolidate_tracks(
  ut_consolidate_tracks::Parameters parameters,
  const uint* dev_unique_x_sector_layer_offsets)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  const uint number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[4];
  const uint total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];
  const UT::TrackHits* event_veloUT_tracks = parameters.dev_ut_tracks + event_number * UT::Constants::max_num_tracks;

  // TODO: Make const container
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits};
  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  const auto event_offset = ut_hit_offsets.event_offset();

  // Create consolidated SoAs.
  UT::Consolidated::Tracks ut_tracks {parameters.dev_atomics_ut,
                                            parameters.dev_ut_track_hit_number,
                                            parameters.dev_ut_qop,
                                            parameters.dev_ut_track_velo_indices,
                                            event_number,
                                            number_of_events};
                                            
  const uint number_of_tracks_event = ut_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = ut_tracks.tracks_offset(event_number);

  // Loop over tracks.
  for (uint i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    ut_tracks.velo_track(i) = event_veloUT_tracks[i].velo_track_index;
    ut_tracks.qop(i) = event_veloUT_tracks[i].qop;
    const int track_index = event_tracks_offset + i;
    parameters.dev_ut_x[track_index] = event_veloUT_tracks[i].x;
    parameters.dev_ut_z[track_index] = event_veloUT_tracks[i].z;
    parameters.dev_ut_tx[track_index] = event_veloUT_tracks[i].tx;
    UT::Consolidated::Hits consolidated_hits = ut_tracks.get_hits(parameters.dev_ut_track_hits, i);
    const UT::TrackHits track = event_veloUT_tracks[i];

    // Populate the consolidated hits.
    populate(track, [&consolidated_hits, &ut_hits, &event_offset] (const uint hit_number, const uint i) {
      consolidated_hits.yBegin(hit_number) = ut_hits.yBegin(event_offset + i);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset] (const uint hit_number, const uint i) {
      consolidated_hits.yEnd(hit_number) = ut_hits.yEnd(event_offset + i);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset] (const uint hit_number, const uint i) {
      consolidated_hits.zAtYEq0(hit_number) = ut_hits.zAtYEq0(event_offset + i);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset] (const uint hit_number, const uint i) {
      consolidated_hits.xAtYEq0(hit_number) = ut_hits.xAtYEq0(event_offset + i);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset] (const uint hit_number, const uint i) {
      consolidated_hits.id(hit_number) = ut_hits.id(event_offset + i);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset] (const uint hit_number, const uint i) {
      consolidated_hits.weight(hit_number) = ut_hits.weight(event_offset + i);
    });

    populate(track, [&consolidated_hits] (const uint hit_number, const uint i) {
      consolidated_hits.plane_code(hit_number) = i;
    });
  }
}

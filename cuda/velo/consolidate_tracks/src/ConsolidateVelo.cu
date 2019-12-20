#include "../include/ConsolidateVelo.cuh"

using namespace velo_consolidate_tracks;

/**
 * @brief Calculates the parameters according to a root means square fit
 */
__device__ VeloState means_square_fit(Velo::Consolidated::Hits& consolidated_hits, const Velo::TrackHits& track)
{
  VeloState state;

  // Fit parameters
  float s0, sx, sz, sxz, sz2;
  float u0, uy, uz, uyz, uz2;
  s0 = sx = sz = sxz = sz2 = 0.0f;
  u0 = uy = uz = uyz = uz2 = 0.0f;

  // Iterate over hits
  for (unsigned short h = 0; h < track.hitsNum; ++h) {
    const auto x = consolidated_hits.x[h];
    const auto y = consolidated_hits.y[h];
    const auto z = consolidated_hits.z[h];

    const auto wx = Velo::Tracking::param_w;
    const auto wx_t_x = wx * x;
    const auto wx_t_z = wx * z;
    s0 += wx;
    sx += wx_t_x;
    sz += wx_t_z;
    sxz += wx_t_x * z;
    sz2 += wx_t_z * z;

    const auto wy = Velo::Tracking::param_w;
    const auto wy_t_y = wy * y;
    const auto wy_t_z = wy * z;
    u0 += wy;
    uy += wy_t_y;
    uz += wy_t_z;
    uyz += wy_t_y * z;
    uz2 += wy_t_z * z;
  }

  // Calculate tx, ty and backward
  const auto dens = 1.0f / (sz2 * s0 - sz * sz);
  state.tx = (sxz * s0 - sx * sz) * dens;
  state.x = (sx * sz2 - sxz * sz) * dens;

  const auto denu = 1.0f / (uz2 * u0 - uz * uz);
  state.ty = (uyz * u0 - uy * uz) * denu;
  state.y = (uy * uz2 - uyz * uz) * denu;

  state.z = -(state.x * state.tx + state.y * state.ty) / (state.tx * state.tx + state.ty * state.ty);
  state.backward = state.z > consolidated_hits.z[0];

  state.x = state.x + state.tx * state.z;
  state.y = state.y + state.ty * state.z;

  return state;
}

template<typename T, typename F>
__device__ void populate(const Velo::TrackHits& track, T* __restrict__ a, const F& fn)
{
  for (int i = 0; i < track.hitsNum; ++i) {
    const auto hit_index = track.hits[i];
    a[i] = fn(hit_index);
  }
}

__global__ void velo_consolidate_tracks::velo_consolidate_tracks(
  dev_atomics_velo_t dev_atomics_velo,
  dev_tracks_t dev_tracks,
  dev_velo_track_hit_number_t dev_velo_track_hit_number,
  dev_sorted_velo_cluster_container_t dev_sorted_velo_cluster_container,
  dev_offsets_estimated_input_size_t dev_offsets_estimated_input_size,
  dev_velo_track_hits_t dev_velo_track_hits,
  dev_velo_states_t dev_velo_states)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  const Velo::TrackHits* event_tracks = dev_tracks + event_number * Velo::Constants::max_tracks;

  // Consolidated datatypes
  const Velo::Consolidated::Tracks velo_tracks {dev_atomics_velo, dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::States velo_states {const_cast<char*>(dev_velo_states.get()), velo_tracks.total_number_of_tracks()};

  const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

  // Pointers to data within event
  const uint total_estimated_number_of_clusters = dev_offsets_estimated_input_size[Velo::Constants::n_modules * number_of_events];
  const uint* module_hitStarts = dev_offsets_estimated_input_size + event_number * Velo::Constants::n_modules;
  const uint hit_offset = module_hitStarts[0];

  // TODO: Offset'ed container
  const auto velo_cluster_container =
    Velo::Clusters {dev_sorted_velo_cluster_container.get() + hit_offset, total_estimated_number_of_clusters};

  for (uint i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    Velo::Consolidated::Hits consolidated_hits = velo_tracks.get_hits(dev_velo_track_hits, i);
    const Velo::TrackHits track = event_tracks[i];

    populate<float>(track, consolidated_hits.x, [&velo_cluster_container] (const uint hit_index) {
      return velo_cluster_container.x(hit_index);
    });
    populate<float>(track, consolidated_hits.y, [&velo_cluster_container] (const uint hit_index) {
      return velo_cluster_container.y(hit_index);
    });
    populate<float>(track, consolidated_hits.z, [&velo_cluster_container] (const uint hit_index) {
      return velo_cluster_container.z(hit_index);
    });
    populate<uint32_t>(
      track, consolidated_hits.LHCbID, [&velo_cluster_container] (const uint hit_index) {
      return velo_cluster_container.id(hit_index);
    });
    
    // Calculate and store fit in consolidated container
    VeloState beam_state = means_square_fit(consolidated_hits, track);
    velo_states.set(event_tracks_offset + i, beam_state);
  }
}

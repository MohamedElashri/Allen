#include "../include/ConsolidateVelo.cuh"

void velo_consolidate_tracks_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
}

void velo_consolidate_tracks_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  
}

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

template<typename T>
__device__ void populate(const Velo::TrackHits& track, T* __restrict__ a, const T* __restrict__ b)
{
  for (int i = 0; i < track.hitsNum; ++i) {
    const auto hit_index = track.hits[i];
    a[i] = b[hit_index];
  }
}

__global__ void velo_consolidate_tracks(
  dev_atomics_velo_t dev_atomics_velo,
  dev_tracks_t dev_tracks,
  dev_velo_track_hit_number_t dev_velo_track_hit_number,
  dev_velo_cluster_container_t dev_velo_cluster_container,
  dev_module_cluster_start_t dev_module_cluster_start,
  dev_velo_track_hits_t dev_velo_track_hits,
  dev_velo_states_t dev_velo_states)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  const Velo::TrackHits* event_tracks = dev_tracks + event_number * Velo::Constants::max_tracks;

  // Consolidated datatypes
  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) dev_atomics_velo, dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::States velo_states {dev_velo_states, velo_tracks.total_number_of_tracks};

  const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

  // Pointers to data within event
  const uint number_of_hits = dev_module_cluster_start[Velo::Constants::n_modules * number_of_events];
  const uint* module_hitStarts = dev_module_cluster_start + event_number * Velo::Constants::n_modules;
  const uint hit_offset = module_hitStarts[0];

  // Order has changed since SortByPhi
  const float* float_dev_velo_cluster_container = (float*) (dev_velo_cluster_container);
  // const uint32_t* hit_IDs = (uint32_t*) (dev_velo_cluster_container + 2 * number_of_hits + hit_offset);
  // const float* hit_Xs = (float*) (dev_velo_cluster_container + 5 * number_of_hits + hit_offset);
  // const float* hit_Ys = (float*) (dev_velo_cluster_container + hit_offset);
  // const float* hit_Zs = (float*) (dev_velo_cluster_container + number_of_hits + hit_offset);

  for (uint i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    Velo::Consolidated::Hits consolidated_hits = velo_tracks.get_hits(dev_velo_track_hits, i);
    const Velo::TrackHits track = event_tracks[i];

    populate<float>(track, consolidated_hits.x, float_dev_velo_cluster_container + 5 * number_of_hits + hit_offset);
    populate<float>(track, consolidated_hits.y, float_dev_velo_cluster_container + hit_offset);
    populate<float>(track, consolidated_hits.z, float_dev_velo_cluster_container + number_of_hits + hit_offset);
    populate<uint32_t>(
      track, consolidated_hits.LHCbID, (uint32_t*) dev_velo_cluster_container + 2 * number_of_hits + hit_offset);

    // Calculate and store fit in consolidated container
    VeloState beam_state = means_square_fit(consolidated_hits, track);
    velo_states.set(event_tracks_offset + i, beam_state);
  }
}

#include "VeloConsolidateTracks.cuh"

/**
 * @brief Calculates the parameters according to a root means square fit
 */
__device__ VeloState means_square_fit(const Velo::Consolidated::Hits& consolidated_hits, const uint number_of_hits)
{
  VeloState state;

  // Fit parameters
  float s0, sx, sz, sxz, sz2;
  float u0, uy, uz, uyz, uz2;
  s0 = sx = sz = sxz = sz2 = 0.0f;
  u0 = uy = uz = uyz = uz2 = 0.0f;

  // Iterate over hits
  for (unsigned short h = 0; h < number_of_hits; ++h) {
    const auto x = consolidated_hits.x(h);
    const auto y = consolidated_hits.y(h);
    const auto z = consolidated_hits.z(h);

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
  state.backward = state.z > consolidated_hits.z(0);

  state.x = state.x + state.tx * state.z;
  state.y = state.y + state.ty * state.z;

  return state;
}

template<typename F>
__device__ void populate(const Velo::TrackHits* track, const uint number_of_hits, const F& assign)
{
  for (uint i = 0; i < number_of_hits; ++i) {
    const auto hit_index = track->hits[i];
    assign(i, hit_index);
  }
}

__global__ void velo_consolidate_tracks::velo_consolidate_tracks(velo_consolidate_tracks::Parameters parameters)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  const Velo::TrackHits* event_tracks = parameters.dev_tracks + event_number * Velo::Constants::max_tracks;
  const Velo::TrackletHits* three_hit_tracks =
    parameters.dev_three_hit_tracks_output + event_number * Velo::Constants::max_tracks;

  // Consolidated datatypes
  const Velo::Consolidated::Tracks velo_tracks {parameters.dev_offsets_all_velo_tracks,
                                                parameters.dev_offsets_velo_track_hit_number,
                                                event_number,
                                                number_of_events};
  Velo::Consolidated::States velo_states {parameters.dev_velo_states, velo_tracks.total_number_of_tracks()};

  const uint event_number_of_tracks = velo_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

  const auto event_number_of_three_hit_tracks_filtered =
    parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number + 1] -
    parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number];
  const auto event_number_of_tracks_in_main_track_container =
    event_number_of_tracks - event_number_of_three_hit_tracks_filtered;

  // Pointers to data within event
  const uint total_estimated_number_of_clusters =
    parameters.dev_offsets_estimated_input_size[Velo::Constants::n_module_pairs * number_of_events];
  const uint* module_hitStarts =
    parameters.dev_offsets_estimated_input_size + event_number * Velo::Constants::n_module_pairs;
  const uint hit_offset = module_hitStarts[0];

  // Offset'ed container
  const auto velo_cluster_container =
    Velo::ConstClusters {parameters.dev_sorted_velo_cluster_container, total_estimated_number_of_clusters, hit_offset};

  for (uint i = threadIdx.x; i < event_number_of_tracks; i += blockDim.x) {
    Velo::Consolidated::Hits consolidated_hits = velo_tracks.get_hits(parameters.dev_velo_track_hits, i);

    Velo::TrackHits* track;
    uint number_of_hits;

    if (i < event_number_of_tracks_in_main_track_container) {
      track = const_cast<Velo::TrackHits*>(event_tracks) + i;
      number_of_hits = track->hitsNum;
    }
    else {
      track = const_cast<Velo::TrackHits*>(reinterpret_cast<const Velo::TrackHits*>(
        three_hit_tracks + i - event_number_of_tracks_in_main_track_container));
      number_of_hits = 3;
    }

    // Populate hits in a coalesced manner, taking into account
    // the underlying container.
    populate(
      track, number_of_hits, [&velo_cluster_container, &consolidated_hits](const uint i, const uint hit_index) {
        consolidated_hits.set_x(i, velo_cluster_container.x(hit_index));
        consolidated_hits.set_y(i, velo_cluster_container.y(hit_index));
        consolidated_hits.set_z(i, velo_cluster_container.z(hit_index));
      });

    populate(
      track, number_of_hits, [&velo_cluster_container, &consolidated_hits](const uint i, const uint hit_index) {
        consolidated_hits.set_id(i, velo_cluster_container.id(hit_index));
      });

    // Calculate and store fit in consolidated container
    const VeloState beam_state = means_square_fit(consolidated_hits, number_of_hits);
    velo_states.set(event_tracks_offset + i, beam_state);
  }
}

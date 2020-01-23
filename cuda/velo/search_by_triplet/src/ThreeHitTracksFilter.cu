#include "ThreeHitTracksFilter.cuh"

/**
 * @brief Calculates the parameters according to a root means square fit
 *        and returns the chi2.
 */
__device__ float means_square_fit_chi2(Velo::ConstClusters& velo_cluster_container, const Velo::TrackletHits& track)
{
  VeloState state;

  // Fit parameters
  float s0, sx, sz, sxz, sz2;
  float u0, uy, uz, uyz, uz2;
  s0 = sx = sz = sxz = sz2 = 0.0f;
  u0 = uy = uz = uyz = uz2 = 0.0f;

  // Iterate over hits
  for (unsigned short h = 0; h < 3; ++h) {
    const auto hit_number = track.hits[h];
    const auto x = velo_cluster_container.x(hit_number);
    const auto y = velo_cluster_container.y(hit_number);
    const auto z = velo_cluster_container.z(hit_number);

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

  {
    // Calculate tx, ty and backward
    const auto dens = 1.0f / (sz2 * s0 - sz * sz);
    state.tx = (sxz * s0 - sx * sz) * dens;
    state.x = (sx * sz2 - sxz * sz) * dens;

    const auto denu = 1.0f / (uz2 * u0 - uz * uz);
    state.ty = (uyz * u0 - uy * uz) * denu;
    state.y = (uy * uz2 - uyz * uz) * denu;
  }

  float chi2;
  {
    //=========================================================================
    // Chi2 / degrees-of-freedom of straight-line fit
    //=========================================================================
    float ch = 0.0f;
    int nDoF = -4;
    for (uint h = 0; h < 3; ++h) {
      const auto hit_number = track.hits[h];

      const auto z = velo_cluster_container.z(hit_number);
      const auto x = state.x + state.tx * z;
      const auto y = state.y + state.ty * z;

      const auto dx = x - velo_cluster_container.x(hit_number);
      const auto dy = y - velo_cluster_container.y(hit_number);

      ch += dx * dx * Velo::Tracking::param_w + dy * dy * Velo::Tracking::param_w;

      // Nice :)
      // TODO: We can get rid of the X and Y read here
      // float sum_w_xzi_2 = CL_Velo::Tracking::param_w * x; // for each hit
      // float sum_w_xi_2 = CL_Velo::Tracking::param_w * velo_cluster_container.x(hit_number]; // for each hit
      // ch = (sum_w_xzi_2 - sum_w_xi_2) + (sum_w_yzi_2 - sum_w_yi_2);

      nDoF += 2;
    }
    chi2 = ch / nDoF;
  }

  return chi2;
}

/**
 * @brief Calculates the scatter of the three hits.
 *        Unused, but it can be a replacement of the above if needed.
 */
__device__ float scatter(Velo::ConstClusters& velo_cluster_container, const Velo::TrackletHits& track)
{
  const Velo::HitBase h0 {velo_cluster_container.x(track.hits[0]),
                          velo_cluster_container.y(track.hits[0]),
                          velo_cluster_container.z(track.hits[0])};
  const Velo::HitBase h1 {velo_cluster_container.x(track.hits[1]),
                          velo_cluster_container.y(track.hits[1]),
                          velo_cluster_container.z(track.hits[1])};
  const Velo::HitBase h2 {velo_cluster_container.x(track.hits[2]),
                          velo_cluster_container.y(track.hits[2]),
                          velo_cluster_container.z(track.hits[2])};

  // Calculate prediction
  const auto z2_tz = (h2.z - h0.z) / (h1.z - h0.z);
  const auto x = h0.x + (h1.x - h0.x) * z2_tz;
  const auto y = h0.y + (h1.y - h0.y) * z2_tz;
  const auto dx = x - h2.x;
  const auto dy = y - h2.y;

  // Calculate scatter
  return (dx * dx) + (dy * dy);
}

__device__ void three_hit_tracks_filter_impl(
  const Velo::TrackletHits* input_tracks,
  const uint number_of_input_tracks,
  Velo::TrackletHits* output_tracks,
  uint* number_of_output_tracks,
  const bool* hit_used,
  Velo::ConstClusters& velo_cluster_container,
  const float max_chi2)
{

  for (uint track_number = threadIdx.x; track_number < number_of_input_tracks; track_number += blockDim.x) {
    const Velo::TrackletHits& t = input_tracks[track_number];
    const bool any_used = hit_used[t.hits[0]] || hit_used[t.hits[1]] || hit_used[t.hits[2]];
    const float chi2 = means_square_fit_chi2(velo_cluster_container, t);

    // Store them in the tracks bag
    if (!any_used && chi2 < max_chi2) {
      const uint track_insert_number = atomicAdd(number_of_output_tracks, 1);
      assert(track_insert_number < Velo::Constants::max_tracks);
      output_tracks[track_insert_number] = t;
    }
  }
}

__global__ void velo_three_hit_tracks_filter::velo_three_hit_tracks_filter(
  velo_three_hit_tracks_filter::Parameters parameters)
{
  // Data initialization
  const uint event_number = blockIdx.x;
  const uint number_of_events = gridDim.x;
  const uint tracks_offset = event_number * Velo::Constants::max_tracks;

  // Pointers to data within the event
  const uint total_estimated_number_of_clusters =
    parameters.dev_offsets_estimated_input_size[Velo::Constants::n_modules * number_of_events];
  const uint* module_hitStarts =
    parameters.dev_offsets_estimated_input_size + event_number * Velo::Constants::n_modules;
  const uint hit_offset = module_hitStarts[0];
  const bool* hit_used = parameters.dev_hit_used + hit_offset;

  // Offseted VELO cluster container
  const auto velo_cluster_container =
    Velo::ConstClusters {parameters.dev_sorted_velo_cluster_container + hit_offset, total_estimated_number_of_clusters};

  // Input three hit tracks
  const Velo::TrackletHits* input_tracks =
    parameters.dev_three_hit_tracks_input + event_number * parameters.max_weak_tracks;
  const auto number_of_input_tracks = parameters.dev_atomics_velo[event_number * Velo::num_atomics];

  // Output containers
  Velo::TrackletHits* output_tracks = parameters.dev_three_hit_tracks_output.get() + tracks_offset;
  uint* number_of_output_tracks = parameters.dev_number_of_three_hit_tracks_output.get() + event_number;

  three_hit_tracks_filter_impl(
    input_tracks,
    number_of_input_tracks,
    output_tracks,
    number_of_output_tracks,
    hit_used,
    velo_cluster_container,
    parameters.max_chi2);
}

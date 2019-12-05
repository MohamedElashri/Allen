#include "SearchByTriplet.cuh"
#include "WeakTracksAdder.cuh"

void velo_weak_tracks_adder_t::visit(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  algorithm.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
    arguments.offset<dev_velo_cluster_container>(),
    arguments.offset<dev_estimated_input_size>(),
    arguments.offset<dev_tracks>(),
    arguments.offset<dev_weak_tracks>(),
    arguments.offset<dev_hit_used>(),
    arguments.offset<dev_atomics_velo>());
}

/**
 * @brief Calculates the parameters according to a root means square fit
 *        and returns the chi2.
 */
__device__ float
means_square_fit_chi2(const float* hit_Xs, const float* hit_Ys, const float* hit_Zs, const Velo::TrackletHits& track)
{
  VeloState state;

  // Fit parameters
  float s0, sx, sz, sxz, sz2;
  float u0, uy, uz, uyz, uz2;
  s0 = sx = sz = sxz = sz2 = 0.0f;
  u0 = uy = uz = uyz = uz2 = 0.0f;

  // Iterate over hits
  for (unsigned short h = 0; h < 3; ++h) {
    const auto hitno = track.hits[h];
    const auto x = hit_Xs[hitno];
    const auto y = hit_Ys[hitno];
    const auto z = hit_Zs[hitno];

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
      const auto hitno = track.hits[h];

      const auto z = hit_Zs[hitno];
      const auto x = state.x + state.tx * z;
      const auto y = state.y + state.ty * z;

      const auto dx = x - hit_Xs[hitno];
      const auto dy = y - hit_Ys[hitno];

      ch += dx * dx * Velo::Tracking::param_w + dy * dy * Velo::Tracking::param_w;

      // Nice :)
      // TODO: We can get rid of the X and Y read here
      // float sum_w_xzi_2 = CL_Velo::Tracking::param_w * x; // for each hit
      // float sum_w_xi_2 = CL_Velo::Tracking::param_w * hit_Xs[hitno]; // for each hit
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
__device__ float scatter(const float* hit_Xs, const float* hit_Ys, const float* hit_Zs, const Velo::TrackletHits& track)
{
  const Velo::HitBase h0 {hit_Xs[track.hits[0]], hit_Ys[track.hits[0]], hit_Zs[track.hits[0]]};
  const Velo::HitBase h1 {hit_Xs[track.hits[1]], hit_Ys[track.hits[1]], hit_Zs[track.hits[1]]};
  const Velo::HitBase h2 {hit_Xs[track.hits[2]], hit_Ys[track.hits[2]], hit_Zs[track.hits[2]]};

  // Calculate prediction
  const auto z2_tz = (h2.z - h0.z) / (h1.z - h0.z);
  const auto x = h0.x + (h1.x - h0.x) * z2_tz;
  const auto y = h0.y + (h1.y - h0.y) * z2_tz;
  const auto dx = x - h2.x;
  const auto dy = y - h2.y;

  // Calculate scatter
  return (dx * dx) + (dy * dy);
}

__device__ void weak_tracks_adder_impl(
  uint* weaktracks_insert_pointer,
  uint* tracks_insert_pointer,
  Velo::TrackletHits* weak_tracks,
  Velo::TrackHits* tracks,
  bool* hit_used,
  const float* hit_Xs,
  const float* hit_Ys,
  const float* hit_Zs)
{
  // Compute the weak tracks
  const auto weaktracks_total = weaktracks_insert_pointer[0];
  for (uint weaktrack_no = threadIdx.x; weaktrack_no < weaktracks_total; weaktrack_no += blockDim.x) {
    const Velo::TrackletHits& t = weak_tracks[weaktrack_no];
    const bool any_used = hit_used[t.hits[0]] || hit_used[t.hits[1]] || hit_used[t.hits[2]];
    const float chi2 = means_square_fit_chi2(hit_Xs, hit_Ys, hit_Zs, t);

    // Store them in the tracks bag
    if (!any_used && chi2 < Configuration::velo_search_by_triplet_t::max_chi2) {
      const uint trackno = atomicAdd(tracks_insert_pointer, 1);
      assert(trackno < Velo::Constants::max_tracks);
      tracks[trackno] = Velo::TrackHits {t};
    }
  }
}

__global__ void velo_weak_tracks_adder(
  uint32_t* dev_velo_cluster_container,
  uint* dev_module_cluster_start,
  Velo::TrackHits* dev_tracks,
  Velo::TrackletHits* dev_weak_tracks,
  bool* dev_hit_used,
  uint* dev_atomics_velo)
{
  /* Data initialization */
  // Each event is treated with two blocks, one for each side.
  const uint event_number = blockIdx.x;
  const uint number_of_events = gridDim.x;
  const uint tracks_offset = event_number * Velo::Constants::max_tracks;

  // Pointers to data within the event
  const uint number_of_hits = dev_module_cluster_start[Velo::Constants::n_modules * number_of_events];
  const uint* module_hitStarts = dev_module_cluster_start + event_number * Velo::Constants::n_modules;
  const uint hit_offset = module_hitStarts[0];
  assert((module_hitStarts[52] - module_hitStarts[0]) < Velo::Constants::max_number_of_hits_per_event);

  // Order has changed since SortByPhi
  const float* hit_Ys = (float*) (dev_velo_cluster_container + hit_offset);
  const float* hit_Zs = (float*) (dev_velo_cluster_container + number_of_hits + hit_offset);
  const float* hit_Xs = (float*) (dev_velo_cluster_container + 5 * number_of_hits + hit_offset);

  // Per event datatypes
  Velo::TrackHits* tracks = dev_tracks + tracks_offset;
  uint* tracks_insert_pointer = (uint*) dev_atomics_velo + event_number;

  // Per side datatypes
  bool* hit_used = dev_hit_used + hit_offset;
  Velo::TrackletHits* weak_tracks =
    dev_weak_tracks + event_number * Configuration::velo_search_by_triplet_t::max_weak_tracks;

  // Initialize variables according to event number and module side
  // Insert pointers (atomics)
  const int ip_shift = number_of_events + event_number * (Velo::num_atomics - 1);
  uint* weaktracks_insert_pointer = (uint*) dev_atomics_velo + ip_shift;

  weak_tracks_adder_impl(
    weaktracks_insert_pointer, tracks_insert_pointer, weak_tracks, tracks, hit_used, hit_Xs, hit_Ys, hit_Zs);
}

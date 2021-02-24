/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ThreeHitTracksFilter.cuh"
#include "VeloTools.cuh"

void velo_three_hit_tracks_filter::velo_three_hit_tracks_filter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_number_of_three_hit_tracks_output_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_three_hit_tracks_output_t>(
    arguments, first<host_number_of_events_t>(arguments) * Velo::Constants::max_tracks);
}

void velo_three_hit_tracks_filter::velo_three_hit_tracks_filter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_number_of_three_hit_tracks_output_t>(arguments, 0, context);

  global_function(velo_three_hit_tracks_filter)(size<dev_event_list_t>(arguments), property<block_dim_t>(), context)(
    arguments);

  if (property<verbosity_t>() >= logger::debug) {
    info_cout << "VELO three hit tracks found:\n";
    print_velo_three_hit_tracks<dev_three_hit_tracks_output_t, dev_number_of_three_hit_tracks_output_t>(arguments);
  }
}

/**
 * @brief Calculates the parameters according to a root means square fit
 *        and returns the chi2.
 */
__device__ float means_square_fit_chi2(Velo::ConstClusters& velo_cluster_container, const Velo::TrackletHits& track)
{
  // Fit parameters
  float s0, sx, sz, sxz, sz2;
  float u0, uy, uz, uyz, uz2;
  s0 = sx = sz = sxz = sz2 = 0.0f;
  u0 = uy = uz = uyz = uz2 = 0.0f;

  // Iterate over hits
  for (unsigned h = 0; h < 3; ++h) {
    const auto hit_number = track.hits[h];
    const float x = velo_cluster_container.x(hit_number);
    const float y = velo_cluster_container.y(hit_number);
    const float z = velo_cluster_container.z(hit_number);

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

  // Calculate tx and ty
  const auto dens = 1.0f / (sz2 * s0 - sz * sz);
  const auto state_tx = (sxz * s0 - sx * sz) * dens;
  const auto state_x = (sx * sz2 - sxz * sz) * dens;

  const auto denu = 1.0f / (uz2 * u0 - uz * uz);
  const auto state_ty = (uyz * u0 - uy * uz) * denu;
  const auto state_y = (uy * uz2 - uyz * uz) * denu;

  // Chi2 / degrees-of-freedom of straight-line fit
  float chi2 = 0.0f;
  for (unsigned h = 0; h < 3; ++h) {
    const auto hit_number = track.hits[h];

    const float z = velo_cluster_container.z(hit_number);
    const float x = state_x + state_tx * z;
    const float y = state_y + state_ty * z;

    const float dx = x - velo_cluster_container.x(hit_number);
    const float dy = y - velo_cluster_container.y(hit_number);

    chi2 += dx * dx * Velo::Tracking::param_w + dy * dy * Velo::Tracking::param_w;
  }

  return chi2 * 0.5f;
}

__device__ void three_hit_tracks_filter_impl(
  const Velo::TrackletHits* input_tracks,
  const unsigned number_of_input_tracks,
  Velo::TrackletHits* output_tracks,
  unsigned* number_of_output_tracks,
  const bool* hit_used,
  Velo::ConstClusters& velo_cluster_container,
  const float max_chi2)
{

  for (unsigned track_number = threadIdx.x; track_number < number_of_input_tracks; track_number += blockDim.x) {
    const Velo::TrackletHits& t = input_tracks[track_number];
    const bool any_used = hit_used[t.hits[0]] || hit_used[t.hits[1]] || hit_used[t.hits[2]];
    const float chi2 = means_square_fit_chi2(velo_cluster_container, t);

    // Store them in the tracks container
    if (!any_used && chi2 < max_chi2) {
      const unsigned track_insert_number = atomicAdd(number_of_output_tracks, 1);
      assert(track_insert_number < Velo::Constants::max_tracks);
      output_tracks[track_insert_number] = t;
    }
  }
}

__global__ void velo_three_hit_tracks_filter::velo_three_hit_tracks_filter(
  velo_three_hit_tracks_filter::Parameters parameters)
{
  // Data initialization
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned tracks_offset = event_number * Velo::Constants::max_tracks;

  // Pointers to data within the event
  const unsigned total_estimated_number_of_clusters =
    parameters.dev_offsets_estimated_input_size[Velo::Constants::n_module_pairs * number_of_events];
  const unsigned* module_hitStarts =
    parameters.dev_offsets_estimated_input_size + event_number * Velo::Constants::n_module_pairs;
  const unsigned hit_offset = module_hitStarts[0];
  const bool* hit_used = parameters.dev_hit_used + hit_offset;

  // Offseted VELO cluster container
  const auto velo_cluster_container =
    Velo::ConstClusters {parameters.dev_sorted_velo_cluster_container, total_estimated_number_of_clusters, hit_offset};

  // Input three hit tracks
  const Velo::TrackletHits* input_tracks =
    parameters.dev_three_hit_tracks_input + event_number * Velo::Constants::max_three_hit_tracks;
  const auto number_of_input_tracks =
    parameters.dev_atomics_velo[event_number * Velo::num_atomics + Velo::Tracking::atomics::number_of_three_hit_tracks];

  // Output containers
  Velo::TrackletHits* output_tracks = parameters.dev_three_hit_tracks_output.get() + tracks_offset;
  unsigned* number_of_output_tracks = parameters.dev_number_of_three_hit_tracks_output.get() + event_number;

  three_hit_tracks_filter_impl(
    input_tracks,
    number_of_input_tracks,
    output_tracks,
    number_of_output_tracks,
    hit_used,
    velo_cluster_container,
    parameters.max_chi2);
}

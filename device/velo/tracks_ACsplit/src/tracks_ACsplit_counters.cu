/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "tracks_ACsplit_counters.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(tracks_ACsplit_counters::tracks_ACsplit_counters_t)

void tracks_ACsplit_counters::tracks_ACsplit_counters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_offsets_velo_tracks_A_side_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_number_of_reconstructed_velo_tracks_A_side_t>(arguments, 1);
  set_size<dev_offsets_velo_tracks_C_side_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_number_of_reconstructed_velo_tracks_C_side_t>(arguments, 1);
  set_size<dev_offsets_number_of_three_hit_tracks_filtered_A_side_t>(
    arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_number_of_three_hit_tracks_filtered_A_side_t>(arguments, 1);
  set_size<dev_offsets_number_of_three_hit_tracks_filtered_C_side_t>(
    arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_number_of_three_hit_tracks_filtered_C_side_t>(arguments, 1);
}

void tracks_ACsplit_counters::tracks_ACsplit_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_offsets_velo_tracks_A_side_t>(arguments, 0, context);
  Allen::memset_async<dev_offsets_velo_tracks_C_side_t>(arguments, 0, context);
  Allen::memset_async<dev_offsets_number_of_three_hit_tracks_filtered_A_side_t>(arguments, 0, context);
  Allen::memset_async<dev_offsets_number_of_three_hit_tracks_filtered_C_side_t>(arguments, 0, context);

  global_function(tracks_ACsplit_counters)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, splitting_algorithm.value() == "A/C split");

  PrefixSum::prefix_sum<dev_offsets_velo_tracks_A_side_t, host_number_of_reconstructed_velo_tracks_A_side_t>(
    *this, arguments, context);

  PrefixSum::prefix_sum<dev_offsets_velo_tracks_C_side_t, host_number_of_reconstructed_velo_tracks_C_side_t>(
    *this, arguments, context);

  PrefixSum::prefix_sum<
    dev_offsets_number_of_three_hit_tracks_filtered_A_side_t,
    host_number_of_three_hit_tracks_filtered_A_side_t>(*this, arguments, context);

  PrefixSum::prefix_sum<
    dev_offsets_number_of_three_hit_tracks_filtered_C_side_t,
    host_number_of_three_hit_tracks_filtered_C_side_t>(*this, arguments, context);
}

__global__ void tracks_ACsplit_counters::tracks_ACsplit_counters(
  tracks_ACsplit_counters::Parameters parameters,
  const bool AC_split)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const auto tracks_offset = Velo::track_offset(parameters.dev_offsets_estimated_input_size, event_number);
  auto tracks = parameters.dev_tracks + tracks_offset;
  auto tracks_3_hit = parameters.dev_three_hit_tracks_output + tracks_offset;

  auto number_of_three_hit_tracks_filtered_A_side =
    parameters.dev_offsets_number_of_three_hit_tracks_filtered_A_side + event_number;
  auto number_of_three_hit_tracks_filtered_C_side =
    parameters.dev_offsets_number_of_three_hit_tracks_filtered_C_side + event_number;

  auto number_of_velo_tracks_A_side = parameters.dev_offsets_velo_tracks_A_side + event_number;
  auto number_of_velo_tracks_C_side = parameters.dev_offsets_velo_tracks_C_side + event_number;

  const auto event_number_of_three_hit_tracks_filtered =
    parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number + 1] -
    parameters.dev_offsets_number_of_three_hit_tracks_filtered[event_number];

  const auto event_total_number_of_tracks =
    parameters.dev_offsets_all_velo_tracks[event_number + 1] - parameters.dev_offsets_all_velo_tracks[event_number];

  const auto event_number_of_tracks_in_main_track_container =
    event_total_number_of_tracks - event_number_of_three_hit_tracks_filtered;

  const unsigned total_estimated_number_of_clusters =
    parameters.dev_offsets_estimated_input_size[Velo::Constants::n_module_pairs * number_of_events];

  const unsigned* module_hitStarts =
    parameters.dev_offsets_estimated_input_size + event_number * Velo::Constants::n_module_pairs;
  const unsigned hit_offset = module_hitStarts[0];

  const auto velo_cluster_container =
    Velo::ConstClusters {parameters.dev_sorted_velo_cluster_container, total_estimated_number_of_clusters, hit_offset};

  for (unsigned i = threadIdx.x; i < event_total_number_of_tracks; i += blockDim.x) {
    __syncthreads();
    unsigned selection;
    if (i < event_number_of_tracks_in_main_track_container) {
      if (AC_split == true) {
        selection = velo_track_in_A_side(velo_cluster_container, tracks[i]);
      }
      else {
        selection = random_selection(velo_cluster_container, tracks[i]);
      }

      if (selection == 1) {
        atomicAdd(number_of_velo_tracks_A_side, 1);
      }
      else {
        if (selection == 2) continue;
        atomicAdd(number_of_velo_tracks_C_side, 1);
      }
    }
    else {
      if (AC_split == true) {
        selection = velo_track_in_A_side(
          velo_cluster_container, tracks_3_hit[i - event_number_of_tracks_in_main_track_container]);
      }
      else {
        selection =
          random_selection(velo_cluster_container, tracks_3_hit[i - event_number_of_tracks_in_main_track_container]);
      }

      if (selection == 1) {
        atomicAdd(number_of_velo_tracks_A_side, 1);
        atomicAdd(number_of_three_hit_tracks_filtered_A_side, 1);
      }
      else {
        if (selection == 2) continue;
        atomicAdd(number_of_velo_tracks_C_side, 1);
        atomicAdd(number_of_three_hit_tracks_filtered_C_side, 1);
      }
    }
  }
}
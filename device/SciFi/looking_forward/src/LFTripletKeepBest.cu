/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "LFCreateTracks.cuh"
#include "OddevenMergeSort.cuh"
#include "WarpIntrinsicsTools.cuh"

template<bool with_ut, typename T>
__device__ void triplet_keep_best(
  lf_create_tracks::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants,
  const T* tracks)
{
  const unsigned max_triplets_per_input_track = parameters.max_triplets_per_input_track;
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned maximum_number_of_triplets_per_warp = parameters.maximum_number_of_triplets_per_warp;

  const auto n_seeds = with_ut ? LookingForward::InputUT::n_seeds : LookingForward::InputVelo::n_seeds;

  DYNAMIC_SHARED_MEMORY_BUFFER(unsigned, shared_memory, parameters.config)
  unsigned* shared_warp_store = shared_memory + threadIdx.y * maximum_number_of_triplets_per_warp * n_seeds;

  const unsigned number_of_elements_initial_window = with_ut ?
                                                       LookingForward::InputUT::number_of_elements_initial_window :
                                                       LookingForward::InputVelo::number_of_elements_initial_window;

  const auto input_tracks_view = tracks->container(event_number);

  const int event_tracks_offset = input_tracks_view.offset();
  // TODO: Don't do this. Will be replaced when SciFi EM is updated.
  const unsigned total_number_of_tracks =
    tracks->container(number_of_events - 1).offset() + tracks->container(number_of_events - 1).size();

  const auto n_tracks_side_0 = parameters.dev_scifi_lf_number_of_tracks[event_number];
  const auto n_tracks_side_1 = parameters.dev_scifi_lf_number_of_tracks[number_of_events + event_number];
  for (unsigned i_number_of_track = threadIdx.y; i_number_of_track < n_tracks_side_0 + n_tracks_side_1;
       i_number_of_track += blockDim.y) {
    const auto track_index = [&]() {
      if (i_number_of_track < n_tracks_side_0) {
        return parameters.dev_scifi_lf_tracks_indices[event_tracks_offset + i_number_of_track];
      }
      return parameters.dev_scifi_lf_tracks_indices
        [total_number_of_tracks + event_tracks_offset + i_number_of_track - n_tracks_side_0];
    }();

    const auto current_input_track_index = event_tracks_offset + track_index;

    const auto* track_scifi_lf_found_triplets =
      parameters.dev_scifi_lf_found_triplets +
      current_input_track_index * maximum_number_of_triplets_per_warp * n_seeds;

    const auto number_of_tracks_found = parameters.dev_scifi_lf_number_of_found_triplets[current_input_track_index];
    for (unsigned i = threadIdx.x; i < number_of_tracks_found; i += blockDim.x) {
      shared_warp_store[i] = track_scifi_lf_found_triplets[i];
    }

    if (number_of_tracks_found == 0) {
      continue;
    }

    // If the number of tracks is more than the max allowed, sort
    if (number_of_tracks_found > max_triplets_per_input_track) {
      oddeven_merge_sort<false>(shared_warp_store, number_of_tracks_found);
    }

    const auto number_of_tracks_to_store =
      number_of_tracks_found > max_triplets_per_input_track ? max_triplets_per_input_track : number_of_tracks_found;

    const auto base_insert_index =
      Allen::warp::atomic_add(parameters.dev_scifi_lf_atomics + event_number, number_of_tracks_to_store);

    // Save best triplet candidates as TrackHits candidates for further extrapolation
    for (unsigned i = threadIdx.x; i < number_of_tracks_to_store; i += blockDim.x) {
      const SciFi::lf_triplet t = shared_warp_store[i];

      // Create triplet candidate with all information we have
      const int current_insert_index = base_insert_index + i;
      const auto layer_0 = dev_looking_forward_constants->triplet_seeding_layers[t.triplet_seed][0];
      const auto layer_1 = dev_looking_forward_constants->triplet_seeding_layers[t.triplet_seed][1];
      const auto layer_2 = dev_looking_forward_constants->triplet_seeding_layers[t.triplet_seed][2];

      // Offsets to h0, h1 and h2
      const int* initial_windows = parameters.dev_scifi_lf_initial_windows + current_input_track_index;

      const int l0_start =
        initial_windows[(layer_0 * number_of_elements_initial_window + t.left_right_side * 2) * total_number_of_tracks];
      const int l1_start =
        initial_windows[(layer_1 * number_of_elements_initial_window + t.left_right_side * 2) * total_number_of_tracks];
      const int l2_start =
        initial_windows[(layer_2 * number_of_elements_initial_window + t.left_right_side * 2) * total_number_of_tracks];

      const auto h0 = l0_start + t.h0_rel;
      const auto h1 = l1_start + t.h1_rel;
      const auto h2 = l2_start + t.h2_rel;

      parameters.dev_scifi_lf_tracks[event_tracks_offset * max_triplets_per_input_track + current_insert_index] =
        SciFi::TrackHits {static_cast<uint16_t>(h0),
                          static_cast<uint16_t>(h1),
                          static_cast<uint16_t>(h2),
                          static_cast<uint16_t>(layer_0),
                          static_cast<uint16_t>(layer_1),
                          static_cast<uint16_t>(layer_2),
                          0.f,
                          0.f,
                          static_cast<uint16_t>(track_index),
                          static_cast<uint16_t>(t.left_right_side)};
    }
  }
}

__global__ void lf_create_tracks::lf_triplet_keep_best(
  lf_create_tracks::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  const auto* ut_tracks =
    Allen::dyn_cast<const Allen::Views::UT::Consolidated::MultiEventTracks*>(*parameters.dev_tracks_view);
  if (ut_tracks) {
    triplet_keep_best<true>(parameters, dev_looking_forward_constants, ut_tracks);
  }
  else {
    const auto* velo_tracks =
      static_cast<const Allen::Views::Velo::Consolidated::MultiEventTracks*>(*parameters.dev_tracks_view);
    triplet_keep_best<false>(parameters, dev_looking_forward_constants, velo_tracks);
  }
}

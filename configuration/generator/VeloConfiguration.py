from algorithms import *

# Sequence
def VELO_sequence():
  host_global_event_cut = host_global_event_cut_t()

  velo_estimate_input_size = velo_estimate_input_size_t()

  prefix_sum_0 = host_prefix_sum_t("prefix_sum_0",
    HostOutput("host_total_number_of_velo_clusters_t", "uint"),
    velo_estimate_input_size.dev_estimated_input_size_t(),
    DeviceOutput("dev_offsets_estimated_input_size_t", "uint"))

  velo_masked_clustering = velo_masked_clustering_t()

  velo_calculate_phi_and_sort = velo_calculate_phi_and_sort_t()

  velo_fill_candidates = velo_fill_candidates_t()

  velo_search_by_triplet = velo_search_by_triplet_t()

  prefix_sum_1 = host_prefix_sum_t("prefix_sum_1",
    HostOutput("host_number_of_reconstructed_velo_tracks_t", "uint"),
    velo_search_by_triplet.dev_number_of_velo_tracks_t(),
    DeviceOutput("dev_offsets_velo_tracks_t", "uint"))

  velo_three_hit_tracks_filter = velo_three_hit_tracks_filter_t(
    dev_three_hit_tracks_input_t=velo_search_by_triplet.dev_three_hit_tracks_t())

  prefix_sum_2 = host_prefix_sum_t("prefix_sum_2",
    HostOutput("host_number_of_three_hit_tracks_filtered_t", "uint"),
    velo_three_hit_tracks_filter.dev_number_of_three_hit_tracks_output_t(),
    DeviceOutput("dev_offsets_number_of_three_hit_tracks_filtered_t", "uint"))

  velo_copy_track_hit_number = velo_copy_track_hit_number_t()

  prefix_sum_3 = host_prefix_sum_t("prefix_sum_3",
    HostOutput("host_accumulated_number_of_hits_in_velo_tracks_t", "uint"),
    velo_copy_track_hit_number.dev_velo_track_hit_number_t(),
    DeviceOutput("dev_offsets_velo_track_hit_number_t", "uint"))

  velo_consolidate_tracks = velo_consolidate_tracks_t()

  s = Sequence(host_global_event_cut,
    velo_estimate_input_size,
    prefix_sum_0,
    velo_masked_clustering,
    velo_calculate_phi_and_sort,
    velo_fill_candidates,
    velo_search_by_triplet,
    prefix_sum_1,
    velo_three_hit_tracks_filter,
    prefix_sum_2,
    velo_copy_track_hit_number,
    prefix_sum_3,
    velo_consolidate_tracks)

  s.validate()

  return s

from algorithms import *
from PVSequence import PV_sequence

def UT_sequence():
  ut_calculate_number_of_hits = ut_calculate_number_of_hits_t()
  
  prefix_sum_ut_hits = host_prefix_sum_t("prefix_sum_ut_hits",
    host_total_sum_holder_t="host_accumulated_number_of_ut_hits_t",
    dev_input_buffer_t=ut_calculate_number_of_hits.dev_ut_hit_sizes_t(),
    dev_output_buffer_t="dev_ut_hit_offsets_t")

  ut_pre_decode = ut_pre_decode_t()
  ut_find_permutation = ut_find_permutation_t()
  ut_decode_raw_banks_in_order = ut_decode_raw_banks_in_order_t()
  ut_search_windows = ut_search_windows_t()
  compass_ut = compass_ut_t()
  
  prefix_sum_single_block_ut = host_prefix_sum_t("prefix_sum_single_block_ut",
    host_total_sum_holder_t="host_number_of_reconstructed_ut_tracks_t",
    dev_input_buffer_t=compass_ut.dev_atomics_ut_t(),
    dev_output_buffer_t="dev_offsets_ut_tracks_t")
  
  ut_copy_track_hit_number = ut_copy_track_hit_number_t()

  prefix_sum_ut_track_hit_number = host_prefix_sum_t("prefix_sum_ut_track_hit_number",
    host_total_sum_holder_t="host_accumulated_number_of_hits_in_ut_tracks_t",
    dev_input_buffer_t=ut_copy_track_hit_number.dev_ut_track_hit_number_t(),
    dev_output_buffer_t="dev_offsets_ut_track_hit_number_t")

  ut_consolidate_tracks = ut_consolidate_tracks_t()

  s = PV_sequence()
  s.extend_sequence(
    ut_calculate_number_of_hits,
    prefix_sum_ut_hits,
    ut_pre_decode,
    ut_find_permutation,
    ut_decode_raw_banks_in_order,
    ut_search_windows,
    compass_ut,
    prefix_sum_single_block_ut,
    ut_copy_track_hit_number,
    prefix_sum_ut_track_hit_number,
    ut_consolidate_tracks)

  s.validate()

  return s

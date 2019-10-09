#pragma once

#include "Argument.cuh"

/**
 * @brief Definition of arguments. All arguments should be defined here,
 *        with their associated type.
 */
ARGUMENT(dev_velo_raw_input, char)
ARGUMENT(dev_velo_raw_input_offsets, uint)
ARGUMENT(dev_ut_raw_input, char)
ARGUMENT(dev_ut_raw_input_offsets, uint)
ARGUMENT(dev_scifi_raw_input, char)
ARGUMENT(dev_scifi_raw_input_offsets, uint)
ARGUMENT(dev_event_list, uint)
ARGUMENT(dev_number_of_selected_events, uint)
ARGUMENT(dev_velo_pv_ip, char)
ARGUMENT(dev_accepted_velo_tracks, bool)
ARGUMENT(dev_prefix_sum_auxiliary_array_2, uint)
ARGUMENT(dev_prefix_sum_auxiliary_array_3, uint)
ARGUMENT(dev_prefix_sum_auxiliary_array_4, uint)
ARGUMENT(dev_prefix_sum_auxiliary_array_5, uint)
ARGUMENT(dev_prefix_sum_auxiliary_array_6, uint)
ARGUMENT(dev_prefix_sum_auxiliary_array_7, uint)
ARGUMENT(dev_prefix_sum_auxiliary_array_8, uint)
ARGUMENT(dev_prefix_sum_auxiliary_array_9, uint)
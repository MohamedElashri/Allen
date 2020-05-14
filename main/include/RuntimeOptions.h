#pragma once

#include <vector>
#include "BankTypes.h"

// Forward declare IInputProvider to avoid including "InputProvider.h" from device code
struct IInputProvider;

/**
 * @brief Runtime options singleton.
 */
struct RuntimeOptions {
  IInputProvider const* input_provider;
  size_t const slice_index;
  std::tuple<uint, uint> event_interval;
  uint number_of_selected_events;
  uint number_of_repetitions;
  bool do_check;
  bool cpu_offload;
  bool mep_layout;

  RuntimeOptions(
    IInputProvider const* ip,
    size_t const index,
    std::tuple<uint, uint> param_event_interval,
    uint param_number_of_repetitions,
    bool param_do_check,
    bool param_cpu_offload,
    bool param_mep_layout) :
    input_provider {ip},
    slice_index {index}, event_interval(param_event_interval),
    number_of_selected_events(std::get<1>(param_event_interval) - std::get<0>(param_event_interval)),
    number_of_repetitions(param_number_of_repetitions), do_check(param_do_check),
    cpu_offload(param_cpu_offload), mep_layout {param_mep_layout}
  {}
};

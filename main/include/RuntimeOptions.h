/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
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
  std::tuple<unsigned, unsigned> event_interval;
  unsigned number_of_selected_events;
  unsigned number_of_repetitions;
  bool do_check;
  bool cpu_offload;
  bool mep_layout;
  uint inject_mem_fail;

  RuntimeOptions(
    IInputProvider const* ip,
    size_t const index,
    std::tuple<unsigned, unsigned> param_event_interval,
    unsigned param_number_of_repetitions,
    bool param_do_check,
    bool param_cpu_offload,
    bool param_mep_layout,
    uint param_inject_mem_fail) :
    input_provider {ip},
    slice_index {index}, event_interval(param_event_interval),
    number_of_selected_events(std::get<1>(param_event_interval) - std::get<0>(param_event_interval)),
    number_of_repetitions(param_number_of_repetitions), do_check(param_do_check),
    cpu_offload(param_cpu_offload), mep_layout {param_mep_layout}, inject_mem_fail {param_inject_mem_fail}
  {}
};

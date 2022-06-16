/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <vector>
#include "BankTypes.h"
#include "MCEvent.h"

// Forward declare IInputProvider to avoid including "InputProvider.h" from device code
class IInputProvider;
struct CheckerInvoker;
struct ROOTService;

/**
 * @brief Runtime options singleton.
 */
struct RuntimeOptions {
  const std::shared_ptr<IInputProvider> input_provider;
  size_t const slice_index;
  std::tuple<unsigned, unsigned> event_interval;
  unsigned number_of_selected_events;
  unsigned number_of_repetitions;
  bool cpu_offload;
  bool mep_layout;
  uint inject_mem_fail;
  const MCEvents mc_events;
  CheckerInvoker* checker_invoker;
  ROOTService* root_service;

  RuntimeOptions(
    std::shared_ptr<IInputProvider> ip,
    size_t const index,
    std::tuple<unsigned, unsigned> param_event_interval,
    unsigned param_number_of_repetitions,
    bool param_cpu_offload,
    bool param_mep_layout,
    uint param_inject_mem_fail,
    CheckerInvoker* param_checker_invoker,
    ROOTService* param_root_service) :
    input_provider {std::move(ip)},
    slice_index {index}, event_interval(param_event_interval),
    number_of_selected_events(std::get<1>(param_event_interval) - std::get<0>(param_event_interval)),
    number_of_repetitions(param_number_of_repetitions),
    cpu_offload(param_cpu_offload), mep_layout {param_mep_layout}, inject_mem_fail {param_inject_mem_fail},
    checker_invoker(param_checker_invoker), root_service(param_root_service)
  {}
};

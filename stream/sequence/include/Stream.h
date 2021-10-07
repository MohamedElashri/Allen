/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <iostream>
#include <vector>
#include <numeric>
#include <algorithm>
#include <tuple>

#include "Common.h"
#include "BackendCommon.h"
#include "Logger.h"
#include "Timer.h"
#include "Tools.h"
#include "Constants.cuh"
#include "RuntimeOptions.h"
#include "CheckerInvoker.h"
#include "Configuration.cuh"

struct HostBuffers;
struct HostBuffersManager;
class Scheduler;

struct Stream {
private:
  // Dynamic scheduler
  Scheduler* scheduler;

  // Context
  Allen::Context m_context {};

  // Launch options
  bool do_print_memory_manager;

  // Host buffers
  HostBuffersManager* host_buffers_manager;
  HostBuffers* host_buffers {0};

  // Number of input events
  unsigned number_of_input_events;

  // Constants
  Constants const& constants;

public:
  Stream(
    const ConfiguredSequence& configuration,
    const bool param_print_memory_usage,
    const size_t param_reserve_mb,
    const size_t reserve_host_mb,
    const unsigned required_memory_alignment,
    const Constants& param_constants,
    HostBuffersManager* buffers_manager);

  Allen::error run(const unsigned buf_idx, RuntimeOptions const& runtime_options);

  void configure_algorithms(const std::map<std::string, std::map<std::string, std::string>>& config);

  void print_configured_sequence();

  std::map<std::string, std::map<std::string, std::string>> get_algorithm_configuration() const;
};

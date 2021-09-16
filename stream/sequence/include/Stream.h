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
#include "VeloEventModel.cuh"
#include "UTDefinitions.cuh"
#include "RuntimeOptions.h"
#include "EstimateInputSize.cuh"
#include "HostBuffers.cuh"
#include "HostBuffersManager.cuh"
#include "SchedulerMachinery.cuh"
#include "Scheduler.cuh"
#include "CheckerInvoker.h"
#include "IStream.h"

#include "ConfiguredSequence.h"

class Timer;

struct Stream : virtual public Allen::IStream {
private:
  using scheduler_t = SchedulerFor_t<configured_sequence_t, configured_arguments_t, configured_sequence_arguments_t>;

  // Dynamic scheduler
  scheduler_t scheduler {configured_sequence_t {}, sequence_algorithm_names};

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
    const bool param_print_memory_usage,
    const size_t param_reserve_mb,
    const size_t reserve_host_mb,
    const unsigned required_memory_alignment,
    const Constants& param_constants,
    HostBuffersManager* buffers_manager);

  Allen::error run(const unsigned buf_idx, RuntimeOptions const& runtime_options) override;

  void configure_algorithms(const std::map<std::string, std::map<std::string, std::string>>& config) override
  {
    scheduler.configure_algorithms(config);
  }

  void print_configured_sequence() override;

  std::map<std::string, std::map<std::string, std::string>> get_algorithm_configuration() const override
  {
    return scheduler.get_algorithm_configuration();
  }
};

extern "C" bool contains_validator_algorithm();

extern "C" Allen::IStream* create_stream(
  const bool param_print_memory_usage,
  const size_t param_reserve_mb,
  const size_t reserve_host_mb,
  const unsigned required_memory_alignment,
  const Constants& constants,
  HostBuffersManager* buffers_manager);

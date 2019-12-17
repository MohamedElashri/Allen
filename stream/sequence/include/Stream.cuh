#pragma once

#include <iostream>
#include <vector>
#include <numeric>
#include <algorithm>
#include <tuple>

#include "Common.h"
#include "CudaCommon.h"
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
#include "SequenceVisitor.cuh"
#include "SchedulerMachinery.cuh"
#include "Scheduler.cuh"
#include "OutputArguments.cuh"
#include "CheckerInvoker.h"
#include "OutputHandler.h"
#include "ConfiguredSequence.cuh"

class Timer;

struct Stream {
  using scheduler_t = Scheduler<configured_sequence_t, output_arguments_t>;
  using argument_manager_t = ArgumentManager<scheduler_t::arguments_tuple_t>;

  Stream() = default;

  // Dynamic scheduler
  scheduler_t scheduler;

  // Stream datatypes
  cudaStream_t cuda_stream;
  cudaEvent_t cuda_generic_event;
  uint stream_number;

  // Launch options
  bool do_print_memory_manager;

  // Host buffers
  HostBuffersManager const* host_buffers_manager;
  HostBuffers* host_buffers {0};

  // Start event offset
  uint start_event_offset;

  // Number of input events
  uint number_of_input_events;

  // Memory base pointers
  char* host_base_pointer;
  char* dev_base_pointer;

  // Constants
  Constants constants;

  cudaError_t initialize(
    const bool param_print_memory_usage,
    const uint param_start_event_offset,
    const size_t param_reserve_mb,
    const uint param_stream_number,
    const Constants& param_constants,
    HostBuffersManager const* buffers_manager);

  std::vector<bool> reconstructed_events() const;

  void run_monte_carlo_test(
    CheckerInvoker& invoker,
    MCEvents const& mc_events,
    std::vector<Checker::Tracks> const& forward_tracks);

  cudaError_t run_sequence(const uint buf_idx, RuntimeOptions const& runtime_options);

  void configure_algorithms(const std::map<std::string, std::map<std::string, std::string>>& config)
  {
    scheduler.configure_algorithms(config);
  }

  auto get_algorithm_configuration() { return scheduler.get_algorithm_configuration(); }
};

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
#include "CheckerInvoker.h"
#include "ConfiguredSequence.h"

class Timer;

struct Stream {
  using scheduler_t = Scheduler<configured_sequence_t, configured_arguments_t, configured_sequence_arguments_t>;

  Stream() = default;
   
  // Dynamic scheduler
  scheduler_t scheduler;

  // Stream datatypes
  cudaStream_t cuda_stream;
  cudaEvent_t cuda_generic_event;
  
  // Launch options
  bool do_print_memory_manager;

  // Host buffers
  HostBuffersManager* host_buffers_manager;
  HostBuffers* host_buffers {0};

  // Start event offset
  unsigned start_event_offset;

  // Number of input events
  unsigned number_of_input_events;

  // Memory base pointers for host and device
  char* host_base_pointer;
  char* dev_base_pointer;

  // Constants
  Constants constants;

  cudaError_t initialize(
    const bool param_print_memory_usage,
    const unsigned param_start_event_offset,
    const size_t param_reserve_mb,
    const Constants& param_constants);

  void set_host_buffer_manager(HostBuffersManager* buffers_manager);
  
  std::vector<bool> reconstructed_events() const;

  void run_monte_carlo_test(
    CheckerInvoker& invoker,
    MCEvents const& mc_events,
    std::vector<Checker::Tracks> const& forward_tracks);

  cudaError_t run_sequence(const unsigned buf_idx, RuntimeOptions const& runtime_options);

  void configure_algorithms(const std::map<std::string, std::map<std::string, std::string>>& config)
  {
    scheduler.configure_algorithms(config);
  }

  auto get_algorithm_configuration() { return scheduler.get_algorithm_configuration(); }
};

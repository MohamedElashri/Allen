/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <memory>

#include "Stream.h"
#include "AlgorithmTypes.cuh"
#include "Scheduler.cuh"
#include "HostBuffers.cuh"
#include "HostBuffersManager.cuh"

#ifdef CALLGRIND_PROFILE
#include <valgrind/callgrind.h>
#endif

/**
 * @brief Sets up the chain that will be executed later.
 */
Stream::Stream(
  const ConfiguredSequence& configuration,
  const bool param_do_print_memory_manager,
  const size_t reserve_mb,
  const size_t reserve_host_mb,
  const unsigned required_memory_alignment,
  const Constants& param_constants,
  HostBuffersManager* buffers_manager) :
  do_print_memory_manager {param_do_print_memory_manager},
  host_buffers_manager {buffers_manager}, constants {param_constants}
{
  scheduler =
    new Scheduler {configuration, do_print_memory_manager, reserve_mb, reserve_host_mb, required_memory_alignment};

  // Initialize context
  m_context.initialize();
}

Allen::error Stream::run(const unsigned buf_idx, const RuntimeOptions& runtime_options)
{
#ifdef CALLGRIND_PROFILE
  CALLGRIND_START_INSTRUMENTATION;
#endif

  host_buffers = host_buffers_manager->getBuffers(buf_idx);
  // The sequence is only run if there are events to run on
  auto event_start = std::get<0>(runtime_options.event_interval);
  auto event_end = std::get<1>(runtime_options.event_interval);

  number_of_input_events = event_end - event_start;
  if (event_end > event_start) {
    for (unsigned repetition = 0; repetition < runtime_options.number_of_repetitions; ++repetition) {
      // Initialize selected_number_of_events with requested_number_of_events
      host_buffers->host_number_of_events = event_end - event_start;

      // Reset scheduler
      scheduler->reset();

      try {
        // Visit all algorithms in configured sequence
        scheduler->run(runtime_options, constants, host_buffers, m_context);

        // deterministic injection of ~random memory failures
        if (runtime_options.inject_mem_fail > 0) {
          // compare the least significant N bits of two ~unrelated buffers
          // test should fire one time in 2^N slices on average
          // limit ourselves to a maximum of 15-bit comparison (1/2 - ~1/32k of slices)
          uint test_mask = (1 << 15) - 1;
          if (runtime_options.inject_mem_fail < 15) test_mask = (1 << runtime_options.inject_mem_fail) - 1;
          if (
            (host_buffers->host_number_of_selected_events & test_mask) ==
            (host_buffers->host_passing_event_list[0] & test_mask))
            throw MemoryException("Test : Injected fake memory exception to test failure handling");
        }

        // Synchronize device
        Allen::synchronize(m_context);
      } catch (const MemoryException& e) {
        warning_cout << "Insufficient memory to process slice - will sub-divide and retry." << std::endl;
        return Allen::error::errorMemoryAllocation;
      }
    }
  }

#ifdef CALLGRIND_PROFILE
  CALLGRIND_STOP_INSTRUMENTATION;
  CALLGRIND_DUMP_STATS;
#endif

  return Allen::error::success;
}

/**
 * @brief Print the type and name of the algorithms in the sequence
 */
void Stream::print_configured_sequence() { scheduler->print_sequence(); }

void Stream::configure_algorithms(const std::map<std::string, std::map<std::string, nlohmann::json>>& config)
{
  scheduler->configure_algorithms(config);
}

std::map<std::string, std::map<std::string, nlohmann::json>> Stream::get_algorithm_configuration() const
{
  return scheduler->get_algorithm_configuration();
}

bool Stream::contains_validation_algorithms() const { return scheduler->contains_validation_algorithms(); }
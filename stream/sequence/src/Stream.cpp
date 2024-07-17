/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <memory>

#include "Stream.h"
#include "AlgorithmTypes.cuh"
#include "Scheduler.cuh"
#include "HostBuffersManager.cuh"
#include "AllenMonitoring.h"

#ifdef CALLGRIND_PROFILE
#include <valgrind/callgrind.h>
#endif

/**
 * @brief Sets up the chain that will be executed later.
 */
Stream::Stream(
  const unsigned stream_id,
  const ConfiguredSequence& configuration,
  const Allen::ScheduledSequence& sched_seq,
  const bool param_do_print_memory_manager,
  const size_t reserve_mb,
  const unsigned required_memory_alignment,
  const Constants& param_constants,
  HostBuffersManager* buffers_manager) :
  stream_id {stream_id},
  do_print_memory_manager {param_do_print_memory_manager}, host_buffers_manager {buffers_manager}, constants {
                                                                                                     param_constants}
{
  scheduler = new Scheduler {configuration, sched_seq, do_print_memory_manager, reserve_mb, required_memory_alignment};

  // Initialize context
  m_context.initialize(stream_id);
}

Allen::error Stream::run(const unsigned buf_idx, const RuntimeOptions& runtime_options)
{
#ifdef CALLGRIND_PROFILE
  CALLGRIND_START_INSTRUMENTATION;
#endif

  auto persistent_store = host_buffers_manager->get_persistent_store(buf_idx);

  // The sequence is only run if there are events to run on
  auto event_start = std::get<0>(runtime_options.event_interval);
  auto event_end = std::get<1>(runtime_options.event_interval);

  number_of_input_events = event_end - event_start;
  if (event_end > event_start) {
    for (unsigned repetition = 0; repetition < runtime_options.number_of_repetitions; ++repetition) {
      // Free memory
      scheduler->free_all();
      persistent_store->free_all();

      try {
        Allen::Monitoring::AccumulatorManager::get()->synchronizeStream(stream_id);
        // Visit all algorithms in configured sequence
        scheduler->run(runtime_options, constants, persistent_store, m_context);

        // Synchronize device
        Allen::synchronize(m_context);
        Allen::Monitoring::AccumulatorManager::get()->streamDone(stream_id);
      } catch (const MemoryException& e) {
        Allen::Monitoring::AccumulatorManager::get()->streamDone(stream_id);
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

std::map<std::string, std::map<std::string, nlohmann::json>> Stream::get_algorithm_configuration() const
{
  return scheduler->get_algorithm_configuration();
}

bool Stream::contains_validation_algorithms() const { return scheduler->contains_validation_algorithms(); }

/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <vector>
#include <string>
#include <stdint.h>

#include "UTDefinitions.cuh"
#include "UTMagnetToolDefinitions.h"
#include "SciFiDefinitions.cuh"
#include "Logger.h"
#include "Common.h"
#include "Constants.cuh"
#include "RuntimeOptions.h"
#include "CheckerTypes.h"
#include "CheckerInvoker.h"
#include "HostBuffersManager.cuh"

// Forward definition of Stream, to avoid
// inability to compile kernel calls (due to <<< >>>
// operators) from main.cpp
struct Stream;

struct StreamWrapper {
  // Note: We need Stream* here due to the compiler
  //       needing to know the size of the allocated object
  std::vector<Stream*> streams;
  bool do_check;
  unsigned number_of_hlt1_lines;
  unsigned errorevent_line;

  StreamWrapper();

  ~StreamWrapper();

  /**
   * @brief Initializes n streams
   */
  void initialize_streams(
    const unsigned n,
    const bool print_memory_usage,
    const unsigned start_event_offset,
    const size_t reserve_mb,
    const size_t reserve_host_mb,
    const Constants& constants,
    const std::map<std::string, std::map<std::string, std::string>>& config);

  /**
   * @brief Runs stream.
   */
  cudaError_t run_stream(const unsigned i, const unsigned buf_idx, const RuntimeOptions& runtime_options);

  /**
   * @brief Mask of the events selected by the stream
   */
  std::vector<bool> reconstructed_events(const unsigned i) const;

  /**
   * @brief Initializes the host buffers managers of all streams.
   */
  void initialize_streams_host_buffers_manager(HostBuffersManager* buffers_manager);

  /**
   * @brief Runs Monte Carlo test. Stream must be run beforehand.
   */
  void run_monte_carlo_test(
    unsigned const i,
    CheckerInvoker& invoker,
    MCEvents const& mc_events,
    std::vector<Checker::Tracks> const& forward_tracks);

  std::map<std::string, std::map<std::string, std::string>> get_algorithm_configuration();
};


/**
 * @brief Prints the configured sequence.
 *        Must be compiled by nvcc.
 */
void print_configured_sequence();

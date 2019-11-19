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
//
// Note: main.cu wouldn't work due to nvcc not
//       supporting properly tbb (or the other way around).
struct Stream;

struct StreamWrapper {
  // Note: We need Stream* here due to the compiler
  //       needing to know the size of the allocated object
  std::vector<Stream*> streams;

  StreamWrapper() = default;

  ~StreamWrapper();

  /**
   * @brief Initializes n streams
   */
  void initialize_streams(
    const uint n,
    const bool print_memory_usage,
    const uint start_event_offset,
    const size_t reserve_mb,
    const Constants& constants,
    HostBuffersManager const * buffers_manager,
    const std::map<std::string, std::map<std::string, std::string>>& config);

  /**
   * @brief Runs stream.
   */
  void run_stream(const uint i, const uint buf_idx, const RuntimeOptions& runtime_options);

  /**
   * @brief Mask of the events selected by the stream
   */
  std::vector<bool> reconstructed_events(const uint i) const;

  /**
   * @brief Runs Monte Carlo test. Stream must be run beforehand.
   */
  void run_monte_carlo_test(
    uint const i,
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

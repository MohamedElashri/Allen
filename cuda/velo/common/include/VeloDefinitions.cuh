#pragma once

#include <cstdint>
#include <cstdlib>
#include <CudaCommon.h>

namespace Velo {
  // Total number of atomics required
  static constexpr uint num_atomics = 4;

  namespace Constants {

    // Detector constants
    static constexpr uint n_modules = 52;
    static constexpr uint n_sensors_per_module = 4;
    static constexpr uint n_sensors = n_modules * n_sensors_per_module;
    static constexpr float z_endVelo = 770; // FIXME_GEOMETRY_HARDCODING

    // Constant for maximum number of hits in a module
    static constexpr uint max_numhits_in_module = 1024;

    // High number of hits per event
    static constexpr uint max_number_of_hits_per_event = 9500;

    // Constants for requested storage on device
    static constexpr uint max_tracks = 1200;
    static constexpr uint max_track_size = 26;

    static constexpr uint32_t number_of_sensor_columns = 768; // FIXME_GEOMETRY_HARDCODING
    static constexpr uint32_t ltg_size = 16 * number_of_sensor_columns;
    static constexpr float pixel_size = 0.055f; // FIXME_GEOMETRY_HARDCODING
  }                                             // namespace Constants

  namespace Tracking {
    // Constants for filters
    static constexpr float param_w = 3966.94f;
    static constexpr float param_w_inverted = 0.000252083f;
    static constexpr int number_of_h0_candidates = 5;
    static constexpr int number_of_h2_candidates = 5;
    // Atomics
    namespace atomics {
      enum atomic_types {
        number_of_three_hit_tracks,
        number_of_seeds,
        tracks_to_follow,
        local_number_of_hits
      };
    }
    // Bits
    namespace bits {
      static constexpr uint seed = 0x80000000;
      static constexpr uint track_number = 0x0FFFFFFF;
      static constexpr uint hit_number = 0x7FFF;
      static constexpr uint skipped_modules = 0x70000000;
      static constexpr uint oddity_position = 15;
      static constexpr uint skipped_module_position = 28;
    }
    // Shared memory
    namespace shared {
      static constexpr uint previous_module_pair = 0;
      static constexpr uint current_module_pair = 2;
      static constexpr uint next_module_pair = 4;
    }
  } // namespace Tracking
} // namespace Velo

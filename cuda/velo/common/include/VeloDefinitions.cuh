#pragma once

#include <cstdint>
#include <cstdlib>
#include <CudaCommon.h>

namespace Configuration {
  namespace velo_search_by_triplet_t {
    // Forward tolerance in phi
    extern __constant__ float forward_phi_tolerance;

    // Max chi2
    extern __constant__ float max_chi2;

    // Max scatter for forming triplets (seeding) and forwarding
    extern __constant__ float max_scatter_forwarding;
    extern __constant__ float max_scatter_seeding;

    // Maximum number of skipped modules allowed for a track
    // before storing it
    extern __constant__ uint max_skipped_modules;

    // Maximum number of tracks to follow at a time
    extern __constant__ uint max_weak_tracks;

    // These parameters impact the found tracks
    // Maximum / minimum acceptable phi
    // These two parameters impacts enourmously the speed of track seeding
    extern __constant__ float phi_extrapolation_base;
    // A higher coefficient improves efficiency at the
    // cost of performance
    extern __constant__ float phi_extrapolation_coef;

    // Maximum number of tracks to follow at a time
    extern __constant__ uint ttf_modulo;
    extern __constant__ int ttf_modulo_mask;
  } // namespace velo_search_by_triplet_t
} // namespace Configuration

namespace Velo {
  // Total number of atomics required
  static constexpr uint num_atomics = 5;

  namespace Constants {

    // Detector constants
    static constexpr uint n_modules = 52;
    static constexpr uint n_sensors_per_module = 4;
    static constexpr uint n_sensors = n_modules * n_sensors_per_module;
    static constexpr float z_endVelo = 770; // FIXME_GEOMETRY_HARDCODING

    // Constant for maximum number of hits in a module
    static constexpr uint max_numhits_in_module = 500;

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

  } // namespace Tracking
} // namespace Velo

#pragma once

#include <cstdint>
#include <cstdlib>
#ifdef __APPLE__
/* Old compatibility names for C types.  */
typedef unsigned long int ulong;
typedef unsigned short int ushort;
typedef unsigned int uint;
#endif
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
    // How many concurrent h1s to process max
    // It should be a divisor of NUMTHREADS_X
    static constexpr uint max_concurrent_h1 = 16;
    static constexpr int max_concurrent_h1_mask = 0xF;
    static constexpr int max_concurrent_h1_shift = 4;

    // Number of concurrent h1s in the first iteration
    // The first iteration has no flagged hits and more triplets per hit
    static constexpr uint max_concurrent_h1_first_iteration = 8;

    // These parameters impact the found tracks
    // Maximum / minimum acceptable phi
    // These two parameters impacts enourmously the speed of track seeding
    static constexpr float phi_extrapolation_base = 0.03f;
    // A higher coefficient improves efficiency at the
    // cost of performance
    static constexpr float phi_extrapolation_coef = 0.0002f;

    // Forward tolerance in phi
    constexpr float forward_phi_tolerance = 0.052f;

    // Max scatter for forming triplets (seeding) and forwarding
    static constexpr float max_scatter_seeding = 0.1f;
    static constexpr float max_scatter_forwarding = 0.1f;

    // Maximum number of skipped modules allowed for a track
    // before storing it
    static constexpr uint max_skipped_modules = 1;

    // Maximum number of tracks to follow at a time
    static constexpr uint ttf_modulo = 2048;
    static constexpr int ttf_modulo_mask = 0x7FF;
    static constexpr uint max_weak_tracks = 500;

    // Constants for filters
    static constexpr uint states_per_track = 3;
    static constexpr float param_w = 3966.94f;
    static constexpr float param_w_inverted = 0.000252083f;

    // Max chi2
    static constexpr float max_chi2 = 20.0;

  } // namespace Tracking
} // namespace Velo

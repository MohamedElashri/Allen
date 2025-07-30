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
#pragma once

#include <cstdint>
#include <cstdlib>
#include <BackendCommon.h>

namespace Velo {
  // Total number of atomics required
  static constexpr unsigned num_atomics = 3;

  namespace Constants {
    // Detector constants
    static constexpr unsigned n_modules = 52;
    static constexpr unsigned n_module_pairs = n_modules / 2;
    static constexpr unsigned n_sensors_per_module = 4;
    static constexpr unsigned n_sensors = n_modules * n_sensors_per_module;
    static constexpr float z_endVelo = 770; // FIXME_GEOMETRY_HARDCODING

    // Constants for requested storage on device
    static constexpr unsigned max_track_size = 26;
    static constexpr unsigned max_tracks_to_follow = 2048;

    static constexpr uint32_t number_of_sensor_columns = 768; // FIXME_GEOMETRY_HARDCODING
    static constexpr uint32_t ltg_size = 16 * number_of_sensor_columns;
    static constexpr float pixel_size = 0.055f; // FIXME_GEOMETRY_HARDCODING
  }                                             // namespace Constants

  namespace Tracking {
    // Constants for filters
    static constexpr float param_w = 6400.f;
    static constexpr float param_w_inverted = 0.00015625;
    static constexpr unsigned max_h0_candidates = 8;
    static constexpr unsigned initial_seeding_h0_candidates = 8;
    static constexpr unsigned seeding_h0_candidates = 4;
    static constexpr unsigned block_dim_x_populate_module_pair_offsets_and_sizes = 256;
    // Atomics
    namespace atomics {
      enum atomic_types { number_of_three_hit_tracks, tracks_to_follow, local_number_of_hits };
    }
    // Bits
    namespace bits {
      static constexpr unsigned seed = 0x80000000;
      static constexpr unsigned track_number = 0x0FFFFFFF;
      static constexpr unsigned skipped_modules = 0x70000000;
      static constexpr unsigned skipped_module_position = 28;
    } // namespace bits
  }   // namespace Tracking
} // namespace Velo

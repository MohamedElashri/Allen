#include "MaskedVeloClustering.cuh"

// 8-connectivity mask
__device__ uint64_t make_8con_mask(uint64_t cluster) {
  return cluster | (cluster << 1) | (cluster << 15) | (cluster << 16) | (cluster << 17) | (cluster >> 1) |
         (cluster >> 15) | (cluster >> 16) | (cluster >> 17);
}

// East-most mask
__device__ uint32_t mask_east(uint64_t cluster) {
  const uint32_t mask = (cluster >> 48);
  return mask | (mask << 1) | (mask >> 1);
}

__global__ void velo_masked_clustering::velo_masked_clustering(
  velo_masked_clustering::Parameters parameters,
  const VeloGeometry* dev_velo_geometry,
  uint8_t* dev_velo_sp_patterns,
  float* dev_velo_sp_fx,
  float* dev_velo_sp_fy) {
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  const uint selected_event_number = parameters.dev_event_list[event_number];

  const char* raw_input = parameters.dev_velo_raw_input + parameters.dev_velo_raw_input_offsets[selected_event_number];
  const uint* module_cluster_start = parameters.dev_offsets_estimated_input_size + event_number * Velo::Constants::n_modules;
  uint* module_cluster_num = parameters.dev_module_cluster_num + event_number * Velo::Constants::n_modules;
  uint number_of_candidates = parameters.dev_module_candidate_num[event_number];
  uint32_t* cluster_candidates =
    (uint32_t*) &parameters.dev_cluster_candidates[event_number * VeloClustering::max_candidates_event];

  // Local pointers to parameters.dev_velo_cluster_container
  const uint total_estimated_number_of_clusters =
    parameters.dev_offsets_estimated_input_size[Velo::Constants::n_modules * number_of_events];
  auto velo_cluster_container =
    Velo::Clusters<uint> {parameters.dev_velo_cluster_container.get(), total_estimated_number_of_clusters};

  // Load Velo geometry (assume it is the same for all events)
  const VeloGeometry& g = *dev_velo_geometry;

  // Read raw event
  const auto raw_event = VeloRawEvent(raw_input);

  // process no neighbour sp
  for (uint raw_bank_number = threadIdx.x; raw_bank_number < raw_event.number_of_raw_banks;
       raw_bank_number += blockDim.x) {
    const auto module_number = raw_bank_number >> 2;
    const uint cluster_start = module_cluster_start[module_number];

    // Read raw bank
    const auto raw_bank = VeloRawBank(raw_event.payload + raw_event.raw_bank_offset[raw_bank_number]);
    const float* ltg = g.ltg + g.n_trans * raw_bank.sensor_index;

    for (uint sp_index = 0; sp_index < raw_bank.sp_count; ++sp_index) {
      // Decode sp
      const uint32_t sp_word = raw_bank.sp_word[sp_index];
      const uint32_t sp_addr = (sp_word & 0x007FFF00U) >> 8;
      const uint32_t no_sp_neighbours = sp_word & 0x80000000U;

      // There are no neighbours, so compute the number of pixels of this superpixel
      if (no_sp_neighbours) {
        // Look up pre-generated patterns
        const int32_t sp_row = sp_addr & 0x3FU;
        const int32_t sp_col = (sp_addr >> 6);
        const uint8_t sp = sp_word & 0xFFU;

        const uint32_t idx = dev_velo_sp_patterns[sp];
        const uint32_t chip = sp_col >> (VP::ChipColumns_division - 1);

        {
          // there is always at least one cluster in the super
          // pixel. look up the pattern and add it.
          const uint32_t row = idx & 0x03U;
          const uint32_t col = (idx >> 2) & 1;
          const uint32_t cx = sp_col * 2 + col;
          const uint32_t cy = sp_row * 4 + row;

          const uint cid = get_channel_id(raw_bank.sensor_index, chip, cx & VP::ChipColumns_mask, cy);

          const float fx = dev_velo_sp_fx[sp * 2];
          const float fy = dev_velo_sp_fy[sp * 2];
          const float local_x = g.local_x[cx] + fx * g.x_pitch[cx];
          const float local_y = (cy + 0.5f + fy) * Velo::Constants::pixel_size;

          const uint cluster_num = atomicAdd(module_cluster_num + module_number, 1);

#if DEBUG
          const auto module_estimated_num =
            parameters.dev_offsets_estimated_input_size[Velo::Constants::n_modules * event_number + module_number + 1] -
            parameters.dev_offsets_estimated_input_size[Velo::Constants::n_modules * event_number + module_number];
          assert(cluster_num <= module_estimated_num);
#endif

          const auto gx = ltg[0] * local_x + ltg[1] * local_y + ltg[9];
          const auto gy = ltg[3] * local_x + ltg[4] * local_y + ltg[10];
          const auto gz = ltg[6] * local_x + ltg[7] * local_y + ltg[11];
          const auto lhcb_id = get_lhcb_id(cid);

          velo_cluster_container.x(cluster_start + cluster_num) = gx;
          velo_cluster_container.y(cluster_start + cluster_num) = gy;
          velo_cluster_container.z(cluster_start + cluster_num) = gz;
          velo_cluster_container.id(cluster_start + cluster_num) = lhcb_id;
        }

        // if there is a second cluster for this pattern
        // add it as well.
        if (idx & 8) {
          const uint32_t row = (idx >> 4) & 3;
          const uint32_t col = (idx >> 6) & 1;
          const uint32_t cx = sp_col * 2 + col;
          const uint32_t cy = sp_row * 4 + row;

          uint cid = get_channel_id(raw_bank.sensor_index, chip, cx & VP::ChipColumns_mask, cy);

          const float fx = dev_velo_sp_fx[sp * 2 + 1];
          const float fy = dev_velo_sp_fy[sp * 2 + 1];
          const float local_x = g.local_x[cx] + fx * g.x_pitch[cx];
          const float local_y = (cy + 0.5f + fy) * Velo::Constants::pixel_size;

          const uint cluster_num = atomicAdd(module_cluster_num + module_number, 1);

#if DEBUG
          const auto module_estimated_num =
            parameters.dev_offsets_estimated_input_size[Velo::Constants::n_modules * event_number + module_number + 1] -
            parameters.dev_offsets_estimated_input_size[Velo::Constants::n_modules * event_number + module_number];
          assert(cluster_num <= module_estimated_num);
#endif

          const auto gx = ltg[0] * local_x + ltg[1] * local_y + ltg[9];
          const auto gy = ltg[3] * local_x + ltg[4] * local_y + ltg[10];
          const auto gz = ltg[6] * local_x + ltg[7] * local_y + ltg[11];
          const auto lhcb_id = get_lhcb_id(cid);

          velo_cluster_container.x(cluster_start + cluster_num) = gx;
          velo_cluster_container.y(cluster_start + cluster_num) = gy;
          velo_cluster_container.z(cluster_start + cluster_num) = gz;
          velo_cluster_container.id(cluster_start + cluster_num) = lhcb_id;
        }
      }
    }
  }

  __syncthreads();

  // Process rest of clusters
  for (uint candidate_number = threadIdx.x; candidate_number < number_of_candidates; candidate_number += blockDim.x) {
    const uint32_t candidate = cluster_candidates[candidate_number];
    const uint8_t sp_index = candidate >> 11;
    const uint8_t raw_bank_number = (candidate >> 3) & 0xFF;
    const uint32_t module_number = raw_bank_number >> 2;
    const uint8_t candidate_k = candidate & 0x7;

    assert(raw_bank_number < Velo::Constants::n_sensors);

    const auto raw_bank = VeloRawBank(raw_event.payload + raw_event.raw_bank_offset[raw_bank_number]);
    const float* ltg = g.ltg + g.n_trans * raw_bank.sensor_index;
    const uint32_t sp_word = raw_bank.sp_word[sp_index];
    const uint32_t sp_addr = (sp_word & 0x007FFF00U) >> 8;
    // Note: In the code below, row and col are int32_t (not unsigned)
    //       This is not a bug
    const int32_t sp_row = sp_addr & 0x3FU;
    const int32_t sp_col = sp_addr >> 6;

    // Find candidates that follow this condition:
    // For pixel x, all pixels o should *not* be populated
    // o o
    // x o
    //   o

    // Load the following SPs,
    // where x is the SP containing the possible candidates, o are other SPs:
    // oooo
    // oxoo
    // oooo
    // oooo
    //
    // Each column of SPs are in one uint32_t
    // Order is from left to right
    //
    // 0: o 1: o 2: o 3: o
    //    o    x    o    o
    //    o    o    o    o
    //    o    o    o    o
    //
    // Order inside an uint32_t is from bottom to top. Eg. 1:
    // 3: o
    // 2: x
    // 1: o
    // 0: o
    uint32_t pixel_array[3] = {0, 0, 0};

    // sp limits to load
    const int32_t sp_row_lower_limit = sp_row - 2;
    const int32_t sp_row_upper_limit = sp_row + 1;
    const int32_t sp_col_lower_limit = sp_col - 1;
    const int32_t sp_col_upper_limit = sp_col + 1;

    // Row limits
    const int32_t row_lower_limit = sp_row_lower_limit * 4;
    const int32_t col_lower_limit = sp_col_lower_limit * 2;

    // Load SPs
    // Note: We will pick up the current one,
    //       no need to add a special case
    for (uint k = 0; k < raw_bank.sp_count; ++k) {
      const uint32_t other_sp_word = raw_bank.sp_word[k];
      const uint32_t other_no_sp_neighbours = other_sp_word & 0x80000000U;
      if (!other_no_sp_neighbours) {
        const uint32_t other_sp_addr = (other_sp_word & 0x007FFF00U) >> 8;
        const int32_t other_sp_row = other_sp_addr & 0x3FU;
        const int32_t other_sp_col = (other_sp_addr >> 6);
        const uint8_t other_sp = other_sp_word & 0xFFU;

        if (
          other_sp_row >= sp_row_lower_limit && other_sp_row <= sp_row_upper_limit &&
          other_sp_col >= sp_col_lower_limit && other_sp_col <= sp_col_upper_limit) {
          const int relative_row = other_sp_row - sp_row_lower_limit;
          const int relative_col = other_sp_col - sp_col_lower_limit;

          // Note: Order is:
          // 15 31
          // 14 30
          // 13 29
          // 12 28
          // 11 27
          // 10 26
          //  9 25
          //  8 24
          //  7 23
          //  6 22
          //  5 21
          //  4 20
          //  3 19
          //  2 18
          //  1 17
          //  0 16
          pixel_array[relative_col] |= (other_sp & 0X0F) << (4 * relative_row) | (other_sp & 0XF0)
                                                                                   << (12 + 4 * relative_row);
        }
      }
    }

    // Work with candidate k
    const uint32_t row = sp_row * 4 + (candidate_k & 0x3);
    const uint32_t col = sp_col * 2 + (candidate_k >= 4);

    // ---------------------
    // Simplified clustering
    // ---------------------

    // Work with a 64-bit number instead
    const uint64_t start_pixel = ((uint64_t)(0x01 << (row - row_lower_limit)) << (16 * (col & 0x01))) << 32;
    const uint64_t pixel_map = (((uint64_t) pixel_array[1]) << 32) | pixel_array[0];
    uint64_t current_cluster = 0;
    uint64_t next_cluster = start_pixel;

    // Do clustering
    while (current_cluster != next_cluster) {
      current_cluster = next_cluster;
      next_cluster = pixel_map & make_8con_mask(current_cluster);
    }

    // Check if there are any hits with precedence
    const uint64_t hits_with_precedence =
      // Hits to the east, populated in the first 16 bits
      (mask_east(current_cluster) & pixel_array[2]) |
      // Hits in the current cluster with precedence in the latter 16 bits
      (current_cluster &
       (start_pixel ^ -start_pixel ^ (~(-(start_pixel << 16)) & ((uint64_t) 0xFFFF000000000000) * ((col + 1) & 0x01))));

    const int n = __popcll(current_cluster);
    if (n > 0 && hits_with_precedence == 0) {
      // If there are no hits with precedence,
      // create the cluster
      const int x = col_lower_limit * n + __popcll(current_cluster & 0x00000000FFFF0000) +
                    __popcll(current_cluster & 0x0000FFFF00000000) * 2 +
                    __popcll(current_cluster & 0xFFFF000000000000) * 3;

      const int y =
        row_lower_limit * n + __popcll(current_cluster & 0x0002000200020002) +
        __popcll(current_cluster & 0x0004000400040004) * 2 + __popcll(current_cluster & 0x0008000800080008) * 3 +
        __popcll(current_cluster & 0x0010001000100010) * 4 + __popcll(current_cluster & 0x0020002000200020) * 5 +
        __popcll(current_cluster & 0x0040004000400040) * 6 + __popcll(current_cluster & 0x0080008000800080) * 7 +
        __popcll(current_cluster & 0x0100010001000100) * 8 + __popcll(current_cluster & 0x0200020002000200) * 9 +
        __popcll(current_cluster & 0x0400040004000400) * 10 + __popcll(current_cluster & 0x0800080008000800) * 11 +
        __popcll(current_cluster & 0x1000100010001000) * 12 + __popcll(current_cluster & 0x2000200020002000) * 13 +
        __popcll(current_cluster & 0x4000400040004000) * 14 + __popcll(current_cluster & 0x8000800080008000) * 15;

      const uint cx = x / n;
      const uint cy = y / n;

      const float fx = x / static_cast<float>(n) - cx;
      const float fy = y / static_cast<float>(n) - cy;

      // store target (3D point for tracking)
      const uint32_t chip = cx >> VP::ChipColumns_division;

      uint cid = get_channel_id(raw_bank.sensor_index, chip, cx & VP::ChipColumns_mask, cy);

      const float local_x = g.local_x[cx] + fx * g.x_pitch[cx];
      const float local_y = (cy + 0.5f + fy) * Velo::Constants::pixel_size;

      const uint cluster_num = atomicAdd(module_cluster_num + module_number, 1);

#if DEBUG
      const auto module_estimated_num =
        parameters.dev_offsets_estimated_input_size[Velo::Constants::n_modules * event_number + module_number + 1] -
        parameters.dev_offsets_estimated_input_size[Velo::Constants::n_modules * event_number + module_number];
      assert(cluster_num <= module_estimated_num);
#endif

      const auto gx = ltg[0] * local_x + ltg[1] * local_y + ltg[9];
      const auto gy = ltg[3] * local_x + ltg[4] * local_y + ltg[10];
      const auto gz = ltg[6] * local_x + ltg[7] * local_y + ltg[11];
      const auto lhcb_id = get_lhcb_id(cid);

      const uint cluster_start = module_cluster_start[module_number];

      velo_cluster_container.x(cluster_start + cluster_num) = gx;
      velo_cluster_container.y(cluster_start + cluster_num) = gy;
      velo_cluster_container.z(cluster_start + cluster_num) = gz;
      velo_cluster_container.id(cluster_start + cluster_num) = lhcb_id;
    }
  }
}

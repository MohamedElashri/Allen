#pragma once
#include <iostream>
#include <iomanip>

#include "CaloConstants.cuh"
#include "CudaCommon.h"

struct CaloGeometry {
  uint32_t code_offset;
  uint32_t max_index;
  float* xy;
  uint16_t* channels;
  uint16_t* neighbors;

  __device__ __host__ CaloGeometry(const char* raw_geometry)
  {
    const char* p = raw_geometry;
    code_offset = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip code offset.
    max_index = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip max_index.
    const auto channels_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip channel size
    channels = (uint16_t*) p;
    p += sizeof(uint16_t) * channels_size;
    const auto neighbors_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip neighbours size
    neighbors = (uint16_t*)p;
    p += sizeof(uint16_t) * neighbors_size;
    // const uint32_t xy_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip xy size
    xy = (float*)p;

    // std::cout << "channels size " << channels_size << "\n";
    // for (size_t i = 0; i < 10; ++i) {
    //   std::cout << "channel   " << std::setw(2) << i << " " << std::setw(8) << channels[i] << "\n";
    // }

    // std::cout << "neighbors size " << neighbors_size << "\n";
    // auto const mn = Calo::Constants::max_neighbours;
    // for (size_t i = 0; i < 10 * mn; ++i) {
    //   std::cout << "neighbour " << std::setw(2) << i << " " << std::setw(8) << neighbors[i] << "\n";
    // }

    // std::cout << "xy size " << xy_size << "\n";
    // for (size_t i = 0; i < 10; ++i) {
    //   std::cout << "xy        " << std::setw(2) << i
    //             << std::setw(9) << std::setprecision(2) << std::fixed << xy[2 * i]
    //             << " " << std::setw(9) << std::setprecision(2)
    //             << std::fixed << xy[2 * i + 1] << "\n";
    // }
  }

  __device__ __host__ float getX(uint16_t cellid) const {
    return xy[2 * cellid];
  }

  __device__ __host__ float getY(uint16_t cellid) const {
    return xy[2 * cellid + 1];
  }

};

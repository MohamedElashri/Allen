#pragma once

#include <CudaCommon.h>
#include "CaloConstants.cuh"

struct CaloDigitClusters {
  uint16_t clustered_at_iteration = 0;
  uint16_t clusters[Calo::Constants::digit_max_clusters];

  __device__ __host__ CaloDigitClusters() {
    for (int i = 0; i < Calo::Constants::digit_max_clusters; i++) {
      clusters[i] = 0;
    }
  }
};

struct CaloCluster {
  uint32_t center_id = 0;
  uint32_t e = 0; // Is a double in the original algorithm, but is still integer here?
  float x = 0.f, y = 0.f;

  __device__ __host__ CaloCluster(uint16_t cellid, uint16_t adc, float rX, float rY)
    : center_id{cellid},
      e{adc},
      x{rX},
      y{rY}
  {
  }

};

struct CaloSeedCluster {
  uint16_t id = 0;
  uint16_t adc = 0; // Is a double in the original algorithm, but is still integer here?
  float x = 0.f, y = 0.f;

  __device__ __host__ CaloSeedCluster(uint16_t cellid, uint16_t a, float rX, float rY)
    : id{cellid},
      adc{a},
      x{rX},
      y{rY}
  {
  }

};

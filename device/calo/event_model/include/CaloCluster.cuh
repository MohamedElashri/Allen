#pragma once

#include <BackendCommon.h>
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
  float e = 0.f;
  float x = 0.f;
  float y = 0.f;
  uint16_t center_id = 0;
  uint16_t digits[Calo::Constants::max_neighbours] = {0, 0 ,0, 0, 0, 0, 0, 0, 0};

  __device__ __host__ CaloCluster(uint16_t index, float energy, float rX, float rY)
    : e{energy},
      x{rX},
      y{rY},
      center_id{index}
  {
  }

};

struct CaloSeedCluster {
  uint16_t id = 0;
  int16_t adc = 0; // Is a double in the original algorithm, but is still integer here?
  float x = 0.f;
  float y = 0.f;

  __device__ __host__ CaloSeedCluster(uint16_t cellid, int16_t a, float rX, float rY)
    : id{cellid},
      adc{a},
      x{rX},
      y{rY}
  {
  }

};

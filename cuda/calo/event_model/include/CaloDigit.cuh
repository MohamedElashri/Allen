#pragma once

#include "CudaCommon.h"

// Technically the maximum number of clusters for a single cell is 40,
// however the maximum found number in the data was 11.
#define MAX_CLUST 15 

struct CaloDigit {
  uint16_t adc;
  uint16_t clustered_at_iteration;
  uint16_t clusters[MAX_CLUST];

  __device__ __host__ CaloDigit() {
      adc = 0;
      clustered_at_iteration = 0;
      for (int i = 0; i < MAX_CLUST; i++) {
          clusters[i] = 0;
      }
  }

  __device__ __host__ static uint8_t area(uint16_t cellID) {
    return (cellID >> 12) & 0x3;
  }

  __device__ __host__ static uint8_t row(uint16_t cellID) {
    return (cellID >> 6) & 0x3F;
  }
  
  __device__ __host__ static uint8_t col(uint16_t cellID) {
    return cellID & 0x3F;
  }
};

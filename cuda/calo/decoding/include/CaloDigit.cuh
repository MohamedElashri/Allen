#pragma once

#include "CudaCommon.h"

#define MAX_NEIGH 9

struct CaloDigit {
  uint16_t adc;
  uint16_t clusters[MAX_NEIGH];

  __device__ __host__ CaloDigit() {
      adc = 0;
      for (int i = 0; i < MAX_NEIGH; i++) {
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

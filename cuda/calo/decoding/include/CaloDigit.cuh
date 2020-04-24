#pragma once

#include "CudaCommon.h"

#define MAX_NEIGH 9

struct CaloDigit {
  uint16_t cellID;
  uint16_t adc;
  struct CaloDigit* neighbors[MAX_NEIGH];
  uint16_t clusters[MAX_NEIGH];

  __device__ __host__ CaloDigit() {
      cellID = adc = 0;
      for (int i = 0; i < MAX_NEIGH; i++) {
          neighbors[i] = NULL;
          clusters[i] = 0;
      }
  }

  __device__ __host__ uint8_t area() const{
    return (cellID >> 12) & 0x3;
  }

  __device__ __host__ uint8_t row() const{
    return (cellID >> 6) & 0x3F;
  }
  
  __device__ __host__ uint8_t col() const{
    return cellID & 0x3F;
  }
};

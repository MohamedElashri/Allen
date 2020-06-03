#pragma once

#include "CudaCommon.h"

struct CaloDigit {
  uint16_t adc = 0;

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

#pragma once

#include "CudaCommon.h"

struct CaloCluster {
  uint16_t center_id;
  uint32_t e; // Is a double in the original algorithm, but is still integer here?
  float refX, refY;
  float x, y;

  __device__ __host__ CaloCluster() {
      center_id = 0;
      e = 0;
      x = y = 0;
      refX = refY = 0;
  }

  __device__ __host__ CaloCluster(uint16_t cellid, uint16_t adc, double rX, double rY) {
    center_id = cellid;
    e = adc;
    refX = rX;
    refY = rY;
    x = 0;
    y = 0;
  }

};

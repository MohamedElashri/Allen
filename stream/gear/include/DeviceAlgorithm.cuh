#pragma once

#include "Configuration.cuh"
#include "CudaCommon.h"
#include "Logger.h"
#include "RuntimeOptions.h"
#include "Constants.cuh"
#include "HostBuffers.cuh"
#include "GlobalFunction.cuh"
#include "Argument.cuh"

struct DeviceAlgorithm : public Algorithm {
  // Obtains the grid dimension. The grid dimension obtained in this way
  // is configurable through the JSON configuration files.
  dim3 grid_dimension() const {
    return {1, 1, 1};
  }

  // Obtains the block dimension. The block dimension obtained in this way
  // is configurable through the JSON configuration files.
  dim3 block_dimension() const {
    return {1, 1, 1};
  }
};

#pragma once

#include "Configuration.cuh"
#include "CudaCommon.h"
#include "Logger.h"
#include "RuntimeOptions.h"
#include "Constants.cuh"
#include "HostBuffers.cuh"
#include "GpuFunction.cuh"
#include "Argument.cuh"

struct GpuAlgorithm : public Algorithm {
private:
  CPUProperty<std::array<uint, 3>> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};
  CPUProperty<std::array<uint, 3>> m_grid_dim {this, "grid_dim", {1, 1, 1}, "grid dimensions"};

public:
  // Obtains the grid dimension. The grid dimension obtained in this way
  // is configurable through the JSON configuration files.
  dim3 grid_dimension() const {
    return {m_grid_dim.get_value()[0], m_grid_dim.get_value()[1], m_grid_dim.get_value()[2]};
  }

  // Obtains the block dimension. The block dimension obtained in this way
  // is configurable through the JSON configuration files.
  dim3 block_dimension() const {
    return {m_block_dim.get_value()[0], m_block_dim.get_value()[1], m_block_dim.get_value()[2]};
  }
};

typedef GpuAlgorithm DeviceAlgorithm;

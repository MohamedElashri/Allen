#pragma once

#include "Configuration.cuh"
#include "CudaCommon.h"
#include "Logger.h"
#include "RuntimeOptions.h"
#include "Constants.cuh"
#include "HostBuffers.cuh"
#include "CpuFunction.cuh"
#include "Argument.cuh"

// Note: For the moment, a CpuAlgorithm does not
//       differ from an Algorithm.
struct CpuAlgorithm : public Algorithm {};

typedef CpuAlgorithm HostAlgorithm;
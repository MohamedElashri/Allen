#pragma once

#include "Configuration.cuh"
#include "CudaCommon.h"
#include "Logger.h"
#include "RuntimeOptions.h"
#include "Constants.cuh"
#include "HostBuffers.cuh"
#include "HostFunction.cuh"
#include "Argument.cuh"

// Note: For the moment, a HostAlgorithm does not
//       differ from an Algorithm.
struct HostAlgorithm : public Allen::Algorithm {};

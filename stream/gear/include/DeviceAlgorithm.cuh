#pragma once

#include "Configuration.cuh"
#include "CudaCommon.h"
#include "Logger.h"
#include "RuntimeOptions.h"
#include "Constants.cuh"
#include "HostBuffers.cuh"
#include "GlobalFunction.cuh"
#include "Argument.cuh"

struct DeviceAlgorithm : public Allen::Algorithm {};

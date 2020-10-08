/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Algorithm.cuh"
#include "Property.cuh"
#include "BackendCommon.h"
#include "Logger.h"
#include "RuntimeOptions.h"
#include "Constants.cuh"
#include "HostBuffers.cuh"
#include "Property.cuh"
#include "Argument.cuh"

// Note: For the moment, a HostAlgorithm does not
//       differ from an Algorithm.
struct HostAlgorithm : public Allen::Algorithm {
};

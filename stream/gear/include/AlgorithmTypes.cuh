/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Algorithm.cuh"
#include "Property.cuh"
#include "Logger.h"
#include "BackendCommon.h"
#include "RuntimeOptions.h"
#include "Constants.cuh"
#include "HostBuffers.cuh"
#include "Datatype.cuh"
#include "InputAggregate.cuh"

struct DeviceAlgorithm : public Allen::Algorithm {
  constexpr static auto algorithm_scope = "DeviceAlgorithm";
};

struct HostAlgorithm : public Allen::Algorithm {
  constexpr static auto algorithm_scope = "HostAlgorithm";
};

struct SelectionAlgorithm : public Allen::Algorithm {
  constexpr static auto algorithm_scope = "SelectionAlgorithm";
};

struct ValidationAlgorithm : public Allen::Algorithm {
  constexpr static auto algorithm_scope = "ValidationAlgorithm";
};


/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once
#include "BackendCommon.h"
#include "AlgorithmTypes.cuh"

__device__ void groupsort2(float* x, int x_size);
__device__ void multiply(float const* w, float const* x, int R, int C, float* out);
__device__ void add_in_place(float* a, float const* b, int size);
__device__ float dot(float const* a, float const* b, int size);
__device__ float sigmoid(float x);
__device__ float propagation(
  const size_t input_size,
  const int* layer_sizes,
  const float* features_track,
  const float* monotone_constraints,
  const float lambda,
  const float* weights,
  const float* biases,
  const size_t n_layers,
  float* buf);

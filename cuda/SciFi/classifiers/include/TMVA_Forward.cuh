#pragma once

#include <vector>
#include <cmath>
#include <string>
#include <iostream>
#include "CudaCommon.h"

namespace SciFi {

  namespace Tracking {

    struct TMVA {
      float fMin_1[3][7];
      float fMax_1[3][7];

      float fWeightMatrix0to1[11][8];  // weight matrix from layer 0 to 1
      float fWeightMatrix1to2[10][11]; // weight matrix from layer 1 to 2
      float fWeightMatrix2to3[8][10];  // weight matrix from layer 2 to 3
      float fWeightMatrix3to4[1][8];   // weight matrix from layer 3 to 4
    };

    __host__ __device__ void Transform_1(float* iv, const TMVA* tmva);

    __host__ __device__ float ActivationFnc(float x);

    __host__ __device__ float OutputActivationFnc(float x);

    __host__ __device__ float GetMvaValue__(const float* inputValues, const TMVA* tmva);

    // the classifier response
    // "inputValues" is an array of input values in the same order as the
    // variables given to the constructor
    // WARNING: inputVariables will be modified
    __host__ __device__ float GetMvaValue(float* iV, const TMVA* tmva);

  } // namespace Tracking
} // namespace SciFi

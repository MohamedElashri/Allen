/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#pragma once

#include "BinarySearch.cuh"
#include "BackendCommon.h"
#include "DownstreamConstants.cuh"
#include "DownstreamHelper.cuh"

/**
 * @brief Downstream ghost killer
 * @details This is a neural network model to evaluate the probability of a track being a ghost track:
 * - The model takes 8 input features from the track.
 * - The output is the probability of the track being a ghost.
 * - The neural network has 1 hidden layer.
 * - The hidden layer has 14 nodes.
 * - The activation function of the hidden layer is ReLU.
 * - The activation function of the output layer is sigmoid.
 * - The input feature is preprocessed before feeding into the model.
 */

namespace Downstream {

  namespace DownstreamGhostKiller {
    namespace Model {
      constexpr unsigned num_node = 14;
      constexpr unsigned num_input = 8;

      // Data preprocessing
      __device__ constexpr float mean[num_input] = {4.641796e+00f,
                                                    1.218002e+00f,
                                                    2.066622e-03f,
                                                    6.105790e-04f,
                                                    7.931495e-01f,
                                                    -4.358424e-06f,
                                                    5.505731e+01f,
                                                    -4.577948e-06f};
      __device__ constexpr float std[num_input] = {1.352746e+02f,
                                                   1.245911e+02f,
                                                   5.589610e-02f,
                                                   5.300781e-02f,
                                                   2.882342e+00f,
                                                   1.944772e-04f,
                                                   1.236910e+02f,
                                                   1.933288e-04f};

      // First layer
      __device__ constexpr float weights1[num_node][num_input] = {{-3.130957e-01f,
                                                                   -1.641726e-01f,
                                                                   -1.713501e-01f,
                                                                   2.774569e+00f,
                                                                   1.790389e-01f,
                                                                   -3.443699e-01f,
                                                                   -2.390053e-01f,
                                                                   5.264124e-01f},
                                                                  {-4.543997e-01f,
                                                                   6.929203e-01f,
                                                                   -4.124951e-01f,
                                                                   1.667518e+00f,
                                                                   -5.790765e-01f,
                                                                   -1.736694e+00f,
                                                                   -3.035999e-02f,
                                                                   1.869971e+00f},
                                                                  {-3.892766e-01f,
                                                                   -3.091297e+00f,
                                                                   -1.589448e-01f,
                                                                   2.255488e+00f,
                                                                   3.155692e-02f,
                                                                   1.994863e+00f,
                                                                   -3.341647e-02f,
                                                                   -2.406254e+00f},
                                                                  {-7.619933e-01f,
                                                                   -2.538542e+00f,
                                                                   1.109884e-01f,
                                                                   1.752232e+00f,
                                                                   -2.004264e-03f,
                                                                   -2.304403e+00f,
                                                                   1.081031e-01f,
                                                                   2.905689e+00f},
                                                                  {-3.137227e+00f,
                                                                   7.107169e-03f,
                                                                   3.188610e+00f,
                                                                   -5.387322e-02f,
                                                                   -3.377151e-01f,
                                                                   2.856478e-02f,
                                                                   -5.703923e-01f,
                                                                   -3.752094e-01f},
                                                                  {2.237538e+00f,
                                                                   -6.104354e-01f,
                                                                   -5.572413e-01f,
                                                                   4.438097e-01f,
                                                                   -7.116383e-03f,
                                                                   -1.087367e+00f,
                                                                   1.802240e-01f,
                                                                   1.155475e+00f},
                                                                  {5.928768e-02f,
                                                                   -2.447907e-02f,
                                                                   -8.312039e-02f,
                                                                   2.518030e-02f,
                                                                   -6.497109e+00f,
                                                                   1.945986e-02f,
                                                                   4.570345e-02f,
                                                                   -2.633242e-02f},
                                                                  {2.100987e-01f,
                                                                   -2.667715e+00f,
                                                                   -3.156098e-01f,
                                                                   -8.274277e-02f,
                                                                   -1.800440e-01f,
                                                                   3.966420e-01f,
                                                                   -7.320842e-02f,
                                                                   -4.046147e-01f},
                                                                  {-4.163949e-02f,
                                                                   -4.757556e-01f,
                                                                   -2.431681e+00f,
                                                                   7.527031e-01f,
                                                                   3.115382e-01f,
                                                                   7.738712e-01f,
                                                                   -5.170256e-02f,
                                                                   -5.628102e-01f},
                                                                  {7.246921e-01f,
                                                                   2.845041e+00f,
                                                                   1.376653e+00f,
                                                                   -7.551545e-01f,
                                                                   -7.963621e-02f,
                                                                   -1.630609e+00f,
                                                                   -2.743626e-01f,
                                                                   1.314171e+00f},
                                                                  {1.418486e-01f,
                                                                   6.683669e-01f,
                                                                   -1.673536e+00f,
                                                                   1.410379e+00f,
                                                                   -9.580804e-01f,
                                                                   6.207639e-01f,
                                                                   -4.120404e-01f,
                                                                   -4.929127e-01f},
                                                                  {-3.945117e+00f,
                                                                   3.235341e-01f,
                                                                   4.177294e+00f,
                                                                   -3.466693e-01f,
                                                                   -3.598633e-01f,
                                                                   -2.199811e+00f,
                                                                   3.522165e-02f,
                                                                   2.189024e+00f},
                                                                  {2.677068e+00f,
                                                                   2.810622e+00f,
                                                                   -2.833140e+00f,
                                                                   -3.127442e+00f,
                                                                   1.409532e-01f,
                                                                   -2.729213e-01f,
                                                                   6.874584e-02f,
                                                                   7.594795e-02f},
                                                                  {-5.225655e+00f,
                                                                   1.249883e+00f,
                                                                   5.443477e+00f,
                                                                   -1.370031e+00f,
                                                                   -2.047247e-01f,
                                                                   2.758757e-01f,
                                                                   -2.960095e-02f,
                                                                   -7.413129e-01f}};

      __device__ constexpr float bias1[num_node] = {1.453953e+00f,
                                                    -1.725877e+00f,
                                                    -7.465494e-02f,
                                                    -2.972420e-02f,
                                                    7.792802e-02f,
                                                    -8.380271e-01f,
                                                    -1.598261e+00f,
                                                    -1.264492e-01f,
                                                    2.211707e-01f,
                                                    -6.500143e-03f,
                                                    -3.698997e-01f,
                                                    -7.611790e-02f,
                                                    -1.297739e-03f,
                                                    -9.083669e-04f};

      // Output layer
      __device__ constexpr float weights2[num_node] = {1.429899e+00f,
                                                       1.597910e+00f,
                                                       1.947038e+00f,
                                                       3.635926e+00f,
                                                       -2.577989e+00f,
                                                       1.932528e+00f,
                                                       -5.301486e+00f,
                                                       -2.333564e+00f,
                                                       -1.750178e+00f,
                                                       -1.834047e+00f,
                                                       -1.647779e+00f,
                                                       -4.475811e+00f,
                                                       2.974817e+00f,
                                                       5.892463e+00f};

      __device__ constexpr float bias2 = 6.899913e-01;

    } // namespace Model

    namespace ActivateFunction {
      // rectified linear unit
      __device__ inline float relu(const float x) { return x > 0 ? x : 0; }
      // sigmoid
      __device__ inline float sigmoid(const float x) { return __fdividef(1.0f, 1.0f + __expf(-x)); }
    } // namespace ActivateFunction

    // Evaluate the ghost killer, returning the probability of it being a ghost track.
    __device__ inline float evaluate(float* input)
    {
      // Data preprocessing
      DownstreamHelpers::unwind<0, Model::num_input>(
        [&](int i) { input[i] = __fdividef(input[i] - Model::mean[i], Model::std[i]); });

      float h1[Model::num_node] = {0.f};

      // First layer
      DownstreamHelpers::unwind<0, Model::num_node>([&](int i) {
        DownstreamHelpers::unwind<0, Model::num_input>([&](int j) { h1[i] += input[j] * Model::weights1[i][j]; });
        h1[i] = ActivateFunction::relu(h1[i] + Model::bias1[i]);
      });

      // Output layer
      float output = 0.f;
      DownstreamHelpers::unwind<0, Model::num_node>([&](int i) { output += h1[i] * Model::weights2[i]; });

      output = ActivateFunction::sigmoid(output + Model::bias2);
      return output;
    }
  } // namespace DownstreamGhostKiller

} // namespace Downstream

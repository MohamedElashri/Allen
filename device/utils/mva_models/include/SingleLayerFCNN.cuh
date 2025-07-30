
/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once
#include "MVAModelsManager.h"
#include "InputReader.h"
#include "BackendCommon.h"
#include <fstream>

namespace Allen::MVAModels {

  struct SingleLayerData {
    std::vector<float> mean;
    std::vector<float> std;
    std::vector<std::vector<float>> weights1;
    std::vector<float> fweights1;
    std::vector<float> bias1;
    std::vector<float> weights2;
    float bias2;
  };

  inline SingleLayerData readSingleLayerJSON(std::string full_path)
  {

    SingleLayerData to_copy;

    nlohmann::json j;
    {
      std::ifstream i(full_path);
      j = nlohmann::json::parse(i);
    }

    using array1d_t = std::vector<float>;
    using array2d_t = std::vector<array1d_t>;
    to_copy.mean = j.at("mean").get<array1d_t>();
    to_copy.std = j.at("std").get<array1d_t>();
    to_copy.weights1 = j.at("weights1").get<array2d_t>();
    to_copy.bias1 = j.at("bias1").get<array1d_t>();
    to_copy.weights2 = j.at("weights2").get<array1d_t>();
    to_copy.bias2 = j.at("bias2").get<float>();

    // Sanity checks
    assert(to_copy.mean.size() == j.at("num_input").get<unsigned>());
    assert(to_copy.std.size() == j.at("num_input").get<unsigned>());
    assert(
      to_copy.weights1.size() == j.at("num_node").get<unsigned>() &&
      to_copy.weights1.front().size() == j.at("num_input").get<unsigned>());
    assert(to_copy.bias1.size() == j.at("num_node").get<unsigned>());
    assert(to_copy.weights2.size() == j.at("num_node").get<unsigned>());

    // Flatten 2d array
    for (const auto& innerVec : to_copy.weights1) {
      to_copy.fweights1.insert(to_copy.fweights1.end(), innerVec.begin(), innerVec.end());
    }

    return to_copy;
  }
  template<unsigned num_input, unsigned num_node>
  struct DeviceSingleLayerFCNN {

    constexpr static unsigned nInput = num_input;
    constexpr static unsigned nNode = num_node;
    // Data preprocessing
    float mean[nInput];
    float std[nInput];
    // Model data
    float weights1[nNode][nInput];
    float bias1[nNode];
    float weights2[nNode];
    float bias2;

    __device__ inline float evaluate(float* input) const;
  };

  template<unsigned num_input, unsigned num_node>
  struct SingleLayerFCNN : public MVAModelBase {

    using DeviceType = DeviceSingleLayerFCNN<num_input, num_node>;

    SingleLayerFCNN(std::string name, std::string path) : MVAModelBase(name, path) { m_device_pointer = nullptr; }

    const DeviceType* getDevicePointer() const { return m_device_pointer; }

    void readData(std::string parameters_path) override
    {
      auto data_to_copy = readSingleLayerJSON(parameters_path + m_path);

      Allen::malloc((void**) &m_device_pointer, sizeof(DeviceType));

      constexpr auto size_mean = DeviceType::nInput * sizeof(float);
      constexpr auto size_std = DeviceType::nInput * sizeof(float);
      constexpr auto size_weights1 = (DeviceType::nNode * DeviceType::nInput) * sizeof(float);
      constexpr auto size_bias1 = DeviceType::nNode * sizeof(float);
      constexpr auto size_weights2 = DeviceType::nNode * sizeof(float);
      constexpr auto size_bias2 = sizeof(float);

      // Copy to device
      Allen::memcpy(m_device_pointer->mean, data_to_copy.mean.data(), size_mean, Allen::memcpyHostToDevice);
      Allen::memcpy(m_device_pointer->std, data_to_copy.std.data(), size_std, Allen::memcpyHostToDevice);
      Allen::memcpy(
        m_device_pointer->weights1, data_to_copy.fweights1.data(), size_weights1, Allen::memcpyHostToDevice);
      Allen::memcpy(m_device_pointer->bias1, data_to_copy.bias1.data(), size_bias1, Allen::memcpyHostToDevice);
      Allen::memcpy(m_device_pointer->weights2, data_to_copy.weights2.data(), size_weights2, Allen::memcpyHostToDevice);
      Allen::memcpy(&m_device_pointer->bias2, &data_to_copy.bias2, size_bias2, Allen::memcpyHostToDevice);
    }

  private:
    DeviceType* m_device_pointer;
  };

} // namespace Allen::MVAModels

namespace ActivateFunction {
  // rectified linear unit
  __device__ inline float relu(const float x) { return x > 0 ? x : 0; }
  // sigmoid
  __device__ inline float sigmoid(const float x)
  {
    // return __fdividef(1.0f, 1.0f + __expf(-x));
    return 1.0f / (1.0f + __expf(-x));
  }
  // __device__ inline float sigmoid(const float x) { return 1.0f / 1.0f + __expf(-x); } // ! change back
} // namespace ActivateFunction

template<unsigned num_input, unsigned num_node>
__device__ inline float Allen::MVAModels::DeviceSingleLayerFCNN<num_input, num_node>::evaluate(float* input) const
{
  using ModelType = Allen::MVAModels::DeviceSingleLayerFCNN<num_input, num_node>;
// Data preprocessing
#if (defined(TARGET_DEVICE_CUDA) && defined(__CUDACC__))
#pragma unroll
#endif
  for (unsigned i = 0; i < ModelType::nInput; i++) {
    // input[i] = __fdividef(input[i] - input_mean[i], input_std[i]);
    input[i] = (input[i] - mean[i]) / std[i];
  }
  float h1[ModelType::nNode] = {0.f};

// First layer
#if (defined(TARGET_DEVICE_CUDA) && defined(__CUDACC__))
#pragma unroll
#endif
  for (unsigned i = 0; i < ModelType::nNode; i++) {
#if (defined(TARGET_DEVICE_CUDA) && defined(__CUDACC__))
#pragma unroll
#endif
    for (unsigned j = 0; j < ModelType::nInput; j++) {
      h1[i] += input[j] * weights1[i][j];
    }
    h1[i] = ActivateFunction::relu(h1[i] + bias1[i]);
  }

  // Output layer
  float output = 0.f;
#if (defined(TARGET_DEVICE_CUDA) && defined(__CUDACC__))
#pragma unroll
#endif
  for (unsigned i = 0; i < ModelType::nNode; i++) {
    output += h1[i] * weights2[i];
  }

  output = ActivateFunction::sigmoid(output + bias2);

  return output;
}
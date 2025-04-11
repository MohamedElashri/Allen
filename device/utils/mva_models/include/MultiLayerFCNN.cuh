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
#include <boost/algorithm/string.hpp>
#include <fstream>

namespace Allen::MVAModels {

  __device__ inline void groupsort2(float* x, int x_size)
  {
    for (int i = 0; i < x_size; i += 2) {
      auto lhs = x[i];
      auto rhs = x[i + 1];
      auto ge = lhs >= rhs;
      x[i] = ge ? rhs : lhs;
      x[i + 1] = ge ? lhs : rhs;
    }
  }

  __device__ inline void multiply(float const* w, float const* x, int R, int C, float* out)
  {
    // w * x = sum_j (w_ij*xj)
    for (int i = 0; i < R; ++i) {
      out[i] = 0;
      for (int j = 0; j < C; ++j) {
        out[i] += w[i * C + j] * x[j];
      }
    }
  }

  __device__ inline void add_in_place(float* a, float const* b, int size)
  {
    for (int i = 0; i < size; ++i) {
      a[i] = a[i] + b[i];
    }
  }

  __device__ inline float dot(float const* a, float const* b, int size)
  {
    float out = 0;
    for (int i = 0; i < size; ++i) {
      out += a[i] * b[i];
    }
    return out;
  }

  __device__ inline float sigmoid(float x) { return 1 / (1 + expf(-1 * x)); }

  __device__ float inline log_feature(float feature) { return logf(max(fabsf(feature), 1e-10f)); }
  __device__ float inline rescale(float feature, int idx, const float* min_rescales, const float* max_rescales)
  {
    return (feature - min_rescales[idx]) / (max_rescales[idx] - min_rescales[idx]);
  }
  __device__ float inline clip(float feature)
  {
    if (feature > 1.f)
      return 1.f;
    else if (feature < 0.f)
      return 0.f;
    return feature;
  }
  template<typename T>
  inline __host__ __device__ T square(const T a)
  {
    return a * a;
  }

  struct MultiLayerData {
    unsigned total_size = 0u;
    std::map<int, nlohmann::json> weights_map;
    std::vector<float> all_weights;
    std::map<int, nlohmann::json> biases_map;
    std::vector<float> all_biases;

    int first_layer_n_features;
    std::vector<float> constraints;
    std::vector<float> rescale_min;
    std::vector<float> rescale_max;

    float sigma;
    float nominal_cut;
    std::vector<int> layer_sizes;
  };

  inline MultiLayerData readMultiLayerJSON(std::string full_path)
  {

    MultiLayerData dataToReturn;

    nlohmann::json j;
    {
      std::ifstream i(full_path);
      j = nlohmann::json::parse(i);
    }

    assert(j.contains("nominal_cut"));
    assert(j.contains("sigmanet.sigma"));

    {
      for (const auto& element : j.items()) {
        const auto is_bias = boost::algorithm::contains(element.key(), ".bias");
        const auto is_weight = boost::algorithm::contains(element.key(), ".weight");
        const auto is_constraints = boost::algorithm::contains(element.key(), "constraints");
        const auto is_rescale_min = boost::algorithm::contains(element.key(), "rescale_min");
        const auto is_rescale_max = boost::algorithm::contains(element.key(), "rescale_max");
        if (is_constraints || is_rescale_min || is_rescale_max) {
          dataToReturn.total_size += element.value().size() * sizeof(float);
        }
        else if (is_weight || is_bias) {
          std::vector<std::string> tokens;
          boost::split(tokens, element.key(), boost::is_any_of("."));
          auto layer_n = std::stoi(tokens[tokens.size() - 2]) + 1;

          if (is_weight) {
            for (const auto& w : element.value()) {
              dataToReturn.total_size += w.size() * sizeof(float);
            }
            dataToReturn.weights_map.emplace(layer_n, element.value());
          }
          else {
            dataToReturn.total_size += element.value().size() * sizeof(float);
            dataToReturn.total_size += sizeof(unsigned);
            dataToReturn.biases_map.emplace(layer_n, element.value());
          }
        }
      }

      for (const auto& [_, weight] : dataToReturn.weights_map) {
        const auto weight_data = weight.get<std::vector<std::vector<float>>>();
        for (const auto& weight_row : weight_data) {
          dataToReturn.all_weights.insert(dataToReturn.all_weights.end(), weight_row.begin(), weight_row.end());
        }
      }

      for (const auto& [_, bias] : dataToReturn.biases_map) {
        const auto bias_data = bias.get<std::vector<float>>();
        dataToReturn.all_biases.insert(dataToReturn.all_biases.end(), bias_data.begin(), bias_data.end());
      }

      // counting layer sizes:
      dataToReturn.first_layer_n_features = j.contains("n_features") ? static_cast<int>(j["n_features"]) : 4;

      dataToReturn.layer_sizes.reserve(dataToReturn.biases_map.size());
      dataToReturn.layer_sizes.emplace_back(dataToReturn.first_layer_n_features);

      for (const auto& [_, bias] : dataToReturn.biases_map) {
        const auto bias_data = bias.get<std::vector<float>>();
        dataToReturn.layer_sizes.emplace_back(bias_data.size());
      }

      // two float values: lambda and nominal cut, two unsigned values: first layer size and number of layers
      dataToReturn.total_size += sizeof(float) * 2 + 2 * sizeof(unsigned);

      if (!j.contains("constraints")) {
        dataToReturn.total_size += sizeof(float) * 4;
      }

      if (j.contains("rescale_min") && j.contains("rescale_max")) {
        dataToReturn.rescale_min = j["rescale_min"].get<std::vector<float>>();
        dataToReturn.rescale_max = j["rescale_max"].get<std::vector<float>>();
      }

      dataToReturn.constraints =
        (j.contains("constraints")) ? j["constraints"].get<std::vector<float>>() : std::vector<float>({1, 1, 0, 1});

      dataToReturn.sigma = j["sigmanet.sigma"][0].get<float>();
      dataToReturn.nominal_cut = j["nominal_cut"].get<float>();
    }

    return dataToReturn;
  }

  // Primary template for the multi-layer network
  template<unsigned First, unsigned... Layers>
  struct DeviceMultiLayerFCNN {
    static constexpr unsigned n_features = First;
    static constexpr unsigned n_layers = sizeof...(Layers) + 1;

    int layer_sizes[n_layers];

    float constaints[n_features];
    float rescale_min[n_features];
    float rescale_max[n_features];

    float sigma;
    float nominal_cut;

    __device__ const float* get_constraints() const { return constaints; }
    __device__ const float* get_min_rescales() const { return rescale_min; }
    __device__ const float* get_max_rescales() const { return rescale_max; }

    __device__ const int* get_layer_sizes() const { return layer_sizes; }

    __device__ float get_lambda() const { return (sigma); }
    __device__ float get_nominal_cut() const { return (nominal_cut); }

    __device__ float propagation(const float* features_track, const float* weights, const float* biases, float* buf)
      const
    {
      float* buf1 = buf;
      float* buf2 = buf + 32;
      float response;
      // copy into buffer for forward pass through
      // main network
      for (size_t i = 0; i < n_features; ++i) {
        buf1[i] = features_track[i];
      }

      // preparation for forward pass
      const float* weight_ptr = weights;
      const float* bias_ptr = biases;
      float* input = buf1;
      float* output = buf2;

      // forward pass itself
      for (unsigned layer_idx = 1; layer_idx < n_layers; ++layer_idx) {
        unsigned n_inputs = layer_sizes[layer_idx - 1];
        unsigned n_outputs = layer_sizes[layer_idx];
        // W * x

        multiply(weight_ptr, input, n_outputs, n_inputs, output);
        // point to next layers weights
        weight_ptr += n_outputs * n_inputs;
        // W * x + b
        add_in_place(output, bias_ptr, n_outputs);
        // point to next layers biases
        bias_ptr += n_outputs;

        // activation (if not last layer)
        if (layer_idx != n_layers - 1) {
          groupsort2(output, n_outputs);
          // swap data pointers ( buf1 <-> buf2 )
          // for the next loop iteration
          float* tmp = input;
          input = output;
          output = tmp;
        }
      }
      response = output[0] + sigma * dot(features_track, constaints, n_features);
      return std::isfinite(response) ? sigmoid(response) : 0.f;
    }
  };

  template<unsigned First, unsigned... Layers>
  struct HostMultiLayerFCNN {

    // Calculate the desired value using the Calculate struct
    static constexpr unsigned n_biases =
      std::apply([](const auto... values) { return (values + ...); }, std::make_tuple(Layers...));

    static constexpr unsigned n_weights = []() {
      return std::apply(
        [](auto&&... args) {
          unsigned sum = 0;
          // Creating an array from the arguments to iterate through them

          unsigned arr[] = {args...}; // Create an array from the tuple elements
          for (std::size_t i = 0; i < sizeof...(args) - 1; ++i) {
            sum += arr[i] * arr[i + 1]; // Sum the products of adjacent elements
          }

          return sum; // Return the computed sum
        },
        std::make_tuple(First, Layers...)); // Apply the lambda to the tuple
    }();

    float weights[n_weights];
    float biases[n_biases];
  };

  // Change to use integers for layers if needed
  template<unsigned... Layers>
  struct MultiLayerFCNN : public MVAModelBase {
    using DeviceType = DeviceMultiLayerFCNN<Layers...>;
    using HostType = HostMultiLayerFCNN<Layers...>;

    MultiLayerFCNN(std::string name, std::string path) : MVAModelBase(name, path)
    {
      m_device_pointer = nullptr;
      m_host_pointer = nullptr;
    }

    void readData(std::string parameters_path) override
    {
      auto data_to_copy = readMultiLayerJSON(parameters_path + m_path);

      constexpr auto size_weights = HostType::n_weights * sizeof(float);
      constexpr auto size_biases = HostType::n_biases * sizeof(float);

      constexpr auto size_layer_sizes = DeviceType::n_layers * sizeof(int);

      constexpr auto size_constraints_rescaler = DeviceType::n_features * sizeof(float);

      Allen::malloc((void**) &m_device_pointer, sizeof(DeviceType));
      Allen::malloc_host((void**) &m_host_pointer, sizeof(HostType));

      Allen::memcpy(
        m_device_pointer->constaints,
        data_to_copy.constraints.data(),
        size_constraints_rescaler,
        Allen::memcpyHostToDevice);
      Allen::memcpy(
        m_device_pointer->layer_sizes, data_to_copy.layer_sizes.data(), size_layer_sizes, Allen::memcpyHostToDevice);

      Allen::memcpy(&m_device_pointer->sigma, &data_to_copy.sigma, sizeof(float), Allen::memcpyHostToDevice);
      Allen::memcpy(
        &m_device_pointer->nominal_cut, &data_to_copy.nominal_cut, sizeof(float), Allen::memcpyHostToDevice);

      if (data_to_copy.rescale_min.size() != 0) {
        Allen::memcpy(
          m_device_pointer->rescale_min,
          data_to_copy.rescale_min.data(),
          size_constraints_rescaler,
          Allen::memcpyHostToDevice);
        Allen::memcpy(
          m_device_pointer->rescale_max,
          data_to_copy.rescale_max.data(),
          size_constraints_rescaler,
          Allen::memcpyHostToDevice);
      }

      std::memcpy(m_host_pointer->weights, data_to_copy.all_weights.data(), size_weights);
      std::memcpy(m_host_pointer->biases, data_to_copy.all_biases.data(), size_biases);
    }

    const HostType* getHostPointer() const { return m_host_pointer; }
    const DeviceType* getDevicePointer() const { return m_device_pointer; }

    const float* get_weights() const { return m_host_pointer->weights; }
    const float* get_biases() const { return m_host_pointer->biases; }

  private:
    DeviceType* m_device_pointer;
    HostType* m_host_pointer;
  };
} // namespace Allen::MVAModels
/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <string>
#include <vector>
#include <set>
#include <BackendCommon.h>
#include <Common.h>
#include <Consumers.h>
#include "UTDefinitions.cuh"
#include "UTMagnetToolDefinitions.h"

namespace {
  using std::string;
  using std::to_string;

  template<bool absolute_value>
  std::set<float> get_unique_values(const float* array, const unsigned size)
  {
    std::set<float> result;
    if constexpr (absolute_value) {
      std::transform(array, array + size, std::inserter(result, result.end()), [](float i) { return fabsf(i); });
    }
    else {
      std::transform(array, array + size, std::inserter(result, result.end()), [](float i) { return i; });
    }
    return result;
  }

  template<bool absolute_value>
  std::set<float> get_unique_values(gsl::span<float> array)
  {
    std::set<float> result;
    if constexpr (absolute_value) {
      std::transform(array.begin(), array.end(), std::inserter(result, result.end()), [](float i) { return fabsf(i); });
    }
    else {
      std::transform(array.begin(), array.end(), std::inserter(result, result.end()), [](float i) { return i; });
    }
    return result;
  }

  using ConditionFunction_t = std::function<bool(float)>;
  template<typename Data_t>
  float compute_mean_value(
    const Data_t& input,
    ConditionFunction_t condition_function = [](auto) { return true; })
  {
    return std::accumulate(
             input.begin(),
             input.end(),
             0.f,
             [&condition_function](float acc, float val) { return condition_function(val) ? acc + val : acc; }) /
           std::count_if(input.begin(), input.end(), condition_function);
  }

  template<typename Data_t>
  float compute_middle_value(const Data_t& input)
  {
    const auto min_val = *std::min_element(input.begin(), input.end());
    const auto max_val = *std::max_element(input.begin(), input.end());
    return (min_val + max_val) / 2;
  }

  template<typename Data_t>
  float compute_middle_value(const Data_t& input, ConditionFunction_t condition_function)
  {
    Data_t filtered;
    std::copy_if(input.begin(), input.end(), std::inserter(filtered, filtered.end()), condition_function);
    const auto min_val = *std::min_element(filtered.begin(), filtered.end());
    const auto max_val = *std::max_element(filtered.begin(), filtered.end());
    return (min_val + max_val) / 2;
  }
} // namespace

Consumers::UTGeometry::UTGeometry(Constants& constants) : m_constants {constants} {}

void Consumers::UTGeometry::initialize(std::vector<char> const& data)
{

  auto alloc_and_copy = [](auto const& host_numbers, auto& device_numbers) {
    using value_type = typename std::remove_reference_t<decltype(host_numbers)>::value_type;
    using span_type = typename std::remove_reference_t<decltype(device_numbers)>::value_type;
    value_type* p = nullptr;
    Allen::malloc((void**) &p, host_numbers.size() * sizeof(value_type));
    device_numbers = gsl::span {p, static_cast<span_size_t<span_type>>(host_numbers.size())};
    Allen::memcpy(
      device_numbers.data(), host_numbers.data(), host_numbers.size() * sizeof(value_type), Allen::memcpyHostToDevice);
  };

  // region offsets
  auto& host_ut_region_offsets = m_constants.get().host_ut_region_offsets;
  //   auto& dev_ut_region_offsets = m_constants.get().dev_ut_region_offsets;
  // FIXME_GEOMETRY_HARDCODING
  host_ut_region_offsets = {0, 84, 164, 248, 332, 412, 496, 594, 674, 772, 870, 950, 1048};
  //   alloc_and_copy(host_ut_region_offsets, dev_ut_region_offsets);

  auto& host_ut_dxDy = m_constants.get().host_ut_dxDy;
  // FIXME_GEOMETRY_HARDCODING
  host_ut_dxDy = {0., 0.08748867, -0.0874886, 0.};
  alloc_and_copy(host_ut_dxDy, m_constants.get().dev_ut_dxDy);

  // Allocate space for geometry
  auto& dev_ut_geometry = m_constants.get().dev_ut_geometry;
  using span_type = typename std::remove_reference_t<decltype(dev_ut_geometry)>::value_type;
  char* g = nullptr;
  Allen::malloc((void**) &g, data.size());
  dev_ut_geometry = gsl::span {g, static_cast<span_size_t<span_type>>(data.size())};
  const ::UTGeometry geometry {data};

  // Offset for each station / layer
  const std::array<unsigned, UT::Constants::n_layers + 1> offsets {host_ut_region_offsets[0],
                                                                   host_ut_region_offsets[3],
                                                                   host_ut_region_offsets[6],
                                                                   host_ut_region_offsets[9],
                                                                   host_ut_region_offsets[12]};
  int current_sector_offset = 0;
  auto& host_unique_x_sector_layer_offsets = m_constants.get().host_unique_x_sector_layer_offsets;
  auto& host_unique_x_sector_offsets = m_constants.get().host_unique_x_sector_offsets;
  auto& host_unique_sector_xs = m_constants.get().host_unique_sector_xs;
  auto& host_mean_ut_layer_zs = m_constants.get().host_mean_ut_layer_zs;
  host_unique_x_sector_layer_offsets[0] = 0;

  // Container for per layer constants
  auto& dev_ut_per_layer_info = m_constants.get().dev_ut_per_layer_info;
  auto host_ut_per_layer_info = new UT::Constants::PerLayerInfo {};
  m_constants.get().host_ut_per_layer_info = host_ut_per_layer_info;

  for (unsigned i = 0; i < UT::Constants::n_layers; ++i) {
    const auto offset = offsets[i];
    const auto size = offsets[i + 1] - offsets[i];

    // Find the mean small and large dy for each layer (2 types (AB or CD))
    const auto unique_layer_dy = get_unique_values<true>(geometry.dy + offset, size);
    const auto middle_dy = compute_middle_value(unique_layer_dy);
    const auto small_mean_dy = compute_mean_value(unique_layer_dy, [middle_dy](float v) { return v < middle_dy; });
    const auto large_mean_dy = compute_mean_value(unique_layer_dy, [middle_dy](float v) { return v >= middle_dy; });
    host_ut_per_layer_info->two_dy[i][0] = small_mean_dy;
    host_ut_per_layer_info->two_dy[i][1] = large_mean_dy;

    // Find 4 mean z positions for each layer (2 Sides + 2 Faces)
    const auto unique_layer_z = get_unique_values<true>(geometry.p0Z + offset, size);
    const auto mean_z = compute_mean_value(unique_layer_z);
    host_ut_per_layer_info->mean_z[i] = mean_z;
    host_mean_ut_layer_zs.push_back(mean_z);

    // Find the mean dxdy for each layer
    float mean_dxdy = 0.f, min_dxdy = 0.f, max_dxdy = 0.f;
    if (geometry.dxDy != nullptr) {
      gsl::span<float> all_dxdy(geometry.dxDy + offset, size);
      const auto unique_layer_dxdy = get_unique_values<false>(all_dxdy);
      mean_dxdy = compute_mean_value(unique_layer_dxdy);
      min_dxdy = *std::min_element(unique_layer_dxdy.begin(), unique_layer_dxdy.end());
      max_dxdy = *std::max_element(unique_layer_dxdy.begin(), unique_layer_dxdy.end());
    }
    else {
      mean_dxdy = UT::Constants::hardcoded_dxdy(i);
      min_dxdy = UT::Constants::hardcoded_dxdy(i);
      max_dxdy = UT::Constants::hardcoded_dxdy(i);
    }
    host_ut_per_layer_info->mean_dxDy[i] = mean_dxdy;
    host_ut_per_layer_info->min_dxDy[i] = min_dxdy;
    host_ut_per_layer_info->max_dxDy[i] = max_dxdy;

    // Copy elements into xs vector and zs vector
    std::vector<float> xs(size), zs(size);
    std::copy_n(geometry.p0X + offset, size, xs.begin());
    std::copy_n(geometry.p0Z + offset, size, zs.begin());

    // Create permutation
    std::vector<int> permutation(xs.size());
    std::iota(permutation.begin(), permutation.end(), 0);

    // Sort permutation according to xs and zs
    std::stable_sort(
      permutation.begin(), permutation.end(), [&xs](const int& a, const int& b) { return xs[a] < xs[b]; });

    // Iterate the permutation, incrementing the counter when the element changes.
    // Calculate unique elements
    std::vector<int> permutation_repeated;
    auto current_element = xs[permutation[0]];
    int current_index = 0;
    int number_of_unique_elements = 1;

    for (auto p : permutation) {
      // Allow for a configurable window of error
      constexpr float accepted_error_window = 20.f;
      if (std::abs(current_element - xs[p]) > accepted_error_window) {
        current_element = xs[p];
        current_index++;
        number_of_unique_elements++;
      }
      if (current_element < xs[p]) current_element = xs[p];
      permutation_repeated.emplace_back(current_index);
    }

    // Calculate final permutation into unique elements
    std::vector<int> unique_permutation;
    for (size_t j = 0; j < size; ++j) {
      auto it = std::find(permutation.begin(), permutation.end(), j);
      auto position = it - permutation.begin();
      unique_permutation.emplace_back(permutation_repeated[position]);
    }

    // Find the not repeated zs
    std::set<float> set_zs;
    std::transform(zs.begin(), zs.end(), std::inserter(set_zs, set_zs.begin()), [](float i) { return fabsf(i); });

    // Fill in host_unique_sector_xs
    std::vector<float> temp_unique_elements(number_of_unique_elements);
    std::fill(temp_unique_elements.begin(), temp_unique_elements.end(), Allen::numeric_limits<float>::infinity());
    for (size_t j = 0; j < size; ++j) {
      const int index = unique_permutation[j];
      if (xs[j] < temp_unique_elements[index]) temp_unique_elements[index] = xs[j];
    }
    for (int j = 0; j < number_of_unique_elements; ++j) {
      host_unique_sector_xs.emplace_back(temp_unique_elements[j]);
    }

    // Fill in host_unique_x_sector_offsets
    for (auto p : unique_permutation) {
      host_unique_x_sector_offsets.emplace_back(current_sector_offset + p);
    }

    // Fill in host_unique_x_sectors
    current_sector_offset += number_of_unique_elements;
    host_unique_x_sector_layer_offsets[i + 1] = current_sector_offset;
  }

  Allen::malloc((void**) &dev_ut_per_layer_info, sizeof(UT::Constants::PerLayerInfo));
  Allen::memcpy(
    m_constants.get().dev_ut_per_layer_info,
    host_ut_per_layer_info,
    sizeof(UT::Constants::PerLayerInfo),
    Allen::memcpyHostToDevice);

  // Populate device constant into global memory
  std::tuple numbers {
    std::tuple {std::cref(host_unique_x_sector_layer_offsets),
                std::ref(m_constants.get().dev_unique_x_sector_layer_offsets)},
    std::tuple {std::cref(host_unique_x_sector_offsets), std::ref(m_constants.get().dev_unique_x_sector_offsets)},
    std::tuple {std::cref(host_mean_ut_layer_zs), std::ref(m_constants.get().dev_mean_ut_layer_zs)},
    std::tuple {std::cref(host_unique_sector_xs), std::ref(m_constants.get().dev_unique_sector_xs)}};

  for_each(
    numbers, [&alloc_and_copy](auto& entry) { alloc_and_copy(std::get<0>(entry).get(), std::get<1>(entry).get()); });
}

void Consumers::UTGeometry::consume(std::vector<char> const& data)
{
  auto& dev_ut_geometry = m_constants.get().dev_ut_geometry;
  if (dev_ut_geometry.empty()) {
    initialize(data);
  }
  else if (static_cast<size_t>(dev_ut_geometry.size()) != data.size()) {
    throw StrException {string {"sizes don't match: "} + to_string(dev_ut_geometry.size()) + " " +
                        to_string(data.size())};
  }

  auto& host_ut_geometry = m_constants.get().host_ut_geometry;
  host_ut_geometry = data;
  Allen::memcpy(dev_ut_geometry.data(), host_ut_geometry.data(), host_ut_geometry.size(), Allen::memcpyHostToDevice);
}

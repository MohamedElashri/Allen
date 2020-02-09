#include <string>
#include <vector>
#include <CudaCommon.h>
#include <Common.h>
#include <Consumers.h>
#include "UTDefinitions.cuh"
#include "UTMagnetToolDefinitions.h"

namespace {
  using std::string;
  using std::to_string;
} // namespace

Consumers::UTGeometry::UTGeometry(Constants& constants) : m_constants {constants} {}

void Consumers::UTGeometry::initialize(std::vector<char> const& data)
{

  auto alloc_and_copy = [](auto const& host_numbers, auto& device_numbers) {
    using value_type = typename std::remove_reference_t<decltype(host_numbers)>::value_type;
    using index_type = typename std::remove_reference_t<decltype(device_numbers)>::index_type;
    value_type* p = nullptr;
    cudaCheck(cudaMalloc((void**) &p, host_numbers.size() * sizeof(value_type)));
    device_numbers = gsl::span {p, static_cast<index_type>(host_numbers.size())};
    cudaCheck(cudaMemcpy(
      device_numbers.data(), host_numbers.data(), host_numbers.size() * sizeof(value_type), cudaMemcpyHostToDevice));
  };

  // region offsets
  auto& host_ut_region_offsets = m_constants.get().host_ut_region_offsets;
  auto& dev_ut_region_offsets = m_constants.get().dev_ut_region_offsets;
  // FIXME_GEOMETRY_HARDCODING
  host_ut_region_offsets = {0, 84, 164, 248, 332, 412, 496, 594, 674, 772, 870, 950, 1048};
  alloc_and_copy(host_ut_region_offsets, dev_ut_region_offsets);

  auto& host_ut_dxDy = m_constants.get().host_ut_dxDy;
  // FIXME_GEOMETRY_HARDCODING
  host_ut_dxDy = {0., 0.08748867, -0.0874886, 0.};
  alloc_and_copy(host_ut_dxDy, m_constants.get().dev_ut_dxDy);

  // Allocate space for geometry
  auto& dev_ut_geometry = m_constants.get().dev_ut_geometry;
  using index_type = typename std::remove_reference_t<decltype(dev_ut_geometry)>::index_type;
  char* g = nullptr;
  cudaCheck(cudaMalloc((void**) &g, data.size()));
  dev_ut_geometry = gsl::span {g, static_cast<index_type>(data.size())};
  const ::UTGeometry geometry {data};

  // Offset for each station / layer
  const std::array<uint, UT::Constants::n_layers + 1> offsets {host_ut_region_offsets[0],
                                                               host_ut_region_offsets[3],
                                                               host_ut_region_offsets[6],
                                                               host_ut_region_offsets[9],
                                                               host_ut_region_offsets[12]};
  auto current_sector_offset = 0;
  auto& host_unique_x_sector_layer_offsets = m_constants.get().host_unique_x_sector_layer_offsets;
  auto& host_unique_x_sector_offsets = m_constants.get().host_unique_x_sector_offsets;
  auto& host_unique_sector_xs = m_constants.get().host_unique_sector_xs;
  host_unique_x_sector_offsets[current_sector_offset];
  host_unique_x_sector_layer_offsets[0] = 0;

  for (uint i = 0; i < UT::Constants::n_layers; ++i) {
    const auto offset = offsets[i];
    const auto size = offsets[i + 1] - offsets[i];

    // Copy elements into xs vector
    std::vector<float> xs(size);
    std::copy_n(geometry.p0X + offset, size, xs.begin());

    // Create permutation
    std::vector<int> permutation(xs.size());
    std::iota(permutation.begin(), permutation.end(), 0);

    // Sort permutation according to xs
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
      constexpr float accepted_error_window = 2.f;
      if (std::abs(current_element - xs[p]) > accepted_error_window) {
        current_element = xs[p];
        current_index++;
        number_of_unique_elements++;
      }
      permutation_repeated.emplace_back(current_index);
    }

    // Calculate final permutation into unique elements
    std::vector<int> unique_permutation;
    for (size_t j = 0; j < size; ++j) {
      auto it = std::find(permutation.begin(), permutation.end(), j);
      auto position = it - permutation.begin();
      unique_permutation.emplace_back(permutation_repeated[position]);
    }

    // Fill in host_unique_sector_xs
    std::vector<float> temp_unique_elements(number_of_unique_elements);
    for (size_t j = 0; j < size; ++j) {
      const int index = unique_permutation[j];
      temp_unique_elements[index] = xs[j];
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

  // Populate device constant into global memory
  std::tuple numbers {
    std::tuple {std::cref(host_unique_x_sector_layer_offsets),
                std::ref(m_constants.get().dev_unique_x_sector_layer_offsets)},
    std::tuple {std::cref(host_unique_x_sector_offsets), std::ref(m_constants.get().dev_unique_x_sector_offsets)},
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
  host_ut_geometry = std::move(data);
  cudaCheck(
    cudaMemcpy(dev_ut_geometry.data(), host_ut_geometry.data(), host_ut_geometry.size(), cudaMemcpyHostToDevice));
}

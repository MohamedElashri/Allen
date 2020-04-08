#pragma once

#include "CudaCommon.h"
#include "CudaMathConstants.h"
#include "ArgumentManager.cuh"
#include "VeloEventModel.cuh"

namespace Velo {
  namespace Tools {
    constexpr float max_input_value = 2.f * static_cast<float>(CUDART_PI_F);
    constexpr float max_output_value = 65536.f;
    constexpr float convert_factor = max_output_value / max_input_value;
    constexpr int16_t shift_value = static_cast<int16_t>(65536 / 2);
  } // namespace Tools
} // namespace Velo

/**
 * @brief Calculates the hit phi in a int16 format.
 * @details The range of the atan2 function is mapped onto the range of the int16,
 *          such that for two hit phis in this format, the difference is stable
 *          regardless of the values.
 */
__device__ inline int16_t hit_phi_16(const float x, const float y)
{
  // We have to convert the range {-PI, +PI} into {-2^15, (2^15 - 1)}
  // Simpler: Convert {0, 2 PI} into {0, 2^16},
  //          then reinterpret cast into int16_t
  const float float_value = (static_cast<float>(CUDART_PI_F) + atan2f(y, x)) * Velo::Tools::convert_factor;
  const uint16_t uint16_value = static_cast<uint16_t>(float_value);
  const int16_t* int16_pointer = reinterpret_cast<const int16_t*>(&uint16_value);
  return *int16_pointer;
}

template<
  typename VeloContainer,
  typename Offsets,
  typename ClusterNum,
  typename TotalNumberOfClusters,
  typename Arguments>
__host__ inline void print_velo_clusters(Arguments arguments)
{
  // Prints the velo clusters
  std::vector<char> a(size<VeloContainer>(arguments));
  std::vector<uint> offsets_estimated_input_size(size<Offsets>(arguments));
  std::vector<uint> module_cluster_num(size<ClusterNum>(arguments));

  cudaCheck(
    cudaMemcpy(a.data(), begin<VeloContainer>(arguments), size<VeloContainer>(arguments), cudaMemcpyDeviceToHost));
  cudaCheck(cudaMemcpy(
    offsets_estimated_input_size.data(), begin<Offsets>(arguments), size<Offsets>(arguments), cudaMemcpyDeviceToHost));
  cudaCheck(cudaMemcpy(
    module_cluster_num.data(), begin<ClusterNum>(arguments), size<ClusterNum>(arguments), cudaMemcpyDeviceToHost));

  const auto velo_cluster_container = Velo::ConstClusters {a.data(), value<TotalNumberOfClusters>(arguments)};
  for (uint i = 0; i < Velo::Constants::n_module_pairs; ++i) {
    const auto module_hit_start = offsets_estimated_input_size[i];
    const auto module_hit_num = module_cluster_num[i];

    std::cout << "Module pair " << i << ":\n";
    for (uint hit_number = 0; hit_number < module_hit_num; ++hit_number) {
      const auto hit_index = module_hit_start + hit_number;
      std::cout << " " << velo_cluster_container.x(hit_index) << ", " << velo_cluster_container.y(hit_index) << ", "
                << velo_cluster_container.z(hit_index) << ", " << velo_cluster_container.id(hit_index) << "\n";
    }
    std::cout << "\n";
  }
}

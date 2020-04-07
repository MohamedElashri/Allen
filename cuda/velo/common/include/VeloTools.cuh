#pragma once

#include "CudaCommon.h"
#include "CudaMathConstants.h"

namespace Velo {
  namespace Tools {
    constexpr float max_input_value = 2.f * static_cast<float>(CUDART_PI_F);
    constexpr float max_output_value = 65536.f;
    constexpr float convert_factor = max_output_value / max_input_value;
    constexpr int16_t shift_value = static_cast<int16_t>(65536 / 2);
  }
}

/**
 * @brief Calculates the hit phi in a int16 format.
 * @details The range of the atan2 function is mapped onto the range of the int16,
 *          such that for two hit phis in this format, the difference is stable
 *          regardless of the values.
 */
__device__ inline int16_t hit_phi_16(const float x, const float y, const bool side = 0) {
  // We have to convert the range {-PI, +PI} into {-2^15, (2^15 - 1)}
  // Simpler: Convert {0, 2 PI} into {0, 2^16},
  //          then reinterpret cast into int16_t

  const float float_value = (static_cast<float>(CUDART_PI_F) + atan2f(y, x)) * Velo::Tools::convert_factor;
  const uint16_t uint16_value = static_cast<uint16_t>(float_value) + (side ? Velo::Tools::shift_value : 0);
  const int16_t* int16_pointer = reinterpret_cast<const int16_t*>(&uint16_value);

  return *int16_pointer;
}
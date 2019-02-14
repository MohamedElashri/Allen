#pragma once

namespace LookingForward {
  constexpr float dx_slope = 4000000f;
  constexpr float dx_min = 1000f;
  constexpr float max_window_layer0 = 1000f;
  constexpr float max_window_layer1 = 10f;
  constexpr float max_window_layer2 = 10f;
  constexpr float max_window_layer3 = 80f;
  constexpr float chi2_cut = 100f;

  /**
   * Station where seeding starts from
   */
  constexpr uint seeding_station = 3;
} // namespace LookingForward

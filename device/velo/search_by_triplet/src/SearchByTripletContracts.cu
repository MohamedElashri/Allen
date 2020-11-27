#include "SearchByTriplet.cuh"
#include <catch2/catch_test_macros.hpp>

void velo_search_by_triplet::cluster_container_is_sorted::operator()(
  const ArgumentReferences<Parameters>&,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context&)
{
  constexpr float velo_cluster_min_x = -100.f;
  constexpr float velo_cluster_max_x = 100.f;
  constexpr float velo_cluster_min_y = -100.f;
  constexpr float velo_cluster_max_y = 100.f;
  constexpr float min_value_phi = -10.f;

  using VeloContainer = Parameters::dev_sorted_velo_cluster_container_t;
  using Offsets = Parameters::dev_offsets_estimated_input_size_t;
  using ClusterNum = Parameters::dev_module_cluster_num_t;

  std::vector<char> a(size<VeloContainer>(arguments));
  std::vector<unsigned> offsets_estimated_input_size(size<Offsets>(arguments));
  std::vector<unsigned> module_cluster_num(size<ClusterNum>(arguments));
  std::vector<float> hit_phi(size<Parameters::dev_hit_phi_t>(arguments));

  Allen::memcpy(
    a.data(),
    data<VeloContainer>(arguments),
    size<VeloContainer>(arguments) * sizeof(VeloContainer::type),
    Allen::memcpyDeviceToHost);
  Allen::memcpy(
    offsets_estimated_input_size.data(),
    data<Offsets>(arguments),
    size<Offsets>(arguments) * sizeof(Offsets::type),
    Allen::memcpyDeviceToHost);
  Allen::memcpy(
    module_cluster_num.data(),
    data<ClusterNum>(arguments),
    size<ClusterNum>(arguments) * sizeof(ClusterNum::type),
    Allen::memcpyDeviceToHost);
  Allen::memcpy(
    hit_phi.data(),
    data<Parameters::dev_hit_phi_t>(arguments),
    size<Parameters::dev_hit_phi_t>(arguments) * sizeof(Parameters::dev_hit_phi_t::type),
    Allen::memcpyDeviceToHost);

  // Condition to check
  bool hit_phi_is_sorted = true;
  bool x_greater_than_min_value = true;
  bool x_lower_than_max_value = true;
  bool y_greater_than_min_value = true;
  bool y_lower_than_max_value = true;

  const auto velo_cluster_container =
    Velo::ConstClusters {a.data(), first<Parameters::host_total_number_of_velo_clusters_t>(arguments)};
  for (unsigned event_number = 0; event_number < first<Parameters::host_number_of_events_t>(arguments);
       ++event_number) {
    const auto event_number_of_hits =
      offsets_estimated_input_size[(event_number + 1) * Velo::Constants::n_module_pairs] -
      offsets_estimated_input_size[event_number * Velo::Constants::n_module_pairs];
    if (event_number_of_hits > 0) {
      for (unsigned i = 0; i < Velo::Constants::n_module_pairs; ++i) {
        const auto module_hit_start = offsets_estimated_input_size[event_number * Velo::Constants::n_module_pairs + i];
        const auto module_hit_num = module_cluster_num[event_number * Velo::Constants::n_module_pairs + i];

        float previous_hit_phi = min_value_phi;
        for (unsigned hit_number = 0; hit_number < module_hit_num; ++hit_number) {
          const auto hit_index = module_hit_start + hit_number;
          hit_phi_is_sorted &= hit_phi[hit_index] >= previous_hit_phi;
          previous_hit_phi = hit_phi[hit_index];

          x_greater_than_min_value &= velo_cluster_container.x(hit_index) > velo_cluster_min_x;
          x_lower_than_max_value &= velo_cluster_container.x(hit_index) < velo_cluster_max_x;
          y_greater_than_min_value &= velo_cluster_container.y(hit_index) > velo_cluster_min_y;
          y_lower_than_max_value &= velo_cluster_container.y(hit_index) < velo_cluster_max_y;
        }
      }
    }
  }

  TEST_CASE("Require that dev_hit_phi_t be sorted per module pair", "[single-file]") { REQUIRE(hit_phi_is_sorted); }

  TEST_CASE("Require that x and y be in reasonable range", "[single-file]")
  {
    REQUIRE(x_greater_than_min_value);
    REQUIRE(x_lower_than_max_value);
    REQUIRE(y_greater_than_min_value);
    REQUIRE(y_lower_than_max_value);
  }
}

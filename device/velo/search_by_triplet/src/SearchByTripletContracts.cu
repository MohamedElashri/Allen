#include "SearchByTriplet.cuh"

void velo_search_by_triplet::cluster_container_checks::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context&) const
{
  constexpr float velo_cluster_min_x = -100.f;
  constexpr float velo_cluster_max_x = 100.f;
  constexpr float velo_cluster_min_y = -100.f;
  constexpr float velo_cluster_max_y = 100.f;

  auto sorted_velo_cluster_container = make_vector<Parameters::dev_sorted_velo_cluster_container_t>(arguments);
  auto offsets_estimated_input_size = make_vector<Parameters::dev_offsets_estimated_input_size_t>(arguments);
  auto module_cluster_num = make_vector<Parameters::dev_module_cluster_num_t>(arguments);
  auto hit_phi = make_vector<Parameters::dev_hit_phi_t>(arguments);

  // Condition to check
  bool hit_phi_is_sorted = true;
  bool x_greater_than_min_value = true;
  bool x_lower_than_max_value = true;
  bool y_greater_than_min_value = true;
  bool y_lower_than_max_value = true;

  const auto velo_container_view =
    Velo::ConstClusters {sorted_velo_cluster_container.data(), first<Parameters::host_total_number_of_velo_clusters_t>(arguments)};
  for (unsigned event_number = 0; event_number < first<Parameters::host_number_of_events_t>(arguments);
       ++event_number) {
    const auto event_number_of_hits =
      offsets_estimated_input_size[(event_number + 1) * Velo::Constants::n_module_pairs] -
      offsets_estimated_input_size[event_number * Velo::Constants::n_module_pairs];
    if (event_number_of_hits > 0) {
      for (unsigned i = 0; i < Velo::Constants::n_module_pairs; ++i) {
        const auto module_hit_start = offsets_estimated_input_size[event_number * Velo::Constants::n_module_pairs + i];
        const auto module_hit_num = module_cluster_num[event_number * Velo::Constants::n_module_pairs + i];

        if (module_hit_num > 0) {
          auto previous_hit_phi = hit_phi[module_hit_start];
          for (unsigned hit_number = 0; hit_number < module_hit_num; ++hit_number) {
            const auto hit_index = module_hit_start + hit_number;
            hit_phi_is_sorted &= hit_phi[hit_index] >= previous_hit_phi;
            previous_hit_phi = hit_phi[hit_index];

            x_greater_than_min_value &= velo_container_view.x(hit_index) > velo_cluster_min_x;
            x_lower_than_max_value &= velo_container_view.x(hit_index) < velo_cluster_max_x;
            y_greater_than_min_value &= velo_container_view.y(hit_index) > velo_cluster_min_y;
            y_lower_than_max_value &= velo_container_view.y(hit_index) < velo_cluster_max_y;
          }
        }
      }
    }
  }

  require(hit_phi_is_sorted, "Require that dev_hit_phi_t be sorted per module pair");
  require(x_greater_than_min_value, "Require that x be greater than min value");
  require(x_lower_than_max_value, "Require that x be lower than max value");
  require(y_greater_than_min_value, "Require that y be greater than min value");
  require(y_lower_than_max_value, "Require that y be lower than max value");
}

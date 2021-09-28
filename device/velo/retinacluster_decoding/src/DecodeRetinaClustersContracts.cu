/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DecodeRetinaClusters.cuh"
#include "LHCbID.h"

void decode_retinaclusters::cluster_container_checks::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context&) const
{
  constexpr float velo_cluster_min_x = -100.f;
  constexpr float velo_cluster_max_x = 100.f;
  constexpr float velo_cluster_min_y = -100.f;
  constexpr float velo_cluster_max_y = 100.f;

  const auto velo_cluster_container = make_vector<Parameters::dev_velo_cluster_container_t>(arguments);
  const auto offsets_module_pair_cluster = make_vector<Parameters::dev_offsets_module_pair_cluster_t>(arguments);
  const auto module_cluster_num = make_vector<Parameters::dev_module_cluster_num_t>(arguments);

  // Condition to check
  bool x_greater_than_min_value = true;
  bool x_lower_than_max_value = true;
  bool y_greater_than_min_value = true;
  bool y_lower_than_max_value = true;
  bool valid_id_hit = true;

  const auto velo_container_view = Velo::ConstClusters {
    velo_cluster_container.data(), first<Parameters::host_total_number_of_velo_clusters_t>(arguments)};
  for (unsigned event_number = 0; event_number < first<Parameters::host_number_of_events_t>(arguments);
       ++event_number) {
    const auto event_number_of_hits =
      offsets_module_pair_cluster[(event_number + 1) * Velo::Constants::n_module_pairs] -
      offsets_module_pair_cluster[event_number * Velo::Constants::n_module_pairs];
    if (event_number_of_hits > 0) {
      for (unsigned i = 0; i < Velo::Constants::n_module_pairs; ++i) {
        const auto module_hit_start = offsets_module_pair_cluster[event_number * Velo::Constants::n_module_pairs + i];
        const auto module_hit_num = module_cluster_num[event_number * Velo::Constants::n_module_pairs + i];

        if (module_hit_num > 0) {
          for (unsigned hit_number = 0; hit_number < module_hit_num; ++hit_number) {
            const auto hit_index = module_hit_start + hit_number;

            valid_id_hit = lhcb_id::is_velo(velo_container_view.id(hit_index));

            x_greater_than_min_value &= velo_container_view.x(hit_index) > velo_cluster_min_x;
            x_lower_than_max_value &= velo_container_view.x(hit_index) < velo_cluster_max_x;
            y_greater_than_min_value &= velo_container_view.y(hit_index) > velo_cluster_min_y;
            y_lower_than_max_value &= velo_container_view.y(hit_index) < velo_cluster_max_y;
          }
        }
      }
    }
  }

  require(x_greater_than_min_value, "Require that x be greater than min value");
  require(x_lower_than_max_value, "Require that x be lower than max value");
  require(y_greater_than_min_value, "Require that y be greater than min value");
  require(y_lower_than_max_value, "Require that y be lower than max value");
  require(valid_id_hit, "Require that every hit id is valid");
}
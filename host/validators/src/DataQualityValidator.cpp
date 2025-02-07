/*****************************************************************************\
* (c) Copyright 2023-2024 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "DataQualityValidator.h"
#include "VeloDefinitions.cuh"
#include "SciFiDefinitions.cuh"
#include "MuonDefinitions.cuh"
#include "KinUtils.cuh"

INSTANTIATE_ALGORITHM(data_quality_validator_velo::data_quality_validator_velo_t)

void data_quality_validator_velo::data_quality_validator_velo_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  if (m_enable_tupling.value()) output_monitor(arguments, runtime_options, context);
}

void data_quality_validator_velo::data_quality_validator_velo_t::output_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Allen::Context& context) const
{
  auto handler = runtime_options.root_service->handle(name());

  // --> Velo states
  auto tree = handler.tree("velo_states");
  const auto event_velo_tracks_offsets = make_host_buffer<dev_offsets_velo_tracks_t>(arguments, context);
  const auto event_list = make_host_buffer<dev_event_list_t>(arguments, context);
  const auto offsets_all_velo_tracks = make_host_buffer<dev_offsets_all_velo_tracks_t>(arguments, context);
  const auto offsets_velo_track_hit_number = make_host_buffer<dev_offsets_velo_track_hit_number_t>(arguments, context);
  const auto velo_track_hits = make_host_buffer<dev_velo_track_hits_t>(arguments, context);
  const auto velo_states_base = make_host_buffer<dev_velo_kalman_states_t>(arguments, context);

  float tx, ty, rho, eta, phi;
  handler.branch(tree, "tx", tx);
  handler.branch(tree, "ty", ty);
  handler.branch(tree, "rho", rho);
  handler.branch(tree, "eta", eta);
  handler.branch(tree, "phi", phi);

  int n_hits;
  handler.branch(tree, "n_hits_per_track", n_hits);

  for (size_t i = 0; i < event_list.size(); ++i) {
    const auto evnum = event_list[i];
    const auto velo_tracks_offset = event_velo_tracks_offsets[evnum];
    Velo::Consolidated::ConstTracks velo_tracks {offsets_all_velo_tracks.data(),
                                                 offsets_velo_track_hit_number.data(),
                                                 evnum,
                                                 first<host_number_of_events_t>(arguments)};
    unsigned n_velo_states = velo_tracks.number_of_tracks(evnum);

    Velo::Consolidated::ConstStates velo_states {velo_states_base.data(), velo_tracks.total_number_of_tracks()};

    for (unsigned i_track = 0; i_track < n_velo_states; i_track++) {
      const auto state = velo_states.get(velo_tracks_offset + i_track);
      tx = state.tx();
      ty = state.ty();
      const float slope2 = tx * tx + ty * ty;
      // Normalised transverse momentum
      rho = std::sqrt(slope2);
      eta = eta_from_rho(rho); // From KinUtils.cuh
      phi = atan2f(ty, tx);

      n_hits = velo_tracks.number_of_hits(i_track);
      tree->Fill();
    }
  }
}
/*---------------------------------------------------------------------------------------------*/
INSTANTIATE_ALGORITHM(data_quality_validator_pv::data_quality_validator_pv_t)

void data_quality_validator_pv::data_quality_validator_pv_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  if (m_enable_tupling.value()) output_monitor(arguments, runtime_options, context);
}

void data_quality_validator_pv::data_quality_validator_pv_t::output_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Allen::Context& context) const
{
  auto handler = runtime_options.root_service->handle(name());

  // --> PVs
  auto tree = handler.tree("PVs");
  auto eventTree = handler.tree("PV_event");
  auto PVpairsTree = handler.tree("PV_pairs");
  const auto PVs = make_host_buffer<dev_multi_fit_vertices_t>(arguments, context);
  const auto n_pvs = make_host_buffer<dev_number_of_multi_fit_vertices_t>(arguments, context);
  const auto event_list = make_host_buffer<dev_event_list_t>(arguments, context);
  float pv_x, pv_y, pv_z, pv_chi2, pv_ndof, pv_nTracks;
  float pv_cov[3][3] = {{0}};
  handler.branch(tree, "pv_x", pv_x);
  handler.branch(tree, "pv_y", pv_y);
  handler.branch(tree, "pv_z", pv_z);
  handler.branch(tree, "pv_chi2", pv_chi2);
  handler.branch(tree, "pv_ndof", pv_ndof);
  handler.branch(tree, "pv_nTracks", pv_nTracks);
  handler.branch(tree, "pv_x", pv_x);
  handler.branch(tree, "cov00", pv_cov[0][0]);
  handler.branch(tree, "cov10", pv_cov[1][0]);
  handler.branch(tree, "cov11", pv_cov[1][1]);
  handler.branch(tree, "cov20", pv_cov[2][0]);
  handler.branch(tree, "cov21", pv_cov[2][1]);
  handler.branch(tree, "cov22", pv_cov[2][2]);

  int nPVs;
  float PVdistance_min, PVdistance_max, PVdistance_mean;
  handler.branch(eventTree, "n_pvs", nPVs);
  handler.branch(eventTree, "PVdistance_min", PVdistance_min);
  handler.branch(eventTree, "PVdistance_max", PVdistance_max);
  handler.branch(eventTree, "PVdistance_mean", PVdistance_mean);

  // Fill with the Delta Z distance of each pair of PVs
  float PVdelta_z;
  handler.branch(PVpairsTree, "PVdelta_z", PVdelta_z);

  for (unsigned i = 0; i < event_list.size(); ++i) {
    const auto evnum = event_list[i];
    nPVs = *(n_pvs.data() + evnum);
    // PVs are not stored densely as is the case for e.g. long tracks
    // Instead they are saved in units of PV::max_number_vertices per event
    // Thus the offset is calculated using this number instead of
    // something like dev_pv_offsets
    const unsigned pv_offset = evnum * PV::max_number_vertices;

    // If there's 1 or fewer PVs, there's no distance between them!
    // - set a dummy number for this
    if (nPVs <= 1) {
      PVdistance_max = -99.f;
      PVdistance_min = -99.f;
      PVdistance_mean = -99.f;
    }
    else { // Otherwise reset the values ready for the upcoming loop
      PVdistance_mean = 0.f;
      PVdistance_max = 0.f;
      PVdistance_min = std::numeric_limits<float>::infinity();
    }

    for (int i_vertex = 0; i_vertex < nPVs; i_vertex++) {
      const auto pv = PVs[i_vertex + pv_offset];
      pv_x = pv.position.x;
      pv_y = pv.position.y;
      pv_z = pv.position.z;
      pv_chi2 = pv.chi2;
      pv_ndof = pv.ndof;
      pv_nTracks = pv.nTracks;
      pv_cov[0][0] = pv.cov00;
      pv_cov[1][0] = pv.cov10;
      pv_cov[1][1] = pv.cov11;
      pv_cov[2][0] = pv.cov20;
      pv_cov[2][1] = pv.cov21;
      pv_cov[2][2] = pv.cov22;
      tree->Fill();

      // Now compare this vertex to all previous ones and calculate their distances
      if (nPVs > 1) {
        for (int j = 0; j < i_vertex; ++j) {
          const auto otherVertex = PVs[j + pv_offset];
          const float delta_x = otherVertex.position.x - pv_x;
          const float delta_y = otherVertex.position.y - pv_y;
          const float delta_z = otherVertex.position.z - pv_z;
          const float delta_pos = std::sqrt(delta_x * delta_x + delta_y * delta_y + delta_z * delta_z);

          if (delta_pos > PVdistance_max) {
            PVdistance_max = delta_pos;
          }
          if (delta_pos < PVdistance_min) {
            PVdistance_min = delta_pos;
          }
          PVdistance_mean += delta_pos;

          // Fill with each pair of points
          PVdelta_z = delta_z;
          PVpairsTree->Fill();
        }
      }
    }
    // finally, divide by nPVs to for the mean
    if (nPVs > 1) {
      PVdistance_mean /= nPVs;
    }
    eventTree->Fill();
  }
}
/*---------------------------------------------------------------------------------------------*/

INSTANTIATE_ALGORITHM(data_quality_validator_occupancy::data_quality_validator_occupancy_t)

void data_quality_validator_occupancy::data_quality_validator_occupancy_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  if (m_enable_tupling.value()) output_monitor(arguments, runtime_options, context);
}

void data_quality_validator_occupancy::data_quality_validator_occupancy_t::output_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Allen::Context& context) const
{
  auto handler = runtime_options.root_service->handle(name());

  // --> Occupancy
  auto eventTree = handler.tree("occupancy");
  const auto scifi_tracks_offsets = make_host_buffer<dev_scifi_hit_offsets_t>(arguments, context);
  const auto scifi_seeds = make_host_buffer<dev_scifi_seedsXZ_t>(arguments, context);
  const auto velo_offsets_eis = make_host_buffer<dev_velo_offsets_estimated_input_size_t>(arguments, context);
  const auto event_velo_tracks_offsets = make_host_buffer<dev_offsets_velo_tracks_t>(arguments, context);
  const auto ecal_clusters = make_host_buffer<dev_ecal_clusters_offsets_t>(arguments, context);
  const auto muon_offsets = make_host_buffer<dev_station_ocurrences_offset_t>(arguments, context);
  const auto event_list = make_host_buffer<dev_event_list_t>(arguments, context);

  int n_scifi_hits, n_scifi_xz_seeds, n_velo_hits, n_velo_tracks, n_ecal_clusters, n_muon_hits;
  handler.branch(eventTree, "n_scifi_hits", n_scifi_hits);
  handler.branch(eventTree, "n_scifi_xz_seeds", n_scifi_xz_seeds);
  handler.branch(eventTree, "n_velo_hits", n_velo_hits);
  handler.branch(eventTree, "n_velo_tracks", n_velo_tracks);
  handler.branch(eventTree, "n_ecal_clusters", n_ecal_clusters);
  handler.branch(eventTree, "n_muon_hits", n_muon_hits);

  constexpr std::array<int, 4> st_order {
    Muon::Constants::M5, Muon::Constants::M4, Muon::Constants::M3, Muon::Constants::M2};

  for (size_t i = 0; i < event_list.size(); ++i) {

    const auto evnum = event_list[i];
    SciFi::ConstHitCount scifi_hit_count {scifi_tracks_offsets.data(), evnum};
    n_scifi_hits = scifi_hit_count.event_number_of_hits();
    n_scifi_xz_seeds = scifi_seeds.data()[evnum];

    const unsigned* module_pair_hit_start = velo_offsets_eis.data() + evnum * Velo::Constants::n_module_pairs;
    const unsigned event_hit_start = module_pair_hit_start[0];
    n_velo_hits = module_pair_hit_start[Velo::Constants::n_module_pairs] - event_hit_start;

    const auto velo_tracks_offset = event_velo_tracks_offsets[evnum];
    n_velo_tracks = event_velo_tracks_offsets[evnum + 1] - velo_tracks_offset;

    n_ecal_clusters = ecal_clusters.data()[evnum + 1] - ecal_clusters.data()[evnum];

    const auto station_ocurrences_offset = muon_offsets.data() + evnum * Muon::Constants::n_stations;
    n_muon_hits = 0;
    for (const int& station : st_order) {
      const auto ocurrences_offset = station_ocurrences_offset[st_order[station]];
      n_muon_hits += station_ocurrences_offset[st_order[station] + 1] - ocurrences_offset;
    }

    eventTree->Fill();
  }
}

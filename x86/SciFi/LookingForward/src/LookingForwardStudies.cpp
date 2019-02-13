#include "LookingForwardStudies.h"

#define WITH_ROOT 1

#ifdef WITH_ROOT
#include "TH1D.h"
#include "TFile.h"
#include "TTree.h"
#endif

int looking_forward_studies(
  const uint* host_scifi_hits,
  const uint* host_scifi_hit_count,
  const char* host_scifi_geometry,
  const std::array<float, 9>& host_inv_clus_res,
  const uint* host_velo_tracks_atomics,
  const uint* host_velo_track_hit_number,
  const char* host_velo_states,
  const int* host_atomics_ut,
  const uint* host_ut_track_hit_number,
  const float* host_ut_qop,
  const float* host_ut_x,
  const float* host_ut_tx,
  const float* host_ut_z,
  const uint* host_ut_track_velo_indices,
  const std::vector<std::vector<std::vector<uint32_t>>>& scifi_ids_ut_tracks,
  const std::vector<std::vector<float>>& p_events,
  const uint number_of_events)
{
#ifdef WITH_ROOT
  // Histograms only for checking and debugging
  TFile* f = new TFile("../output/scifi.root", "RECREATE");
  TTree* t_scifi_hits = new TTree("scifi_hits", "scifi_hits");
  TTree* t_extrap_T1 = new TTree("extrap_T1", "extrap_T1");
  TTree* t_extrap_T3 = new TTree("extrap_T3", "extrap_T3");
  TTree* t_track_candidates = new TTree("track_candidates", "track_candidates");
  TTree* t_good_tracks = new TTree("good_tracks", "good_tracks");
  TTree* t_ut_tracks = new TTree("ut_tracks", "ut_tracks");
  TTree* t_other_x_layer_t1 = new TTree("other_x_layer_T1", "other_x_layer_T1");
  TTree* t_other_x_layer_t3 = new TTree("other_x_layer_T3", "other_x_layer_T3");

  uint planeCode, LHCbID;
  float x0, z0, w, dxdy, dzdy, yMin, yMax;
  float qop;
  int n_tracks;
  float state_x, state_y, state_z, state_tx, state_ty;
  //  float xf_t1, yf_t1, txf_t1, tyf_t1, der_xf_qop_t1, qop_update_t1;
  //  float res_x_0_t1, res_x_3_t1, dx_t1, x_extrap_t1, true_x_t1, res_x_other_t1, true_z_t1;
  //  float true_x_t1_other;
  float UT_x, UT_y, UT_z, UT_tx, UT_ty, ut_qop;
  float velo_x_extrap, velo_tx;
  //  int n_hits_in_window_0_t1 = 0, n_hits_in_window_0_t1_true_p = 0, n_hits_in_window_3_t1 = 0;
  //  int n_hits_in_zone_t1 = 0, n_hits_in_window_other_t1 = 0, n_hits_in_window_other_t1_tx = 0;
  //  float p_diff_before_update_t1, p_diff_after_update_t1, p_diff_before_after_t1, p_resolution_after_update_t1;
  //  float qop_diff_before_update_t1, qop_diff_after_update_t1, qop_diff_before_after_t1,
  //  qop_resolution_after_update_t1; float tx_x_hits_t1, res_x_u_t1, res_x_v_t1, res_x_u_slope_t1, res_x_v_slope_t1;
  float res_x_T2_0, res_x_T2_3, res_x_T3_0, res_x_T3_3;

  float xf_t3, yf_t3, txf_t3, tyf_t3, der_xf_qop_t3, qop_update_t3, x_mag, y_mag;
  float res_x_0_t3, res_x_3_t3, dx_t3, x_extrap_t3, true_x_t3, res_x_other_t3;

  float delta_y, delta_y_good;
  int num_candidates, good_hits;
  ;
  int n_hits_in_window_0_t3 = 0, n_hits_in_window_0_t3_true_p = 0, n_hits_in_window_3_t3 = 0;
  int n_hits_in_zone_t3 = 0, n_hits_in_window_other_t3 = 0;
  float p_diff_before_update_t3, p_diff_after_update_t3, p_resolution_after_update_t3;
  float qop_diff_before_update_t3, qop_diff_after_update_t3, qop_diff_before_after_t3, qop_resolution_after_update_t3;

  bool t1_extrap_worked, t3_extrap_worked, isLong;
  float p_true;
  bool match_t1, match_t3, match_t1_other, match_t3_other, match_t1_u, match_t1_v;
  bool match_T2_0, match_T2_3, match_T3_0, match_T3_3;

  t_scifi_hits->Branch("planeCode", &planeCode);
  t_scifi_hits->Branch("LHCbID", &LHCbID);
  t_scifi_hits->Branch("x0", &x0);
  t_scifi_hits->Branch("z0", &z0);
  t_scifi_hits->Branch("w", &w);
  t_scifi_hits->Branch("dxdy", &dxdy);
  t_scifi_hits->Branch("dzdy", &dzdy);
  t_scifi_hits->Branch("yMin", &yMin);
  t_scifi_hits->Branch("yMax", &yMax);

  //  t_extrap_T1->Branch("xf", &xf_t1);
  //  t_extrap_T1->Branch("yf", &yf_t1);
  //  t_extrap_T1->Branch("txf", &txf_t1);
  //  t_extrap_T1->Branch("tyf", &tyf_t1);
  //  t_extrap_T1->Branch("der_xf_qop", &der_xf_qop_t1);
  //  t_extrap_T1->Branch("res_x_0", &res_x_0_t1);
  //  t_extrap_T1->Branch("res_x_other", &res_x_other_t1);
  //  t_extrap_T1->Branch("true_x", &true_x_t1);
  //  t_extrap_T1->Branch("true_z", &true_z_t1);
  //  t_extrap_T1->Branch("x_extrap", &x_extrap_t1);
  //  t_extrap_T1->Branch("dx", &dx_t1);
  //  t_extrap_T1->Branch("qop_update", &qop_update_t1);
  //  t_extrap_T1->Branch("p_diff_before_update", &p_diff_before_update_t1);
  //  t_extrap_T1->Branch("p_diff_after_update", &p_diff_after_update_t1);
  //  t_extrap_T1->Branch("p_resolution_after_update", &p_resolution_after_update_t1);
  //  t_extrap_T1->Branch("qop_diff_before_update", &qop_diff_before_update_t1);
  //  t_extrap_T1->Branch("qop_diff_after_update", &qop_diff_after_update_t1);
  //  t_extrap_T1->Branch("qop_resolution_after_update", &qop_resolution_after_update_t1);
  //  t_extrap_T1->Branch("n_hits_in_window_0", &n_hits_in_window_0_t1);
  //  t_extrap_T1->Branch("n_hits_in_zone", &n_hits_in_zone_t1);
  //  t_extrap_T1->Branch("isLong", &isLong);
  //  t_extrap_T1->Branch("p_true", &p_true);
  //  t_extrap_T1->Branch("match", &match_t1);
  //  t_extrap_T1->Branch("match_other", &match_t1_other);
  //  t_extrap_T1->Branch("ut_qop", &ut_qop);
  //  t_extrap_T1->Branch("tx_x_hits", &tx_x_hits_t1);
  //  t_extrap_T1->Branch("res_x_u", &res_x_u_t1);
  //  t_extrap_T1->Branch("res_x_u_slope", &res_x_u_slope_t1);
  //  t_extrap_T1->Branch("match_u", &match_t1_u);
  //  t_extrap_T1->Branch("res_x_v", &res_x_v_t1);
  //  t_extrap_T1->Branch("res_x_v_slope", &res_x_v_slope_t1);
  //  t_extrap_T1->Branch("match_v", &match_t1_v);
  //  t_extrap_T1->Branch("match_T2_0", &match_T2_0);
  //  t_extrap_T1->Branch("match_T2_3", &match_T2_3);
  //  t_extrap_T1->Branch("res_x_T2_0", &res_x_T2_0);
  //  t_extrap_T1->Branch("res_x_T2_3", &res_x_T2_3);
  //  t_extrap_T1->Branch("match_T3_0", &match_T3_0);
  //  t_extrap_T1->Branch("match_T3_3", &match_T3_3);
  //  t_extrap_T1->Branch("res_x_T3_0", &res_x_T3_0);
  //  t_extrap_T1->Branch("res_x_T3_3", &res_x_T3_3);

  t_extrap_T3->Branch("xf", &xf_t3);
  t_extrap_T3->Branch("yf", &yf_t3);
  t_extrap_T3->Branch("txf", &txf_t3);
  t_extrap_T3->Branch("tyf", &tyf_t3);
  t_extrap_T3->Branch("der_xf_qop", &der_xf_qop_t3);
  t_extrap_T3->Branch("res_x_0", &res_x_0_t3);
  t_extrap_T3->Branch("res_x_other", &res_x_other_t3);
  t_extrap_T3->Branch("true_x", &true_x_t3);
  t_extrap_T3->Branch("x_extrap", &x_extrap_t3);
  t_extrap_T3->Branch("dx", &dx_t3);
  t_extrap_T3->Branch("qop_update", &qop_update_t3);
  t_extrap_T3->Branch("p_diff_before_update", &p_diff_before_update_t3);
  t_extrap_T3->Branch("p_diff_after_update", &p_diff_after_update_t3);
  t_extrap_T3->Branch("p_resolution_after_update", &p_resolution_after_update_t3);
  t_extrap_T3->Branch("qop_diff_before_update", &qop_diff_before_update_t3);
  t_extrap_T3->Branch("qop_diff_after_update", &qop_diff_after_update_t3);
  t_extrap_T3->Branch("qop_resolution_after_update", &qop_resolution_after_update_t3);
  t_extrap_T3->Branch("n_hits_in_window_0", &n_hits_in_window_0_t3);
  t_extrap_T3->Branch("n_hits_in_zone", &n_hits_in_zone_t3);
  t_extrap_T3->Branch("isLong", &isLong);
  t_extrap_T3->Branch("p_true", &p_true);
  t_extrap_T3->Branch("ut_qop", &ut_qop);
  t_extrap_T3->Branch("UT_tx", &UT_tx);
  t_extrap_T3->Branch("match", &match_t3);
  t_extrap_T3->Branch("match_other", &match_t3_other);
  t_extrap_T3->Branch("x_mag", &x_mag);
  t_extrap_T3->Branch("y_mag", &y_mag);

  t_track_candidates->Branch("delta_y", &delta_y);
  t_track_candidates->Branch("num_candidates", &num_candidates);
  t_track_candidates->Branch("good_hits", &good_hits);
  t_track_candidates->Branch("UT_qop", &ut_qop);

  t_good_tracks->Branch("delta_y", &delta_y);
  t_good_tracks->Branch("num_candidates", &num_candidates);
  t_good_tracks->Branch("good_hits", &good_hits);
  t_good_tracks->Branch("UT_qop", &ut_qop);

  t_ut_tracks->Branch("ut_x", &UT_x);
  t_ut_tracks->Branch("ut_y", &UT_y);
  t_ut_tracks->Branch("ut_z", &UT_z);
  t_ut_tracks->Branch("ut_tx", &UT_tx);
  t_ut_tracks->Branch("ut_ty", &UT_ty);
  t_ut_tracks->Branch("velo_x_extrap", &velo_x_extrap);
  t_ut_tracks->Branch("velo_tx", &velo_tx);
  t_ut_tracks->Branch("ut_qop", &ut_qop);
  t_ut_tracks->Branch("t1_extrap_worked", &t1_extrap_worked);
  t_ut_tracks->Branch("t3_extrap_worked", &t3_extrap_worked);
  t_ut_tracks->Branch("isLong", &isLong);
  t_ut_tracks->Branch("p_true", &p_true);

  //  t_other_x_layer_t1->Branch("n_hits_in_window_other", &n_hits_in_window_other_t1);
  //  t_other_x_layer_t1->Branch("n_hits_in_window_other_tx", &n_hits_in_window_other_t1_tx);

  t_other_x_layer_t3->Branch("n_hits_in_window_other", &n_hits_in_window_other_t3);
#endif

  int n_veloUT_tracks = 0;
  int n_extrap_T1 = 0;
  int n_extrap_T3 = 0;

  for (uint i_event = 0; i_event < number_of_events; ++i_event) {
      // Velo consolidated types
      const Velo::Consolidated::Tracks velo_tracks {
          (uint*) host_velo_tracks_atomics, (uint*) host_velo_track_hit_number, i_event, number_of_events};
      const uint velo_event_tracks_offset = velo_tracks.tracks_offset(i_event);
      const Velo::Consolidated::States velo_states {(char*) host_velo_states, velo_tracks.total_number_of_tracks};

      // UT consolidated types
      UT::Consolidated::Tracks ut_tracks {(uint*) host_atomics_ut,
                  (uint*) host_ut_track_hit_number,
                  (float*) host_ut_qop,
                  (uint*) host_ut_track_velo_indices,
                  i_event,
                  number_of_events};
      const int n_veloUT_tracks_event = ut_tracks.number_of_tracks(i_event);
      const int ut_event_tracks_offset = ut_tracks.tracks_offset(i_event);
      n_veloUT_tracks += n_veloUT_tracks_event;

      // SciFi non-consolidated types
      const uint total_number_of_hits = host_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
      SciFi::HitCount scifi_hit_count {(uint32_t*) host_scifi_hit_count, i_event};

      const SciFi::SciFiGeometry scifi_geometry(host_scifi_geometry);

      SciFi::Hits scifi_hits(
                  (uint*) host_scifi_hits,
                  total_number_of_hits,
                  &scifi_geometry,
                  reinterpret_cast<const float*>(host_inv_clus_res.data()));

#ifdef WITH_ROOT
      // store hit variables in tree
      for (size_t zone = 0; zone < SciFi::Constants::n_zones; zone++) {
          const auto zone_offset = scifi_hit_count.zone_offset(zone);
          for (size_t hit = 0; hit < scifi_hit_count.zone_number_of_hits(zone); hit++) {
              const auto hit_offset = zone_offset + hit;

              planeCode = scifi_hits.planeCode(hit_offset);
              LHCbID = scifi_hits.LHCbID(hit_offset);
              x0 = scifi_hits.x0[hit_offset];
              z0 = scifi_hits.z0[hit_offset];
              w = scifi_hits.w(hit_offset);
              dxdy = scifi_hits.dxdy(hit_offset);
              dzdy = scifi_hits.dzdy(hit_offset);
              yMin = scifi_hits.yMin(hit_offset);
              yMax = scifi_hits.yMax(hit_offset);
              t_scifi_hits->Fill();
          }
      }
#endif

      /* etrapolation to first SciFi station using parametrization*/

      // extrapolate veloUT tracks
      float tx, ty, qop;

      for (int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track) {
          // veloUT track variables
          const float qop = ut_tracks.qop[i_veloUT_track];
          const int i_velo_track = ut_tracks.velo_track[i_veloUT_track];
          const MiniState velo_state {velo_states, velo_event_tracks_offset + i_velo_track};
          const int ut_track_index = ut_event_tracks_offset + i_veloUT_track;
          const float ut_x = host_ut_x[ut_track_index];
          const float ut_tx = host_ut_tx[ut_track_index];
          const float ut_z = host_ut_z[ut_track_index];

          // SciFi IDs for matched veloUT track
          const std::vector<uint32_t> true_scifi_ids = scifi_ids_ut_tracks[i_event][i_veloUT_track];

          // extrapolate velo y & ty to z of UT x and tx
          // use ty from Velo state
          MiniState state_UT;
          state_UT.x = ut_x;
          state_UT.tx = ut_tx;
          state_UT.z = ut_z;
          state_UT.ty = velo_state.ty;
          state_UT.y = y_at_z(velo_state, ut_z);

          // extrapolate state to last UT plane (needed as input for parametrization)
          MiniState UT_state_from_velo = state_at_z(velo_state, SciFi::LookingForward::z_last_UT_plane);
          MiniState UT_state = state_at_z(state_UT, SciFi::LookingForward::z_last_UT_plane);

          // DEBUG this is just a test
          // UT_state = UT_state_from_velo;

          t1_extrap_worked = false;
          t3_extrap_worked = false;
          isLong = false;
          match_t1 = false;
          match_t3 = false;
          // n_hits_in_window_0_t1 = 0;
          n_hits_in_window_0_t3 = 0;
          match_T2_0 = false;
          match_T2_3 = false;
          match_T3_0 = false;
          match_T3_3 = false;

          // sign of momentum -> charge of MCP
          // Caution: this is only set correctly if the veloUT track was matched to an MCP
          // set to 1e9 if not matched
          p_true = p_events[i_event][i_veloUT_track];

#ifdef WITH_ROOT
          UT_x = UT_state.x;
          UT_y = UT_state.y;
          UT_z = UT_state.z;
          UT_tx = UT_state.tx;
          UT_ty = UT_state.ty;
          ut_qop = qop;
          x_mag = x_at_z(UT_state, SciFi::LookingForward::zMagnetParams[0]);
          y_mag = y_at_z(UT_state, SciFi::LookingForward::zMagnetParams[0]);
#endif

          // running the hit selection algorithm
          std::vector<SciFi::TrackHits> track_candidates;
          SciFiWindowsParams window_params;
          window_params.max_window_layer0 = 600;
          // window_params.max_window_layer1 = 100;
          // window_params.max_window_layer2 = 100;
          // window_params.max_window_layer3 = 300;
          bool track_match;
          track_match = select_hits(UT_state, ut_tracks.qop[i_veloUT_track] , i_veloUT_track, scifi_hits, scifi_hit_count, 3, track_candidates, window_params);

          num_candidates = track_candidates.size();

          // propagation to first layer of T3
          MiniState SciFi_state_T3;
          int q = (ut_qop > 0 ? 1 : -1);
          SciFi_state_T3 = propagate_state_from_velo(UT_state, qop, 8);
          // access hits in first layer of T1, layer 0 = zone 0 (y < 0) + zone 1 (y > 0)
          int x_zone_offset, n_hits;
          get_offset_and_n_hits_for_layer(16, scifi_hit_count, SciFi_state_T3.y, n_hits, x_zone_offset);

          // access hits in last layer of T1, layer 3 = zone 6 (y < 0) + zone 7 (y > 0)
          int n_hits_other, x_zone_offset_other;
          get_offset_and_n_hits_for_layer(22, scifi_hit_count, SciFi_state_T3.y, n_hits_other, x_zone_offset_other);

          // access hits in u-layer of T1, layer 1 = zone 2 (y < 0) + zone 3 (y > 0)
          int n_hits_u, x_zone_offset_u;
          get_offset_and_n_hits_for_layer(18, scifi_hit_count, SciFi_state_T3.y, n_hits_u, x_zone_offset_u);

          // access hits in v-layer of T1, layer 1 = zone 4 (y < 0) + zone 5 (y > 0)
          int n_hits_v, x_zone_offset_v;
          get_offset_and_n_hits_for_layer(20, scifi_hit_count, SciFi_state_T3.y, n_hits_v, x_zone_offset_v);

          // find x hit(s) in layer 0 that
          // were truth matched to the veloUT track
          if (true_scifi_ids.size() > 0) {
              isLong = true;
              match_t1 = false;
              for (const auto & track_candidate : track_candidates){
                  int good_hit_count = 0;
                  for (const auto true_id : true_scifi_ids) {
                      for (int k = 0 ; k<track_candidate.hitsNum ; k++){
                          const uint32_t lhcbid = scifi_hits.LHCbID(track_candidate.hits[k]);
                          if(true_id == lhcbid){
                              good_hit_count++;
                          }
                      }
                      good_hits = good_hit_count;
                      delta_y = track_candidate.quality;
                      if(good_hits == 4){
                          t_good_tracks->Fill();
                      }
                      // TODO check for normalization
                      t_track_candidates->Fill();
                  }
              }
              std::array<int,4> true_hits_idx_T3 = {0,0,0,0};
              for (const auto true_id : true_scifi_ids) {
                  for (int i_hit = 0; i_hit < n_hits; ++i_hit) {
                      const int hit_index = x_zone_offset + i_hit;
                      const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
                      if (true_id == lhcbid) {
                          res_x_0_t3 = SciFi_state_T3.x - scifi_hits.x0[hit_index];
                          true_x_t3 = scifi_hits.x0[hit_index];
                          x_extrap_t3 = SciFi_state_T3.x;
                          match_t3 = true;
                          t_extrap_T3->Fill();
                          true_hits_idx_T3[0] = hit_index;
                          break;
                      }
                  }

                  for (int i_hit = 0; i_hit < n_hits_other; ++i_hit) {
                      const int hit_index = x_zone_offset_other + i_hit;
                      const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
                      if (true_id == lhcbid) {
                          true_hits_idx_T3[3] = hit_index;
                          break;
                      }
                  }

                  for (int i_hit = 0; i_hit < n_hits_u; ++i_hit) {
                      const int hit_index = x_zone_offset_u + i_hit;
                      const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
                      if (true_id == lhcbid) {
                          true_hits_idx_T3[1] = hit_index;
                          break;
                      }
                  }

                  for (int i_hit = 0; i_hit < n_hits_v; ++i_hit) {
                      const int hit_index = x_zone_offset_v + i_hit;
                      const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
                      if (true_id == lhcbid) {
                          true_hits_idx_T3[2] = hit_index;
                          break;
                      }
                  }

                  // if (match_t3) break;
              }
              for(auto idx : true_hits_idx_T3){
                  std::cout << idx << " " ;
              }
              std::cout << std::endl;

          } // extrapolation to T3 worked
#ifdef WITH_ROOT
          t_ut_tracks->Fill();
#endif
      } // loop over veloUT tracks
  }

#ifdef WITH_ROOT
  f->Write();
  f->Close();
#endif

  return 0;
}

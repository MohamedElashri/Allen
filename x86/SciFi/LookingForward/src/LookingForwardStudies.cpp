#include "LookingForwardStudies.h"
#include "TrackUtils.cuh"
#include "FindXHits.cuh"
#include "LookingForwardSbt.h"
#include <numeric>
#include <iomanip>

#define WITH_ROOT 1

#ifdef WITH_ROOT
#include "TH1D.h"
#include "TFile.h"
#include "TTree.h"
#endif

std::vector<std::vector<SciFi::TrackHits>> looking_forward_studies(
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
  std::vector<std::vector<SciFi::TrackHits>> trackhits;

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
  TTree* t_windows_x = new TTree("windows_x", "windows_x");
  TTree* t_xcalc_x = new TTree("xcalc_x", "xcalc_x");
  TTree* t_chi2_triplet_1 = new TTree("chi2_triplet1", "chi2_triplet1");
  TTree* t_chi2_random_triplet = new TTree("chi2_random_triplet", "chi2_random_triplet");
  TTree* t_distance_candidate_extrap_mc = new TTree("distance_candidate_extrap_mc", "distance_candidate_extrap_mc");
  TTree* t_extend_tracks0 = new TTree("t_extend_tracks0", "t_extend_tracks0");
  TTree* t_extend_tracks1 = new TTree("t_extend_tracks1", "t_extend_tracks1");
  TTree* t_extend_tracks2 = new TTree("t_extend_tracks2", "t_extend_tracks2");
  TTree* t_triplet_0 = new TTree("t_triplet_0", "t_triplet_0");
  TTree* t_triplet_1 = new TTree("t_triplet_1", "t_triplet_1");
  TTree* t_triplet_2 = new TTree("t_triplet_2", "t_triplet_2");
  TTree* t_triplet_3 = new TTree("t_triplet_3", "t_triplet_3");

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
  float layer8_win_size;
  int layer8_win_pop;
  float res_x_0_t3, res_x_3_t3, dx_t3, x_extrap_t3, y_extrap_t3, true_x_t3, res_x_other_t3;

  float quality, delta_y_good;
  int num_candidates, good_hits;
  int n_hits_in_window_0_t3 = 0, n_hits_in_window_0_t3_true_p = 0, n_hits_in_window_3_t3 = 0;
  int n_hits_in_zone_t3 = 0, n_hits_in_window_other_t3 = 0;
  float p_diff_before_update_t3, p_diff_after_update_t3, p_resolution_after_update_t3;
  float qop_diff_before_update_t3, qop_diff_after_update_t3, qop_diff_before_after_t3, qop_resolution_after_update_t3;
  std::array<float, 8> forwarding_res;
  std::array<float, 8> forwarding_chi2;

  bool t1_extrap_worked, t3_extrap_worked, isLong;
  float p_true;
  bool match_t1, match_t3, match_t1_other, match_t3_other, match_t1_u, match_t1_v;
  bool match_T2_0, match_T2_3, match_T3_0, match_T3_3;
  float chi2_track;

  t_scifi_hits->Branch("planeCode", &planeCode);
  t_scifi_hits->Branch("LHCbID", &LHCbID);
  t_scifi_hits->Branch("x0", &x0);
  t_scifi_hits->Branch("z0", &z0);
  t_scifi_hits->Branch("w", &w);
  t_scifi_hits->Branch("dxdy", &dxdy);
  t_scifi_hits->Branch("dzdy", &dzdy);
  t_scifi_hits->Branch("yMin", &yMin);
  t_scifi_hits->Branch("yMax", &yMax);

  std::array<int, 6> window_size;
  std::array<float, 6> window_dx;
  std::array<float, 6> window_flavio_dx;
  std::array<float, 6> real_dx;
  std::array<float, 6> diff_window_dx;
  std::array<float, 6> diff_window_flavio_dx;

  for (int i = 0; i < 6; ++i) {
    t_windows_x->Branch(("window_x" + std::to_string(i + 1)).c_str(), (int*) &(window_size[i]));
    t_windows_x->Branch(("window_dx" + std::to_string(i + 1)).c_str(), (float*) &(window_dx[i]));
    t_windows_x->Branch(("window_flavio_dx" + std::to_string(i + 1)).c_str(), (float*) &(window_flavio_dx[i]));
    t_windows_x->Branch(("real_dx" + std::to_string(i + 1)).c_str(), (float*) &(real_dx[i]));
    t_windows_x->Branch(("diff_window_dx" + std::to_string(i + 1)).c_str(), (float*) &(diff_window_dx[i]));
    t_windows_x->Branch(
      ("diff_window_flavio_dx" + std::to_string(i + 1)).c_str(), (float*) &(diff_window_flavio_dx[i]));
  }

  float xcalc_distance_MC;
  t_xcalc_x->Branch("xcalc_distance_MC", &xcalc_distance_MC);

  float chi2_triplet_1;
  t_chi2_triplet_1->Branch("chi2_triplet_1", &chi2_triplet_1);

  float chi2_random_triplet;
  t_chi2_random_triplet->Branch("t_chi2_random_triplet", &chi2_random_triplet);

  float distance_candidate_extrap_x3_x0_mc;
  float distance_candidate_extrap_x3_x4_mc;
  t_distance_candidate_extrap_mc->Branch("distance_candidate_extrap_x3_x0_mc", &distance_candidate_extrap_x3_x0_mc);
  t_distance_candidate_extrap_mc->Branch("distance_candidate_extrap_x3_x4_mc", &distance_candidate_extrap_x3_x4_mc);

  float extend_track_diff_x [3];
  float extend_track_chi2 [3];
  t_extend_tracks0->Branch("extend_track_diff_x", (float*) &(extend_track_diff_x[0]));
  t_extend_tracks0->Branch("extend_track_chi2", (float*) &(extend_track_chi2[0]));
  t_extend_tracks1->Branch("extend_track_diff_x", (float*) &(extend_track_diff_x[1]));
  t_extend_tracks1->Branch("extend_track_chi2", (float*) &(extend_track_chi2[1]));
  t_extend_tracks2->Branch("extend_track_diff_x", (float*) &(extend_track_diff_x[2]));
  t_extend_tracks2->Branch("extend_track_chi2", (float*) &(extend_track_chi2[2]));

  float triplet_diff_x0 [4];
  float triplet_diff_x2 [4];
  float triplet_chi2 [4];
  t_triplet_0->Branch("triplet_diff_x0", (float*) &(triplet_diff_x0[0]));
  t_triplet_0->Branch("triplet_diff_x2", (float*) &(triplet_diff_x2[0]));
  t_triplet_0->Branch("triplet_chi2", (float*) &(triplet_chi2[0]));
  t_triplet_1->Branch("triplet_diff_x0", (float*) &(triplet_diff_x0[1]));
  t_triplet_1->Branch("triplet_diff_x2", (float*) &(triplet_diff_x2[1]));
  t_triplet_1->Branch("triplet_chi2", (float*) &(triplet_chi2[1]));
  t_triplet_2->Branch("triplet_diff_x0", (float*) &(triplet_diff_x0[2]));
  t_triplet_2->Branch("triplet_diff_x2", (float*) &(triplet_diff_x2[2]));
  t_triplet_2->Branch("triplet_chi2", (float*) &(triplet_chi2[2]));
  t_triplet_3->Branch("triplet_diff_x0", (float*) &(triplet_diff_x0[3]));
  t_triplet_3->Branch("triplet_diff_x2", (float*) &(triplet_diff_x2[3]));
  t_triplet_3->Branch("triplet_chi2", (float*) &(triplet_chi2[3]));

  t_extrap_T3->Branch("xf", &xf_t3);
  t_extrap_T3->Branch("yf", &yf_t3);
  t_extrap_T3->Branch("txf", &txf_t3);
  t_extrap_T3->Branch("tyf", &tyf_t3);
  t_extrap_T3->Branch("der_xf_qop", &der_xf_qop_t3);
  t_extrap_T3->Branch("res_x_0", &res_x_0_t3);
  t_extrap_T3->Branch("res_x_other", &res_x_other_t3);
  t_extrap_T3->Branch("true_x", &true_x_t3);
  t_extrap_T3->Branch("x_extrap", &x_extrap_t3);
  t_extrap_T3->Branch("y_extrap", &y_extrap_t3);
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
  t_extrap_T3->Branch("layer8_win_size", &layer8_win_size);
  t_extrap_T3->Branch("layer8_win_pop", &layer8_win_pop);
  t_extrap_T3->Branch("num_candidates", &num_candidates);

  t_track_candidates->Branch("quality", &quality);
  t_track_candidates->Branch("num_candidates", &num_candidates);
  t_track_candidates->Branch("good_hits", &good_hits);
  t_track_candidates->Branch("UT_qop", &ut_qop);

  t_good_tracks->Branch("quality", &quality);
  t_good_tracks->Branch("num_candidates", &num_candidates);
  t_good_tracks->Branch("good_hits", &good_hits);
  t_good_tracks->Branch("UT_qop", &ut_qop);
  t_good_tracks->Branch("qop_update_res", &qop_resolution_after_update_t3);
  for (int k = 0; k < 8; k++) {
    t_good_tracks->Branch(("forwarding_res_plane" + to_string(k)).c_str(), &forwarding_res[k]);
    t_good_tracks->Branch(("forwarding_chi2_plane" + to_string(k)).c_str(), &forwarding_chi2[k]);
  }
  t_good_tracks->Branch("qop_update", &qop_update_t3);
  t_good_tracks->Branch("p_true", &p_true);
  t_good_tracks->Branch("chi2_track", &chi2_track);

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

  const auto lhcb_id_find_id =
    [](int start_id, const int last_id, const uint32_t lhcb_id, const SciFi::Hits& scifi_hits) {
      for (; start_id < last_id; ++start_id) {
        if (scifi_hits.LHCbID(start_id) == lhcb_id) {
          return start_id;
        }
      }
      return start_id;
    };

  int n_veloUT_tracks = 0;
  int n_extrap_T1 = 0;
  int n_extrap_T3 = 0;

  std::array<int, 12> n_layer {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  int n_quadruplets = 0;
  int n_triplets = 0;
  int n_reconstructible_scifi_tracks_from_ut_tracks = 0;
  int n_both_x_stations = 0;
  int n_hits_in_first_window = 0;

  int n_reconstructible_found_tracks = 0;
  std::array<int, 12> n_found_hits {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  std::array<int, 12> n_layer_with_T3_quad_triplets {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

  int number_of_track_candidates = 0;
  int n_total_hits_in_first_window = 0;
  int n_veloUT_tracks_with_window = 0;

  int number_of_track_candidates_after_station_2 = 0;

  for (uint i_event = 0; i_event < number_of_events; ++i_event) {
    // info_cout << std::endl << "Event #" << i_event << std::endl;
    // Tracks found for this event
    std::vector<SciFi::TrackHits> event_trackhits;

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

    int number_of_candidates_event = 0;

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

      const auto make_index_list_of_reconstructible =
        [&scifi_hit_count, &scifi_hits, &lhcb_id_find_id](const std::vector<uint>& true_scifi_ids) {
          std::vector<int> indices;

          const auto event_offset = scifi_hit_count.event_offset();
          const auto n_hits = scifi_hit_count.event_number_of_hits();
          const auto last_hit = event_offset + n_hits;

          for (const auto& lhcb_id : true_scifi_ids) {
            const auto index = lhcb_id_find_id(event_offset, last_hit, lhcb_id, scifi_hits);
            if (index != last_hit) {
              indices.push_back(index);
            }
          }

          return indices;
        };

      // SciFi IDs for matched veloUT track
      const std::vector<int> true_scifi_indices =
        make_index_list_of_reconstructible(scifi_ids_ut_tracks[i_event][i_veloUT_track]);

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
      std::vector<SciFi::TrackHits> scifi_tracks;
      std::array<std::vector<Window_stat>, 4> window_stats;
      SciFiWindowsParams window_params;
      window_params.dx_slope = 1e5;
      window_params.dx_min = 300;
      window_params.dx_weight = 0.6;
      window_params.tx_slope = 1250;
      window_params.tx_min = 300;
      window_params.tx_weight = 0.4;
      window_params.max_window_layer0 = 600;
      window_params.max_window_layer1 = 2;
      window_params.max_window_layer2 = 2;
      window_params.max_window_layer3 = 20;
      window_params.chi2_cut = 4;

      // propagation to first layer of T3
      const auto SciFi_state_T3 = propagate_state_from_velo(UT_state, qop, 8);

      std::array<int, 12> layer_offsets;
      std::array<int, 12> layer_number_of_hits;
      std::array<int, 12> layer_last_hits;

      for (int i = 0; i < 12; ++i) {
        const auto layer_offset_nhits = get_offset_and_n_hits_for_layer(i * 2, scifi_hit_count, SciFi_state_T3.y);

        layer_offsets[i] = std::get<0>(layer_offset_nhits);
        layer_number_of_hits[i] = std::get<1>(layer_offset_nhits);
        layer_last_hits[i] = layer_offsets[i] + layer_number_of_hits[i];
      }

      // Monte Carlo track
      // Simplified model: One hit per layer.
      // This is not realistic though, since we could have repeated hits on stations
      std::array<int, 12> true_scifi_indices_per_layer {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
      for (int i = 0; i < 12; ++i) {
        for (const auto index : true_scifi_indices) {
          if (index >= layer_offsets[i] && index < layer_last_hits[i]) {
            true_scifi_indices_per_layer[i] = index;
          }
        }
      }

      std::array<int, 2 * 6> windows_x;
      std::array<int, 2 * 6> windows_uv;
      std::array<float, 4 * 6> parameters_uv;

      for (int i = 0; i < 6; ++i) {
        windows_x[2 * i] = 0;
        windows_x[2 * i + 1] = 0;
        windows_uv[2 * i] = 0;
        windows_uv[2 * i + 1] = 0;
        parameters_uv[4 * i] = 0;
        parameters_uv[4 * i + 1] = 0;
        parameters_uv[4 * i + 2] = 0;
        parameters_uv[4 * i + 3] = 0;
      }

      const float y_projection = y_at_z(UT_state, SciFi::LookingForward::Zone_zPos[0]);
      const float zRef_track = SciFi::Tracking::zReference;
      const float xAtRef = xFromVelo(zRef_track, UT_state);
      const float yAtRef = yFromVelo(zRef_track, UT_state);
      std::array<int, 6> layers {0, 3, 4, 7, 8, 11};

      float bs_x[4] {xAtRef, UT_state.tx, 0, 0};
      float bs_y[4] {yAtRef, UT_state.ty, 0, 0};

      SciFi::Tracking::Arrays constArrays;
      collectAllXHits_proto(
        scifi_hits,
        scifi_hit_count,
        bs_x,
        bs_y,
        &constArrays,
        UT_state,
        qop,
        (y_projection < 0 ? -1 : 1),
        windows_x,
        windows_uv,
        parameters_uv);

      // Collect all X candidates
      std::array<std::vector<int>, 6> hits_in_layers =
        collect_x_candidates(scifi_hits, windows_x, windows_uv, parameters_uv);

      // info_cout << "Candidate sizes: ";
      // for (int i=0; i<6; ++i) {
      //   info_cout << hits_in_layers[i].size() << ", ";
      // }
      // info_cout << std::endl;

      const float xParams_seed[2] = {xAtRef, UT_state.tx};
      const float yParams_seed[2] = {yAtRef, UT_state.ty};

      const float zMag = SciFi::LookingForward::zMagnetParams[0] +
                         SciFi::LookingForward::zMagnetParams[2] * UT_state.tx * UT_state.tx +
                         SciFi::LookingForward::zMagnetParams[3] * UT_state.ty * UT_state.ty;

      // Constants from BsPhiPhi Monte Carlo
      const std::array<float, 4> dx_stddev_triplet_x0  {53.01f, 97.43f, 39.89f, 77.55f};
      const std::array<float, 4> dx_stddev_triplet_x2  {117.1f, 42.68f, 88.74f, 33.79f};
      const std::array<float, 4> chi2_mean_triplet     { 2.35f,  3.14f,  2.17f,  3.95f};
      const std::array<float, 4> chi2_stddev_triplet   {14.05f,  7.49f,  9.97f,  7.97f};
      const std::array<int, 4> max_candidates_triplets {20, 20, 20, 20};

      const std::array<float, 3> dx_stddev_extrapolation_to_x_layers   {1.50f, 1.40f, 1.74f};
      const std::array<float, 3> chi2_mean_extrapolation_to_x_layers   {3.09f, 1.98f, 3.89f};
      const std::array<float, 3> chi2_stddev_extrapolation_to_x_layers {6.33f, 5.09f, 7.42f};

      // Find window on x0 from x1, and window on x2 from x1
      std::vector<std::tuple<int, int>> compatible_hits_x0 = find_compatible_window(
        scifi_hits, layers[1], layers[0], hits_in_layers[1], hits_in_layers[0], dx_stddev_triplet_x0[0], UT_state, xAtRef, zMag);

      std::vector<std::tuple<int, int>> compatible_hits_x2 = find_compatible_window(
        scifi_hits, layers[1], layers[2], hits_in_layers[1], hits_in_layers[2], dx_stddev_triplet_x2[0], UT_state, xAtRef, zMag);

      // for (int i = 0; i < hits_in_layers[1].size(); ++i) {
      //   const auto start_h0 = std::get<0>(compatible_hits_x0[i]);
      //   const auto size_h0 = std::get<1>(compatible_hits_x0[i]) - start_h0;
      //   const auto start_h2 = std::get<0>(compatible_hits_x2[i]);
      //   const auto size_h2 = std::get<1>(compatible_hits_x2[i]) - start_h2;

      //   info_cout << "Compatible hits: " << start_h0 << ", " << size_h0 << " (" << hits_in_layers[0].size() << "),"
      //     << start_h2 << ", " << size_h2 << " (" << hits_in_layers[2].size() << ")" << std::endl;
      // }
      
      // Flagging mechanism
      const auto event_offset = scifi_hit_count.event_offset();
      std::vector<bool> flag (scifi_hit_count.event_number_of_hits(), false);

      // Get all compatible triplets in window
      std::vector<Tracklet> tracklets;
      std::vector<std::tuple<int, int, int, float>> triplets = find_triplets(
        scifi_hits,
        qop,
        compatible_hits_x0,
        compatible_hits_x2,
        flag,
        event_offset,
        layers,
        hits_in_layers,
        0,
        1,
        2,
        max_candidates_triplets[0],
        chi2_mean_triplet[0] + 2 * chi2_stddev_triplet[0]);

      std::vector<std::tuple<int, int>> extend_candidates_windows;

      for (int i=0; i<3; ++i) {
        // Extend forming tracklets
        extend_tracklets(
          scifi_hits,
          UT_state,
          qop,
          layers,
          hits_in_layers,
          i+3,
          event_offset,
          chi2_mean_extrapolation_to_x_layers[i] + 2 * chi2_stddev_extrapolation_to_x_layers[i],
          tracklets,
          flag);

        // Find candidates in next layer for triplets
        extend_candidates_windows = find_extend_windows(
          scifi_hits,
          UT_state,
          qop,
          layers,
          hits_in_layers,
          i+1,
          i+2,
          i+3,
          2 * dx_stddev_extrapolation_to_x_layers[i],
          triplets);

        // Fetch only the best candidate
        extend_triplets(
          scifi_hits,
          UT_state,
          qop,
          layers,
          hits_in_layers,
          i+1,
          i+2,
          i+3,
          triplets,
          extend_candidates_windows,
          event_offset,
          chi2_mean_extrapolation_to_x_layers[i] + 2 * chi2_stddev_extrapolation_to_x_layers[i],
          tracklets,
          flag);

        // Find window on x0 from x1, and window on x2 from x1
        compatible_hits_x0 = find_compatible_window(
          scifi_hits, layers[i+2], layers[i+1], hits_in_layers[i+2], hits_in_layers[i+1], dx_stddev_triplet_x0[i+1], UT_state, xAtRef, zMag);

        compatible_hits_x2 = find_compatible_window(
          scifi_hits, layers[i+2], layers[i+3], hits_in_layers[i+2], hits_in_layers[i+3], dx_stddev_triplet_x2[i+1], UT_state, xAtRef, zMag);

        // Find new triplets
        triplets = find_triplets(
          scifi_hits,
          qop,
          compatible_hits_x0,
          compatible_hits_x2,
          flag,
          event_offset,
          layers,
          hits_in_layers,
          i+1,
          i+2,
          i+3,
          max_candidates_triplets[i+1],
          chi2_mean_triplet[i+1] + 2 * chi2_stddev_triplet[i+1]);
      }

      for (const auto& triplet : triplets) {
        Tracklet t;
        t.add_hit(std::get<0>(triplet));
        t.add_hit(std::get<1>(triplet));
        t.add_hit(std::get<2>(triplet));

        tracklets.push_back(t);
      }

      // Extra triplets
      std::array<std::tuple<int, int, int>, 4> extra_triplets {
        std::make_tuple(0, 2, 4),
        std::make_tuple(0, 2, 5),
        std::make_tuple(1, 3, 4),
        std::make_tuple(1, 3, 5)
      };

      const float dx_stddev_triplet_x0_extra = 97.43f;
      const float dx_stddev_triplet_x2_extra = 117.1f;
      const float chi2_mean_triplet_extra = 3.95f;
      const float chi2_stddev_triplet_extra = 14.05f;
      const int max_candidates_triplets_extra = 20;

      for (const auto& extra_triplet : extra_triplets) {
        const auto relative_layer0 = std::get<0>(extra_triplet);
        const auto relative_layer1 = std::get<1>(extra_triplet);
        const auto relative_layer2 = std::get<2>(extra_triplet);

        compatible_hits_x0 = find_compatible_window(
          scifi_hits, layers[relative_layer1], layers[relative_layer0], hits_in_layers[relative_layer1], hits_in_layers[relative_layer0], dx_stddev_triplet_x0_extra, UT_state, xAtRef, zMag);

        compatible_hits_x2 = find_compatible_window(
          scifi_hits, layers[relative_layer1], layers[relative_layer2], hits_in_layers[relative_layer1], hits_in_layers[relative_layer2], dx_stddev_triplet_x2_extra, UT_state, xAtRef, zMag);

        triplets = find_triplets(
          scifi_hits,
          qop,
          compatible_hits_x0,
          compatible_hits_x2,
          flag,
          event_offset,
          layers,
          hits_in_layers,
          relative_layer0,
          relative_layer1,
          relative_layer2,
          max_candidates_triplets_extra,
          chi2_mean_triplet_extra + 2 * chi2_stddev_triplet_extra);

        for (const auto& triplet : triplets) {
          Tracklet t;
          t.add_hit(std::get<0>(triplet));
          t.add_hit(std::get<1>(triplet));
          t.add_hit(std::get<2>(triplet));
          tracklets.push_back(t);
        }        
      }

      // Generate MC data about triplet creation
      // for (int i=0; i<4; ++i) {
      //   const auto layer0 = layers[i];
      //   const auto layer1 = layers[i+1];
      //   const auto layer2 = layers[i+2];
      //   const auto h0 = true_scifi_indices_per_layer[layer0];
      //   const auto h1 = true_scifi_indices_per_layer[layer1];
      //   const auto h2 = true_scifi_indices_per_layer[layer2];

      //   if (h0 != -1 && h1 != -1 && h2 != -1) {
      //     {
      //       const auto z1 = SciFi::LookingForward::Zone_zPos[layer1];
      //       const auto z0 = SciFi::LookingForward::Zone_zPos[layer0];
      //       const auto dSlopeDivPart = 1.f / (z1 - SciFi::LookingForward::zMagnetParams[0]);
      //       const auto dz = 1.e-3f * std::abs(z1 - z0);
      //       const float x_from_velo_hit = xAtRef + UT_state.tx * z1;

      //       const auto x1 = scifi_hits.x0[h1];
      //       const auto dSlope = (x_from_velo_hit - x1) * dSlopeDivPart;
      //       const auto zMag_corrected = zMag + SciFi::LookingForward::zMagnetParams[1] * dSlope * dSlope;
      //       const auto xMag = x_from_velo_hit + UT_state.tx * (zMag_corrected - z1);

      //       // calculate x position on reference plane (save in coodX)
      //       // dxCoef: account for additional bending of track due to fringe field in first station
      //       // expressed by quadratic and cubic term in z
      //       auto dxCoef =
      //         dz * dz * (SciFi::LookingForward::xParams[0] + dz * SciFi::LookingForward::xParams[1]) * dSlope;
      //       auto ratio = (z0 - zMag_corrected) / (z1 - zMag_corrected);
      //       auto extrapolated_value = xMag + ratio * (x1 + dxCoef - xMag);
      //       const auto x0 = scifi_hits.x0[h0];
            
      //       triplet_diff_x0[i] = x0 - extrapolated_value;
      //     }

      //     {
      //       const auto z1 = SciFi::LookingForward::Zone_zPos[layer1];
      //       const auto z2 = SciFi::LookingForward::Zone_zPos[layer2];
      //       const auto dSlopeDivPart = 1.f / (z1 - SciFi::LookingForward::zMagnetParams[0]);
      //       const auto dz = 1.e-3f * std::abs(z1 - z2);
      //       const float x_from_velo_hit = xAtRef + UT_state.tx * z1;

      //       const auto x1 = scifi_hits.x0[h1];
      //       const auto dSlope = (x_from_velo_hit - x1) * dSlopeDivPart;
      //       const auto zMag_corrected = zMag + SciFi::LookingForward::zMagnetParams[1] * dSlope * dSlope;
      //       const auto xMag = x_from_velo_hit + UT_state.tx * (zMag_corrected - z1);

      //       // calculate x position on reference plane (save in coodX)
      //       // dxCoef: account for additional bending of track due to fringe field in first station
      //       // expressed by quadratic and cubic term in z
      //       auto dxCoef =
      //         dz * dz * (SciFi::LookingForward::xParams[0] + dz * SciFi::LookingForward::xParams[1]) * dSlope;
      //       auto ratio = (z2 - zMag_corrected) / (z1 - zMag_corrected);
      //       auto extrapolated_value = xMag + ratio * (x1 + dxCoef - xMag);
      //       const auto x2 = scifi_hits.x0[h2];
            
      //       triplet_diff_x2[i] = x2 - extrapolated_value;
      //     }
          
      //     triplet_chi2[i] = chi2_triplet(scifi_hits, qop, h0, h1, h2, layer0, layer1, layer2);

      //     if (triplet_chi2[i] < 1000.f) {
      //       if (i==0) {
      //         t_triplet_0->Fill();
      //       } else if (i==1) {
      //         t_triplet_1->Fill();
      //       } else if (i==2) {
      //         t_triplet_2->Fill();
      //       } else if (i==3) {
      //         t_triplet_3->Fill();
      //       }
      //     }
      //   }
      // }

      // Generate MC data about extrapolation
      // for (int i=0; i<3; ++i) {
      //   const auto layer0 = layers[1+i];
      //   const auto layer1 = layers[2+i];
      //   const auto layer2 = layers[3+i];
      //   const auto h0 = true_scifi_indices_per_layer[layer0];
      //   const auto h1 = true_scifi_indices_per_layer[layer1];
      //   const auto h2 = true_scifi_indices_per_layer[layer2];

      //   if (h0 != -1 && h1 != -1 && h2 != -1) {
      //     const auto projection_y = y_at_z(UT_state, SciFi::LookingForward::Zone_zPos[layer2]);

      //     // do the propagation
      //     const auto x_at_layer0 = scifi_hits.x0[h0];
      //     const auto x_at_layer1 = scifi_hits.x0[h1];
      //     const auto x_at_layer2 = scifi_hits.x0[h2];

      //     const auto reco_slope = (x_at_layer1 - x_at_layer0) /
      //       (SciFi::LookingForward::Zone_zPos[layer1] -
      //        SciFi::LookingForward::Zone_zPos[layer0]);

      //     const auto projection_x = scifi_propagation(
      //                                 x_at_layer0,
      //                                 reco_slope,
      //                                 qop,
      //                                 SciFi::LookingForward::Zone_zPos[layer2] - SciFi::LookingForward::Zone_zPos[layer0]);

      //     const auto diff_x = x_at_layer2 - projection_x;

      //     const auto chi2_fn = [&x_at_layer0, &reco_slope, &qop, &layer0] (const float z) {
      //       return scifi_propagation(
      //         x_at_layer0,
      //         reco_slope,
      //         qop,
      //         z - SciFi::LookingForward::Zone_zPos[layer0]);
      //     };

      //     std::vector<float> x_coordinates {
      //       x_at_layer0,
      //       x_at_layer1,
      //       x_at_layer2};

      //     std::vector<float> z_coordinates {
      //       SciFi::LookingForward::Zone_zPos[layer0],
      //       SciFi::LookingForward::Zone_zPos[layer1],
      //       SciFi::LookingForward::Zone_zPos[layer2]};

      //     const auto chi2 = get_chi_2(z_coordinates, x_coordinates, chi2_fn);

      //     extend_track_diff_x[i] = diff_x;
      //     extend_track_chi2[i] = chi2;

      //     if (chi2 < 100.f) {
      //       if (i==0) {
      //         t_extend_tracks0->Fill();
      //       } else if (i==1) {
      //         t_extend_tracks1->Fill();
      //       } else if (i==2) {
      //         t_extend_tracks2->Fill();
      //       }
      //     }
      //   }
      // }

      // if (true_scifi_indices_per_layer[0] != -1 &&
      //     true_scifi_indices_per_layer[1] != -1 &&
      //     true_scifi_indices_per_layer[2] != -1) {
      //   const float z0 = scifi_hits.z0[true_scifi_indices_per_layer[0]];
      //   const float z1 = scifi_hits.z0[true_scifi_indices_per_layer[1]];
      //   const float z2 = scifi_hits.z0[true_scifi_indices_per_layer[2]];

      //   const float xFromVelo_Hit = xParams_seed[0] + xParams_seed[1] * z1;
      //   const float xHit = scifi_hits.x0[true_scifi_indices_per_layer[1]];

      //   {
      //     const auto dz = 1.e-3f * (z1 - z0);
      //     const auto dSlopeDivPart = 1.f / (z1 - SciFi::LookingForward::zMagnetParams[0]);
      //     const auto dSlope = (xFromVelo_Hit - xHit) * dSlopeDivPart;
      //     const auto zMag_corrected = zMag + SciFi::LookingForward::zMagnetParams[1] * dSlope * dSlope;
      //     const auto xMag = xFromVelo_Hit + UT_state.tx * (zMag_corrected - z1);

      //     // calculate x position on reference plane (save in coodX)
      //     // dxCoef: account for additional bending of track due to fringe field in first station
      //     // expressed by quadratic and cubic term in z
      //     const auto dxCoef = dz * dz * (SciFi::LookingForward::xParams[0] + dz * SciFi::LookingForward::xParams[1])
      //     * dSlope; const auto ratio = (z0 - zMag_corrected) / (z1 - zMag_corrected); const auto extrapolated_value =
      //     xMag + ratio * (xHit + dxCoef - xMag);

      //     const auto mc_x0 = scifi_hits.x0[true_scifi_indices_per_layer[0]];
      //     distance_candidate_extrap_x3_x0_mc = extrapolated_value - mc_x0;
      //   }

      //   {
      //     const auto dz = 1.e-3f * (z2 - z1);
      //     const auto dSlopeDivPart = 1.f / (z1 - SciFi::LookingForward::zMagnetParams[0]);
      //     const auto dSlope = (xFromVelo_Hit - xHit) * dSlopeDivPart;
      //     const auto zMag_corrected = zMag + SciFi::LookingForward::zMagnetParams[1] * dSlope * dSlope;
      //     const auto xMag = xFromVelo_Hit + UT_state.tx * (zMag_corrected - z1);

      //     // calculate x position on reference plane (save in coodX)
      //     // dxCoef: account for additional bending of track due to fringe field in first station
      //     // expressed by quadratic and cubic term in z
      //     const auto dxCoef = dz * dz * (SciFi::LookingForward::xParams[0] + dz * SciFi::LookingForward::xParams[1])
      //     * dSlope; const auto ratio = (z2 - zMag_corrected) / (z1 - zMag_corrected); const auto extrapolated_value =
      //     xMag + ratio * (xHit + dxCoef - xMag);

      //     const auto mc_x2 = scifi_hits.x0[true_scifi_indices_per_layer[2]];
      //     distance_candidate_extrap_x3_x4_mc = extrapolated_value - mc_x2;
      //   }

      //   t_distance_candidate_extrap_mc->Fill();
      //   // std::cout << "Diff: " << std::abs(extrapolated_value - mc_x0) << std::endl;
      // }

      // // Create SciFi track if it is within the windows
      // auto found_triplet = false;
      // if (
      //   true_scifi_indices_per_layer[0] != -1 && true_scifi_indices_per_layer[3] != -1 &&
      //   true_scifi_indices_per_layer[4] != -1 && hits_in_layers[0].size() > 0 && hits_in_layers[1].size() > 0 &&
      //   hits_in_layers[2].size() > 0) {
      //   // for (int i = 0; i < hits_in_layers[1].size(); ++i) {
      //   //   const auto start_h0 = std::get<0>(compatible_hits_x0[i]);
      //   //   const auto size_h0 = std::get<1>(compatible_hits_x0[i]) - start_h0;
      //   //   const auto start_h2 = std::get<0>(compatible_hits_x2[i]);
      //   //   const auto size_h2 = std::get<1>(compatible_hits_x2[i]) - start_h2;

      //   //   info_cout << "Compatible hits: " << start_h0 << ", " << size_h0 << " (" << hits_in_layers[0].size() << "),"
      //   //     << start_h2 << ", " << size_h2 << " (" << hits_in_layers[2].size() << ")" << std::endl;
      //   // }

      //   for (int i = 0; i < hits_in_layers[1].size(); ++i) {
      //     const bool found_h1 = std::find(true_scifi_indices.begin(), true_scifi_indices.end(), hits_in_layers[1][i]) !=
      //                           true_scifi_indices.end();
      //     if (found_h1) {
      //       const auto start_h0 = std::get<0>(compatible_hits_x0[i]);
      //       const auto size_h0 = std::get<1>(compatible_hits_x0[i]) - start_h0;

      //       const auto start_h2 = std::get<0>(compatible_hits_x2[i]);
      //       const auto size_h2 = std::get<1>(compatible_hits_x2[i]) - start_h2;

      //       if (size_h0 > 0 && size_h2 > 0) {
      //         for (int j = 0; !found_triplet && j < size_h0; ++j) {
      //           const bool found_h0 =
      //             std::find(true_scifi_indices.begin(), true_scifi_indices.end(), hits_in_layers[0][start_h0 + j]) !=
      //             true_scifi_indices.end();

      //           if (found_h0) {
      //             for (int k = 0; !found_triplet && k < size_h2; ++k) {
      //               const bool found_h2 =
      //                 std::find(
      //                   true_scifi_indices.begin(), true_scifi_indices.end(), hits_in_layers[2][start_h2 + k]) !=
      //                 true_scifi_indices.end();

      //               found_triplet |= (found_h0 && found_h1 && found_h2);
      //             }
      //           }
      //         }
      //       }
      //     }
      //   }
      // }

      // if (found_triplet) {
      //   SciFi::TrackHits candidate;
      //   candidate.UTTrackIndex = i_veloUT_track;
      //   for (int i = 0; i < 12; ++i) {
      //     if (true_scifi_indices_per_layer[i] != -1) {
      //       candidate.addHit(true_scifi_indices_per_layer[i]);
      //     }
      //   }
      //   scifi_tracks.push_back(candidate);
      // }

      // // We have in window all windows for x layers
      // // Save in coordX all extrapolated hits in the above windows
      // std::vector<float> coordX;
      // std::vector<int8_t> monte_carlo_particles;
      // std::vector<uint8_t> hit_layers;

      // for (int i=0; i<3; ++i) {
      //   const auto window_size = hits_in_layers[i].size();

      //   if (window_size > 0) {
      //     const float zHit = scifi_hits.z0[hits_in_layers[i][0]];
      //     const float xFromVelo_Hit = xParams_seed[0] + xParams_seed[1] * zHit;
      //     const float dSlopeDivPart = 1.f / (zHit - SciFi::LookingForward::zMagnetParams[0]);
      //     const float dz = 1.e-3f * (zHit - SciFi::Tracking::zReference);

      //     for (int j=0; j<window_size; ++j) {
      //       const auto hit_index = hits_in_layers[i][j];
      //       const float xHit = scifi_hits.x0[hit_index];

      //       float dSlope = (xFromVelo_Hit - xHit) * dSlopeDivPart;
      //       float zMag_corrected = zMag + SciFi::LookingForward::zMagnetParams[1] * dSlope * dSlope;
      //       float xMag = xFromVelo_Hit + UT_state.tx * (zMag_corrected - zHit);

      //       // calculate x position on reference plane (save in coodX)
      //       // dxCoef: account for additional bending of track due to fringe field in first station
      //       // expressed by quadratic and cubic term in z
      //       float dxCoef = dz * dz * (SciFi::LookingForward::xParams[0] + dz * SciFi::LookingForward::xParams[1]) *
      //       dSlope; float ratio = (SciFi::Tracking::zReference - zMag_corrected) / (zHit - zMag_corrected);
      //       coordX.emplace_back(xMag + ratio * (xHit + dxCoef - xMag));
      //       hit_layers.emplace_back(0x1 << (6 - i));
      //       if (std::find(true_scifi_indices.begin(), true_scifi_indices.end(), hit_index) !=
      //       true_scifi_indices.end()) {
      //         monte_carlo_particles.emplace_back(1);
      //       } else {
      //         monte_carlo_particles.emplace_back(0);
      //       }
      //     }
      //   }
      // }

      // // // Print coordX
      // // int counter = 0;
      // // for (int i=0; i<6; ++i) {
      // //   const auto window_size = windows_x[2*i+1];
      // //   info_cout << "Window " << i << ": ";
      // //   for (int j = 0; j<window_size; ++j) {
      // //     const auto index = counter + j;
      // //     info_cout << coordX[index] << ", ";
      // //   }
      // //   info_cout << std::endl;
      // //   counter += window_size;
      // // }

      // // Get sorted keys, sort coordX
      // std::vector<int> keys (coordX.size());
      // std::iota(keys.begin(), keys.end(), 0);
      // std::sort(keys.begin(), keys.end(), [&coordX](const int a, const int b) {
      //   return coordX[a] < coordX[b];
      // });

      // // // Check the distance of our MC particles in the Hough
      // // info_cout << "MC particle indices locations (presort): ";
      // // for (int i=0; i<monte_carlo_particles.size(); ++i) {
      // //   if (monte_carlo_particles[i] == 1) {
      // //     info_cout << i << ", ";
      // //   }
      // // }
      // // info_cout << std::endl;

      // std::sort(coordX.begin(), coordX.end());

      // decltype(monte_carlo_particles) sorted_monte_carlo_particles (monte_carlo_particles.size());
      // for (int i=0; i<monte_carlo_particles.size(); ++i) {
      //   sorted_monte_carlo_particles[i] = monte_carlo_particles[keys[i]];
      // }
      // monte_carlo_particles = sorted_monte_carlo_particles;

      // decltype(hit_layers) sorted_hit_layers (hit_layers.size());
      // for (int i=0; i<hit_layers.size(); ++i) {
      //   sorted_hit_layers[i] = hit_layers[keys[i]];
      // }
      // hit_layers = sorted_hit_layers;

      // if (true_scifi_indices.size() >= 9) {
      //   // Check the distance of our MC particles in the Hough
      //   std::vector<float> xcoord_mc_hits;

      //   info_cout << "MC particle indices locations: ";
      //   for (int i=0; i<monte_carlo_particles.size(); ++i) {
      //     if (monte_carlo_particles[i] == 1) {
      //       xcoord_mc_hits.push_back(coordX[i]);
      //       info_cout << i << ", ";
      //     }
      //   }
      //   // info_cout << "(" << std::setprecision(4) << std::scientific << p_true << ")" << std::endl;
      //   info_cout << "(" << monte_carlo_particles.size() << ")";
      //   float max_distance = 0.f;
      //   for (int i=0; i<xcoord_mc_hits.size(); ++i) {
      //     for (int j=i+1; j<xcoord_mc_hits.size(); ++j) {
      //       const auto distance = std::abs(xcoord_mc_hits[i] - xcoord_mc_hits[j]);
      //       if (distance > max_distance) {
      //         max_distance = distance;

      //         // Histogram
      //         xcalc_distance_MC = distance;
      //         t_xcalc_x->Fill();
      //       }
      //     }
      //   }
      //   info_cout << ", max distance " << max_distance << std::endl;
      // }

      // int times_condition_is_met = 0;
      // for (int i=0; i<coordX.size(); ++i) {
      //   const auto j = i+6;

      //   if (j < coordX.size()) {
      //     bool has_any_mc_index = false;
      //     for (int k=i; k<j; ++k) {
      //       has_any_mc_index |= monte_carlo_particles[k];
      //     }

      //     if (!has_any_mc_index) {
      //       bool condition_is_met = false;
      //       uint different_layers = 0;
      //       for (int k=i; k<j; ++k) {
      //         different_layers |= hit_layers[k];
      //       }
      //       int number_of_layers = __builtin_popcount(different_layers);
      //       // info_cout << number_of_layers << ", " << std::flush;
      //       if (number_of_layers >= 4) {
      //         times_condition_is_met++;
      //       }
      //     }
      //   }
      // }

      // // info_cout << "Times condition is met: " << times_condition_is_met << std::endl;

      // Create SciFi track if it is within the windows
      std::array<bool, 6> within_bounds {false, false, false, false, false, false};
      std::array<int, 6> compatible_scifi_hits {-1, -1, -1, -1, -1, -1};
      for (int i = 0; i < 6; ++i) {
        bool found = false;
        for (const auto index : true_scifi_indices) {
          if (std::find(hits_in_layers[i].begin(), hits_in_layers[i].end(), index) != hits_in_layers[i].end()) {
            found = true;
            compatible_scifi_hits[i] = index;
            break;
          }
        }
        within_bounds[i] = found;
      }

      // std::vector<std::tuple<int, int, int, float>> triplets;
      // for (const auto h0 : hits_in_layers[0]) {
      //   for (const auto h1 : hits_in_layers[1]) {
      //     for (const auto h2 : hits_in_layers[2]) {
      //       const auto chi2 = chi2_triplet(
      //         scifi_hits,
      //         qop,
      //         h0,
      //         h1,
      //         h2,
      //         layers[0],
      //         layers[1],
      //         layers[2]);

      //       if (chi2 < 4.f) {
      //         triplets.push_back({h0, h1, h2, chi2});
      //       }
      //     }
      //   }
      // }
      // std::sort(triplets.begin(), triplets.end(), [] (const auto a, const auto b) {
      //   return std::get<3>(a) < std::get<3>(b);
      // });

      // // info_cout << triplets.size() << std::endl;

      // Create SciFi track if it is within the windows
      bool found_triplet = false;
      for (int i = 0; i < tracklets.size(); ++i) {
        const auto tracklet = tracklets[i];

        int number_found = 0;
        for (int j=0; j<tracklet.numHits; ++j) {
          const auto hit_index = tracklet.hits[j];
          const bool found = std::find(true_scifi_indices.begin(), true_scifi_indices.end(), hit_index) !=
                             true_scifi_indices.end();
          if (found) {
            ++number_found;
          }
        }

        found_triplet |= (number_found >= 3);
      }

      // // Check for triplets
      const bool triplet_0 = within_bounds[0] && within_bounds[1] && within_bounds[2];
      const bool triplet_1 = within_bounds[3] && within_bounds[1] && within_bounds[2];
      const bool triplet_2 = within_bounds[3] && within_bounds[4] && within_bounds[2];
      const bool triplet_3 = within_bounds[3] && within_bounds[4] && within_bounds[5];

      const bool triplet_extra_0 = within_bounds[0] && within_bounds[2] && within_bounds[4];
      const bool triplet_extra_1 = within_bounds[0] && within_bounds[2] && within_bounds[5];
      const bool triplet_extra_2 = within_bounds[1] && within_bounds[3] && within_bounds[4];
      const bool triplet_extra_3 = within_bounds[1] && within_bounds[3] && within_bounds[5];

      const bool manuels_triplet_condition = (within_bounds[0] || within_bounds[1])
        && (within_bounds[2] || within_bounds[3])
        && (within_bounds[4] || within_bounds[5]);

      // //  || triplet_1 || triplet_2 || triplet_3
      if (found_triplet) {
        SciFi::TrackHits candidate;
        candidate.UTTrackIndex = i_veloUT_track;
        for (int i = 0; i < 12; ++i) {
          if (true_scifi_indices_per_layer[i] != -1) {
            candidate.addHit(true_scifi_indices_per_layer[i]);
          }
        }
        scifi_tracks.push_back(candidate);
      }

      // for (int i = 0; i < 6; ++i) {
      //   window_size[i] = hits_in_layers[i].size();
      // }
      // t_windows_x->Fill();

      // if (triplet_0) {
      //   chi2_triplet_1 = chi2_triplet(
      //     scifi_hits,
      //     qop,
      //     compatible_scifi_hits[0],
      //     compatible_scifi_hits[1],
      //     compatible_scifi_hits[2],
      //     layers[0],
      //     layers[1],
      //     layers[2]);

      //   t_chi2_triplet_1->Fill();
      // }

      // // Fetch real track seeds
      // if (true_scifi_indices_per_layer[8] != -1 &&
      //     true_scifi_indices_per_layer[11] != -1 &&
      //     (true_scifi_indices_per_layer[9] != -1 ||
      //     true_scifi_indices_per_layer[10] != -1))
      // {
      //   const auto populated_layer = true_scifi_indices_per_layer[11] != -1 ? 11 :
      //     (true_scifi_indices_per_layer[10] != -1 ? 10 : 9);

      //   SciFi::TrackHits candidate;
      //   candidate.UTTrackIndex = i_veloUT_track;
      //   candidate.qop = qop_update(
      //     UT_state,
      //     scifi_hits.x0[true_scifi_indices_per_layer[8]],
      //     scifi_hits.x0[true_scifi_indices_per_layer[populated_layer]],
      //     SciFi::LookingForward::Zone_zPos[8],
      //     SciFi::LookingForward::Zone_zPos[populated_layer],
      //     8);

      //   candidate.addHit(true_scifi_indices_per_layer[8], 8);
      //   candidate.addHit(true_scifi_indices_per_layer[populated_layer], populated_layer);

      //   for (int i=9; i<11; ++i) {
      //     if (i != populated_layer && true_scifi_indices_per_layer[i] != -1) {
      //       candidate.addHit(true_scifi_indices_per_layer[i], i);
      //     }
      //   }

      //   // for (int i=0; i<12; ++i) {
      //   //   if (true_scifi_indices_per_layer[i] != -1) {
      //   //     candidate.addHit(true_scifi_indices_per_layer[i]);
      //   //   }
      //   // }

      //   track_candidates.push_back(candidate);
      //   // scifi_tracks.push_back(candidate);
      // }

      // // Find track seeds
      // bool track_match;
      // track_match = select_hits(
      //   UT_state,
      //   ut_tracks.qop[i_veloUT_track],
      //   i_veloUT_track,
      //   scifi_hits,
      //   scifi_hit_count,
      //   3,
      //   track_candidates,
      //   window_stats,
      //   window_params);

      // std::vector<bool> extrapolated_track_candidates (track_candidates.size(), false);

      // // Extrapolate from candidates into tracks
      // propagate_candidates(
      //   7,
      //   scifi_hits,
      //   scifi_hit_count,
      //   UT_state,
      //   track_candidates,
      //   extrapolated_track_candidates,
      //   scifi_tracks,
      //   window_params);

      // // Extrapolate scifi tracks
      // propagate_tracks(
      //   6,
      //   scifi_hits,
      //   scifi_hit_count,
      //   UT_state,
      //   scifi_tracks,
      //   window_params);

      // // Extrapolate from candidates into tracks
      // // Only extrapolate those candidates that were
      // // not extrapolated to layer 7
      // // Note: Maybe not needed
      // propagate_candidates(
      //   6,
      //   scifi_hits,
      //   scifi_hit_count,
      //   UT_state,
      //   track_candidates,
      //   extrapolated_track_candidates,
      //   scifi_tracks,
      //   window_params);

      // for (int i=5; i>=0; --i) {
      //   // Extrapolate scifi tracks
      //   propagate_tracks(
      //     i,
      //     scifi_hits,
      //     scifi_hit_count,
      //     UT_state,
      //     scifi_tracks,
      //     window_params);
      // }

      // Populate trackhits
      for (auto& t : scifi_tracks) {
        if (t.hitsNum >= 9) {
          event_trackhits.push_back(t);
        }
      }

      num_candidates = track_candidates.size();
      number_of_candidates_event += track_candidates.size();
      number_of_track_candidates += track_candidates.size();

      if (window_stats[0].size()) {
        n_total_hits_in_first_window += window_stats[0][0].num_hits;
        n_veloUT_tracks_with_window++;
      }

      if (true_scifi_indices.size() >= 10) {
        n_reconstructible_scifi_tracks_from_ut_tracks++;

        // Fill in some information concerning station 3
        bool is_t3_quadruplet = false;
        if (
          true_scifi_indices_per_layer[8] != -1 && true_scifi_indices_per_layer[9] != -1 &&
          true_scifi_indices_per_layer[10] != -1 && true_scifi_indices_per_layer[11] != -1) {
          is_t3_quadruplet = true;
          n_quadruplets++;
        }

        bool is_t3_triplet = false;
        if (
          !is_t3_quadruplet && true_scifi_indices_per_layer[8] != -1 && true_scifi_indices_per_layer[11] != -1 &&
          (true_scifi_indices_per_layer[9] != -1 || true_scifi_indices_per_layer[10] != -1)) {
          is_t3_triplet = true;
          n_triplets++;
        }

        if (is_t3_quadruplet) {
          true_x_t3 = scifi_hits.x0[true_scifi_indices_per_layer[8]];
          x_extrap_t3 = SciFi_state_T3.x;
          y_extrap_t3 = SciFi_state_T3.y;
          tyf_t3 = SciFi_state_T3.ty;
          txf_t3 = SciFi_state_T3.tx;
          // t_extrap_T3->Fill();
        }

        if (
          (is_t3_quadruplet || is_t3_triplet) && window_stats.size() > 0 && window_stats[0].size() > 0 &&
          scifi_hits.x0[true_scifi_indices_per_layer[8]] < window_stats[0][0].x_max &&
          scifi_hits.x0[true_scifi_indices_per_layer[8]] > window_stats[0][0].x_min) {
          n_hits_in_first_window++;
        }

        // if (track_match) {
        //   layer8_win_size = window_stats[0][0].x_max - window_stats[0][0].x_min;
        //   layer8_win_pop = window_stats[0][0].num_hits;
        //   t_extrap_T3->Fill();
        // }

        for (int i = 0; i < 12; ++i) {
          if (true_scifi_indices_per_layer[i] != -1) {
            n_layer[i]++;
          }
        }

        // Check the efficiency of the algorithm declared above
        if (is_t3_quadruplet || is_t3_triplet) {
          std::array<bool, 12> found {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

          // Find best candidate (one matching more hits)
          int best_candidate = -1;
          int highest_match = 0;
          for (int i_candidate = 0; i_candidate < scifi_tracks.size(); ++i_candidate) {
            const auto candidate = scifi_tracks[i_candidate];
            int matched_hits = 0;
            quality = candidate.quality;
            t_track_candidates->Fill();
            for (int i = 0; i < candidate.hitsNum; ++i) {
              const auto hit = candidate.hits[i];
              if (
                std::find(std::begin(true_scifi_indices), std::end(true_scifi_indices), hit) !=
                std::end(true_scifi_indices)) {
                matched_hits++;
              }
              if (matched_hits > highest_match) {
                highest_match = matched_hits;
                best_candidate = i_candidate;
              }
            }
          }

          if (highest_match >= 10) {
            n_reconstructible_found_tracks++;
          }

          if (best_candidate != -1) {
            const auto candidate = scifi_tracks[best_candidate];
            for (int i = 0; i < candidate.hitsNum; ++i) {
              const auto hit = candidate.hits[i];
              for (int j = 0; j < 12; ++j) {
                if (hit == true_scifi_indices_per_layer[j]) {
                  found[j] = true;
                }
              }
            }
            for (int i = 0; i < 12; ++i) {
              if (found[i]) {
                n_found_hits[i]++;
              }
              if (n_layer[i]) {
                n_layer_with_T3_quad_triplets[i]++;
              }
            }
          }

          float reco_slope =
            (scifi_hits.x0[true_scifi_indices_per_layer[11]] - scifi_hits.x0[true_scifi_indices_per_layer[8]]) /
            SciFi::LookingForward::dz_x_layers;

          float updated_qop = qop_update(
            UT_state,
            scifi_hits.x0[true_scifi_indices_per_layer[8]],
            scifi_hits.x0[true_scifi_indices_per_layer[11]],
            8,
            11,
            8);

          const auto x_at_layer_8 = scifi_hits.x0[true_scifi_indices_per_layer[8]];

          // We need a new lambda to compare in chi2
          const auto chi2_fn = [&x_at_layer_8, &reco_slope, &updated_qop](const float z) {
            return scifi_propagation(x_at_layer_8, reco_slope, updated_qop, z - SciFi::LookingForward::Zone_zPos[8]);
          };

          std::vector<float> x_coordinates_full_track;
          std::vector<float> z_coordinates_full_track;
          int total_number_of_hits_track = 0;
          for (int i = 0; i < 12; ++i) {
            if (true_scifi_indices_per_layer[i] != -1) {
              total_number_of_hits_track++;
              z_coordinates_full_track.push_back(SciFi::LookingForward::Zone_zPos[i]);

              const float real_x = scifi_hits.x0[true_scifi_indices_per_layer[i]];
              const auto projection_y = y_at_z(UT_state, SciFi::LookingForward::Zone_zPos[i]);
              x_coordinates_full_track.push_back(real_x + projection_y * SciFi::LookingForward::Zone_dxdy[(i % 4)]);
            }
          }
          chi2_track = get_chi_2(z_coordinates_full_track, x_coordinates_full_track, chi2_fn) /
                       ((float) total_number_of_hits_track);

          for (int k = 0; k < 8; k++) {
            if (true_scifi_indices_per_layer[k] != -1) {
              const float real_x = scifi_hits.x0[true_scifi_indices_per_layer[k]];

              const auto projection_y = y_at_z(UT_state, SciFi::LookingForward::Zone_zPos[k]);
              const auto projection_x = scifi_propagation(
                                          x_at_layer_8,
                                          reco_slope,
                                          updated_qop,
                                          SciFi::LookingForward::Zone_zPos[k] - SciFi::LookingForward::Zone_zPos[8]) -
                                        SciFi::LookingForward::Zone_dxdy[k % 4] * projection_y;

              forwarding_res[k] = (projection_x - real_x); // real_x;

              std::vector<float> x_coordinates {x_at_layer_8,
                                                scifi_hits.x0[true_scifi_indices_per_layer[11]],
                                                real_x + projection_y * SciFi::LookingForward::Zone_dxdy[(k % 4)]};

              std::vector<float> z_coordinates {SciFi::LookingForward::Zone_zPos[8],
                                                SciFi::LookingForward::Zone_zPos[11],
                                                SciFi::LookingForward::Zone_zPos[k]};

              forwarding_chi2[k] = get_chi_2(z_coordinates, x_coordinates, chi2_fn);
            }
            else {
              forwarding_chi2[k] = 0.f;
              forwarding_res[k] = 0.f;
            }
          }

          qop_resolution_after_update_t3 = (updated_qop - 1 / p_true) * p_true;
          qop_update_t3 = updated_qop;
          t_good_tracks->Fill();
        }
      }
    } // extrapolation to T3 worked

    // info_cout << "Event " << i_event << ", number of candidates: " << number_of_candidates_event << std::endl;

    trackhits.emplace_back(event_trackhits);

#ifdef WITH_ROOT
    t_ut_tracks->Fill();
#endif
  } // loop over veloUT tracks

  uint total_number_of_tracks_found = 0;
  for (const auto& t : trackhits) {
    total_number_of_tracks_found += t.size();
  }

  const auto t3_quads_triplets = n_triplets + n_quadruplets;

  const auto print_nice = [](const std::string& name, const int value, const int denominator) {
    info_cout << name << ": " << value << " (" << (100.f * value) / ((float) denominator) << "%)" << std::endl;
  };

  info_cout << "Number of UT tracks: " << n_veloUT_tracks << std::endl;

  print_nice(
    "Number of reconstructible forward tracks coming from found UT tracks",
    n_reconstructible_scifi_tracks_from_ut_tracks,
    n_veloUT_tracks);

  for (int i = 0; i < 12; ++i) {
    print_nice(
      "Number of tracks with layer " + std::to_string(i) + " populated",
      n_layer[i],
      n_reconstructible_scifi_tracks_from_ut_tracks);
  }

  info_cout << std::endl;

  print_nice("Number of T3 quadruplets", n_quadruplets, n_reconstructible_scifi_tracks_from_ut_tracks);
  print_nice(
    "Number of T3 triplets with hits on both x layers (does not include quadruplets)",
    n_triplets,
    n_reconstructible_scifi_tracks_from_ut_tracks);

  info_cout << std::endl << "-- Algorithm specific --" << std::endl;

  print_nice(
    "Number of tracks with a hit in the layer 8 window, out of T3 quads", n_hits_in_first_window, t3_quads_triplets);
  print_nice(
    "Found out of reconstructible tracks",
    n_reconstructible_found_tracks,
    n_reconstructible_scifi_tracks_from_ut_tracks);

  print_nice("Found out of T3 quadruplets and triplets", n_reconstructible_found_tracks, t3_quads_triplets);
  print_nice("Found out of T3 quadruplets", n_reconstructible_found_tracks, n_quadruplets);

  for (int i = 0; i < 12; ++i) {
    print_nice(
      "Number of hits found in layer " + std::to_string(i) + ", out of T3 quads and triplets",
      n_found_hits[i],
      n_layer_with_T3_quad_triplets[i]);
  }

  info_cout << "Number of candidates per ut velo track: " << number_of_track_candidates / ((float) n_veloUT_tracks)
            << std::endl;

  info_cout << "Number of candidates in first window per ut velo track: "
            << n_total_hits_in_first_window / ((float) n_veloUT_tracks_with_window) << std::endl;

  info_cout << "Total number of candidates in " << number_of_events << " events: " << number_of_track_candidates
            << std::endl;

  info_cout << "Total number of tracks found with >=10 hits: " << total_number_of_tracks_found
            << ", average per event: " << total_number_of_tracks_found / ((float) number_of_events) << std::endl;

  info_cout << std::endl;

#ifdef WITH_ROOT
  f->Write();
  f->Close();
#endif

  return trackhits;
}

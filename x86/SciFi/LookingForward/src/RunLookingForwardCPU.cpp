#include "RunLookingForwardCPU.h"

#include "SciFiParametrization.h"
#include "MomentumForwardConstants.h"

#ifdef WITH_ROOT
#include "TH1D.h"
#include "TFile.h"
#include "TTree.h"
#endif

int run_looking_forward_CPU(
  SciFi::TrackHits* host_scifi_tracks,
  int* host_scifi_n_tracks,
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
  const uint number_of_events)
{

#ifdef WITH_ROOT
  TFile* f = new TFile("../output/scifi_momentum_forward.root", "RECREATE");
  TTree* t_quadruplets = new TTree("quadruplets", "quadruplets");
  TTree* t_tracks = new TTree("tracks", "tracks");
  TTree* t_T1_x = new TTree("T1_x", "T1_x");
  TTree* t_extrap = new TTree("extrap", "extrap");

  int b_n_quadruplets;
  int n_tracks;
  float dx_x_layers_T1, b_qop_update;
  float b_qop, dx_extrap_hit;
  t_quadruplets->Branch("n_quadruplets", &b_n_quadruplets);
  t_tracks->Branch("n_tracks", &n_tracks);
  t_T1_x->Branch("dx_x_layers_T1", &dx_x_layers_T1);
  t_T1_x->Branch("qop_update", &b_qop_update);
  t_extrap->Branch("dx_extrap_hit", &dx_extrap_hit);
  t_extrap->Branch("qop", &b_qop);
#endif

  // initialize parameters
  char name_coef_T1[200] = "../input/UT_T1_shift_50_tilt_new.tab";
  debug_cout << "Reading coefs for extrapolation to T1: " << name_coef_T1 << std::endl;
  SciFi::Parameters scifi_params_T1 = SciFi::Parameters(name_coef_T1);

  int n_veloUT_tracks = 0;
  int n_extrap_T1 = 0;

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
    int* n_forward_tracks_event = host_scifi_n_tracks + i_event;
    *n_forward_tracks_event = 0;
    SciFi::TrackHits* scifi_tracks_event = host_scifi_tracks + i_event * SciFi::Constants::max_tracks;

    const uint total_number_of_hits = host_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
    SciFi::HitCount scifi_hit_count {(uint32_t*) host_scifi_hit_count, i_event};
    const uint event_hit_offset = scifi_hit_count.event_offset();

    const SciFi::SciFiGeometry scifi_geometry(host_scifi_geometry);

    SciFi::Hits scifi_hits(
      (uint*) host_scifi_hits,
      total_number_of_hits,
      &scifi_geometry,
      reinterpret_cast<const float*>(host_inv_clus_res.data()));

    // extrapolate veloUT tracks
    float tx, ty, qop;

    for (int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track) {
      int n_quadruplets = 0;
      SciFi::MomentumForward::Track quadruplets[SciFi::MomentumForward::max_quadruplets];

      // veloUT track variables
      const float qop = ut_tracks.qop[i_veloUT_track];
      const int i_velo_track = ut_tracks.velo_track[i_veloUT_track];
      const MiniState velo_state {velo_states, velo_event_tracks_offset + i_velo_track};
      const int ut_track_index = ut_event_tracks_offset + i_veloUT_track;
      const float ut_x = host_ut_x[ut_track_index];
      const float ut_tx = host_ut_tx[ut_track_index];
      const float ut_z = host_ut_z[ut_track_index];

      // extrapolate velo y & ty to z of UT x and tx
      // use ty from Velo state
      MiniState state_UT;
      state_UT.x = ut_x;
      state_UT.tx = ut_tx;
      state_UT.z = ut_z;
      state_UT.ty = velo_state.ty;
      state_UT.y = y_at_z(velo_state, ut_z);

      // extrapolate to last UT plane (the UT state can be at the third or fourth plane)
      // the extrapolation starts from the last UT plane
      MiniState UT_state = state_at_z(state_UT, SciFi::MomentumForward::z_last_UT_plane);

      // propagation to first layer of T1
      int n_hits_in_window_l0 = 0;
      float xf_t1, yf_t1, txf_t1, tyf_t1, der_xf_qop_t1;
      int ret = extrap(
        UT_state.x,
        UT_state.y,
        UT_state.tx,
        UT_state.ty,
        qop,
        scifi_params_T1,
        xf_t1,
        yf_t1,
        txf_t1,
        tyf_t1,
        der_xf_qop_t1);

      if (!ret) continue;
      n_extrap_T1++;

      //=====================
      // Look for hits in T1
      //====================
      // access hits in first layer of T1, layer 0 = zone 0 (y < 0) + zone 1 (y > 0)
      int x_zone_offset, n_hits_x;
      get_offset_and_n_hits_for_layer(0, scifi_hit_count, yf_t1, n_hits_x, x_zone_offset);
      // access hits in last layer of T1, layer 3 = zone 6 (y < 0) + zone 7 (y > 0)
      int n_hits_x_other, x_zone_offset_other;
      get_offset_and_n_hits_for_layer(6, scifi_hit_count, yf_t1, n_hits_x_other, x_zone_offset_other);
      // access hits in u-layer of T1, layer 1 = zone 2 (y < 0) + zone 3 (y > 0)
      int n_hits_u, x_zone_offset_u;
      get_offset_and_n_hits_for_layer(2, scifi_hit_count, yf_t1, n_hits_u, x_zone_offset_u);
      // access hits in v-layer of T1, layer 1 = zone 4 (y < 0) + zone 5 (y > 0)
      int n_hits_v, x_zone_offset_v;
      get_offset_and_n_hits_for_layer(4, scifi_hit_count, yf_t1, n_hits_v, x_zone_offset_v);

      // Variables for cut on x difference between hits of the two
      // x layers
      float slope1, slope2;
      if (qop < 0) {
        slope1 = SciFi::MomentumForward::x_diff_layer_qop_slope_a;
        slope2 = SciFi::MomentumForward::x_diff_layer_qop_slope_b;
      }
      else {
        slope1 = SciFi::MomentumForward::x_diff_layer_qop_slope_b;
        slope2 = SciFi::MomentumForward::x_diff_layer_qop_slope_a;
      }

      bool max_quadruplets = false;
      // loop over hits in first x layer of T1 (layer 0)
      for (int i_hit = 0; i_hit < n_hits_x; ++i_hit) {
        const int hit_index_0 = x_zone_offset + i_hit;
        const float x_1 = scifi_hits.x0[hit_index_0];
        // cut on difference between extrapolated x position and hit
        if (
          fabsf(x_1 - xf_t1) >
          SciFi::MomentumForward::dx_extrap_qop_offset_T1 + SciFi::MomentumForward::dx_extrap_qop_slope_T1 * fabsf(qop))
          continue;
        n_hits_in_window_l0++;
#ifdef WITH_ROOT
        dx_extrap_hit = x_1 - xf_t1;
        b_qop = qop;
        t_extrap->Fill();
#endif

        // Update qop estimate
        float qop_update;
        int ret_qop = update_qop_estimate(
          UT_state, qop, x_1, scifi_params_T1, xf_t1, yf_t1, txf_t1, tyf_t1, der_xf_qop_t1, qop_update);

        // loop over other x layer of T1 (layer 3)
        for (int i_hit_other = 0; i_hit_other < n_hits_x_other; ++i_hit_other) {
          const int hit_index_3 = x_zone_offset_other + i_hit_other;
          const float x_3 = scifi_hits.x0[hit_index_3];
          int best_hit_index_3;
          float best_dx_3 = 1.e9;
          // cut on difference between hits on the two x layers of T1
          if (
            x_1 - x_3 > SciFi::MomentumForward::x_diff_layer_qop_offset - slope1 * qop_update ||
            x_1 - x_3 < -1.f * SciFi::MomentumForward::x_diff_layer_qop_offset - slope2 * qop_update)
            continue;

#ifdef WITH_ROOT
          dx_x_layers_T1 = x_1 - x_3;
          b_qop_update = qop_update;
          t_T1_x->Fill();
#endif

          // cut on difference of tx from the two hits and from the extrapolation
          // tx (dx/dz) of the two x hits
          const float tx_x_hits_t1 = (x_3 - x_1) / SciFi::MomentumForward::dz_x_layers;
          if (std::abs(tx_x_hits_t1 - txf_t1) > SciFi::MomentumForward::max_tx_diff) continue;

          // predict x in u and v layer based on tx of x hits
          const float x_at_u = x_1 + tx_x_hits_t1 * SciFi::MomentumForward::dz_x_u_layers;
          const float x_at_v = x_1 + tx_x_hits_t1 * SciFi::MomentumForward::dz_x_v_layers;

          // loop over hits in u-layer (layer 1)
          for (int i_hit_u = 0; i_hit_u < n_hits_u; ++i_hit_u) {
            const int hit_index_1 = x_zone_offset_u + i_hit_u;
            float x_hit_u = scifi_hits.x0[hit_index_1] + yf_t1 * scifi_hits.dxdy(hit_index_1);

            // cut on x difference of u-hit and x from tx of the x hits
            if (std::abs(x_hit_u - x_at_u) > SciFi::MomentumForward::dx_x_uv_layers) continue;
            // loop over hits in v-layer (layer 2)
            for (int i_hit_v = 0; i_hit_v < n_hits_v; ++i_hit_v) {
              const int hit_index_2 = x_zone_offset_v + i_hit_v;
              float x_hit_v = scifi_hits.x0[hit_index_2] + yf_t1 * scifi_hits.dxdy(hit_index_2);

              // cut on x difference of v-hit and x from tx of the x hits
              if (std::abs(x_hit_v - x_at_v) > SciFi::MomentumForward::dx_x_uv_layers) continue;
              // found quadruplet!! :-)
              SciFi::MomentumForward::Track quadruplet;
              quadruplet.addHit(hit_index_0);
              quadruplet.addHit(hit_index_1);
              quadruplet.addHit(hit_index_2);
              quadruplet.addHit(hit_index_3);
              quadruplet.tx = tx_x_hits_t1;
              quadruplet.qop = qop_update;

              n_quadruplets++;
              // assert( n_quadruplets < SciFi::MomentumForward::max_quadruplets );
              // quadruplets[n_quadruplets++] = quadruplet;
              // if ( n_quadruplets >= SciFi::MomentumForward::max_quadruplets ) {
              //   max_quadruplets = true;
              //   break;
              //}
            } // loop over hits in layer 2
            // if ( max_quadruplets ) break;
          } // loop over hits in layer 1
          // if ( max_quadruplets ) break;
        } // loop over hits in layer 3
        // if ( max_quadruplets ) break;
      } // loop over hits in layer 0
#ifdef WITH_ROOT
      b_n_quadruplets = n_quadruplets;
      t_quadruplets->Fill();
#endif
      //=======================
      // Look for hits in T2
      //=======================
      // access hits in first layer of T2, layer 4 = zone 8 (y < 0) + zone 9 (y > 0)
      get_offset_and_n_hits_for_layer(8, scifi_hit_count, yf_t1, n_hits_x, x_zone_offset);
      // access hits in last layer of T2, layer 7 = zone 14 (y < 0) + zone 15 (y > 0)
      get_offset_and_n_hits_for_layer(14, scifi_hit_count, yf_t1, n_hits_x_other, x_zone_offset_other);
      // access hits in u-layer of T2, layer 5 = zone 10 (y < 0) + zone 11 (y > 0)
      get_offset_and_n_hits_for_layer(10, scifi_hit_count, yf_t1, n_hits_u, x_zone_offset_u);
      // access hits in v-layer of T2, layer 6 = zone 12 (y < 0) + zone 13 (y > 0)
      get_offset_and_n_hits_for_layer(12, scifi_hit_count, yf_t1, n_hits_v, x_zone_offset_v);

      // Loop over quadruplets

    } // veloUT tracks

    int zone_offset, n_hits;
    get_offset_and_n_hits_for_layer(0, scifi_hit_count, -1., n_hits, zone_offset);
    debug_cout << "n_hits zone 0 = " << n_hits << std::endl;
    get_offset_and_n_hits_for_layer(0, scifi_hit_count, 1., n_hits, zone_offset);
    debug_cout << "n_hits zone 1 = " << n_hits << std::endl;
    get_offset_and_n_hits_for_layer(2, scifi_hit_count, -1., n_hits, zone_offset);
    debug_cout << "n_hits zone 2 = " << n_hits << std::endl;
    get_offset_and_n_hits_for_layer(2, scifi_hit_count, 1., n_hits, zone_offset);
    debug_cout << "n_hits zone 3 = " << n_hits << std::endl;
#ifdef WITH_ROOT
    n_tracks = *n_forward_tracks_event;
    t_tracks->Fill();
#endif
    assert(*n_forward_tracks_event < SciFi::Constants::max_tracks);
    debug_cout << "In event " << i_event << ": number of tracks = " << *n_forward_tracks_event << std::endl;
  } // events

  info_cout << "Tracking: Extrapolation to T1 worked: " << float(n_extrap_T1) / n_veloUT_tracks << std::endl;

#ifdef WITH_ROOT
  f->Write();
  f->Close();
#endif

  return 0;
}

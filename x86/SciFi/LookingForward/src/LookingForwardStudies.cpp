#include "LookingForwardStudies.h"

#ifdef WITH_ROOT
#include "TH1D.h"
#include "TFile.h"
#include "TTree.h"
#endif


int momentum_forward_studies(
  const uint* host_scifi_hits,
  const uint* host_scifi_hit_count,
  const char* host_scifi_geometry,
  const std::array<float, 9>& host_inv_clus_res,
  const uint* host_velo_tracks_atomics,
  const uint* host_velo_track_hit_number,
  const char* host_velo_states,
  const int * host_atomics_ut,
  const uint* host_ut_track_hit_number,
  const float* host_ut_qop,
  const float* host_ut_x,
  const float* host_ut_tx,
  const float* host_ut_z,
  const uint* host_ut_track_velo_indices,
  const std::vector< std::vector< std::vector< uint32_t > > > scifi_ids_ut_tracks,
  const std::vector< std::vector< float > > p_events,
  const uint number_of_events
) {

  // initialize parameters
  //char name_coef_T1[200] = "../input/test_UT_T1.tab";
  char name_coef_T1[200] = "../input/UT_T1_shift_50_tilt_new.tab";
  debug_cout << "Reading coefs for extrapolation to T1: " << name_coef_T1 << std::endl;
  SciFi::Parameters scifi_params_T1 = SciFi::Parameters(name_coef_T1);
  
  char name_coef_T3[200] = "../input/test_UT_T3.tab";
  debug_cout << "Reading coefs for extrapolation to T3: " << name_coef_T3 << std::endl;
  SciFi::Parameters scifi_params_T3 = SciFi::Parameters(name_coef_T3);

#ifdef WITH_ROOT
  // Histograms only for checking and debugging
  TFile *f = new TFile("../output/scifi.root", "RECREATE");
  TTree *t_scifi_hits = new TTree("scifi_hits","scifi_hits");
  TTree *t_extrap_T1 = new TTree("extrap_T1","extrap_T1");
  TTree *t_extrap_T3 = new TTree("extrap_T3","extrap_T3");
  TTree *t_ut_tracks = new TTree("ut_tracks","ut_tracks");
  TTree* t_other_x_layer_t1 = new TTree("other_x_layer_T1","other_x_layer_T1");
  TTree* t_other_x_layer_t3 = new TTree("other_x_layer_T3","other_x_layer_T3");
  
  uint planeCode, LHCbID;
  float x0, z0, w, dxdy, dzdy, yMin, yMax;
  float qop;
  int n_tracks;
  float state_x, state_y, state_z, state_tx, state_ty;
  float xf_t1, yf_t1, txf_t1, tyf_t1, der_xf_qop_t1, qop_update_t1;
  float res_x_0_t1, res_x_3_t1, dx_t1, x_extrap_t1, true_x_t1, res_x_other_t1, true_z_t1;
  float true_x_t1_other;
  float UT_x, UT_y, UT_z, UT_tx, UT_ty, ut_qop;
  float velo_x_extrap, velo_tx;
  int n_hits_in_window_0_t1 = 0, n_hits_in_window_0_t1_true_p = 0, n_hits_in_window_3_t1 = 0;
  int n_hits_in_zone_t1 = 0, n_hits_in_window_other_t1 = 0, n_hits_in_window_other_t1_tx = 0;
  float p_diff_before_update_t1, p_diff_after_update_t1, p_diff_before_after_t1, p_resolution_after_update_t1;
  float qop_diff_before_update_t1, qop_diff_after_update_t1, qop_diff_before_after_t1, qop_resolution_after_update_t1;
  float tx_x_hits_t1, res_x_u_t1, res_x_v_t1, res_x_u_slope_t1, res_x_v_slope_t1;
  float res_x_T2_0, res_x_T2_3, res_x_T3_0, res_x_T3_3;

  float xf_t3, yf_t3, txf_t3, tyf_t3, der_xf_qop_t3, qop_update_t3;
  float res_x_0_t3, res_x_3_t3, dx_t3, x_extrap_t3, true_x_t3, res_x_other_t3;;
  int n_hits_in_window_0_t3 = 0, n_hits_in_window_0_t3_true_p = 0, n_hits_in_window_3_t3 = 0;
  int n_hits_in_zone_t3 = 0, n_hits_in_window_other_t3 = 0;
  float p_diff_before_update_t3, p_diff_after_update_t3, p_resolution_after_update_t3;
  float qop_diff_before_update_t3, qop_diff_after_update_t3, qop_diff_before_after_t3, qop_resolution_after_update_t3;
  float tx_x_hits_t3;

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

  t_extrap_T1->Branch("xf", &xf_t1);
  t_extrap_T1->Branch("yf", &yf_t1);
  t_extrap_T1->Branch("txf", &txf_t1);
  t_extrap_T1->Branch("tyf", &tyf_t1);
  t_extrap_T1->Branch("der_xf_qop", &der_xf_qop_t1);
  t_extrap_T1->Branch("res_x_0", &res_x_0_t1);
  t_extrap_T1->Branch("res_x_other", &res_x_other_t1);
  t_extrap_T1->Branch("true_x", &true_x_t1);
  t_extrap_T1->Branch("true_z", &true_z_t1);
  t_extrap_T1->Branch("x_extrap", &x_extrap_t1);
  t_extrap_T1->Branch("dx", &dx_t1);
  t_extrap_T1->Branch("qop_update", &qop_update_t1);
  t_extrap_T1->Branch("p_diff_before_update", &p_diff_before_update_t1);
  t_extrap_T1->Branch("p_diff_after_update", &p_diff_after_update_t1);
  t_extrap_T1->Branch("p_resolution_after_update", &p_resolution_after_update_t1);
  t_extrap_T1->Branch("qop_diff_before_update", &qop_diff_before_update_t1);
  t_extrap_T1->Branch("qop_diff_after_update", &qop_diff_after_update_t1);
  t_extrap_T1->Branch("qop_resolution_after_update", &qop_resolution_after_update_t1);
  t_extrap_T1->Branch("n_hits_in_window_0", &n_hits_in_window_0_t1);
  t_extrap_T1->Branch("n_hits_in_zone", &n_hits_in_zone_t1);
  t_extrap_T1->Branch("isLong", &isLong);
  t_extrap_T1->Branch("p_true", &p_true);
  t_extrap_T1->Branch("match", &match_t1);
  t_extrap_T1->Branch("match_other", &match_t1_other);
  t_extrap_T1->Branch("ut_qop", &ut_qop);
  t_extrap_T1->Branch("tx_x_hits", &tx_x_hits_t1);
  t_extrap_T1->Branch("res_x_u", &res_x_u_t1);
  t_extrap_T1->Branch("res_x_u_slope", &res_x_u_slope_t1);
  t_extrap_T1->Branch("match_u", &match_t1_u);
  t_extrap_T1->Branch("res_x_v", &res_x_v_t1);
  t_extrap_T1->Branch("res_x_v_slope", &res_x_v_slope_t1);
  t_extrap_T1->Branch("match_v", &match_t1_v);
  t_extrap_T1->Branch("match_T2_0", &match_T2_0);
  t_extrap_T1->Branch("match_T2_3", &match_T2_3);
  t_extrap_T1->Branch("res_x_T2_0", &res_x_T2_0);
  t_extrap_T1->Branch("res_x_T2_3", &res_x_T2_3);
  t_extrap_T1->Branch("match_T3_0", &match_T3_0);
  t_extrap_T1->Branch("match_T3_3", &match_T3_3);
  t_extrap_T1->Branch("res_x_T3_0", &res_x_T3_0);
  t_extrap_T1->Branch("res_x_T3_3", &res_x_T3_3);

  
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
  t_extrap_T3->Branch("tx_x_hits", &tx_x_hits_t3);
  t_extrap_T3->Branch("match", &match_t3);
  t_extrap_T3->Branch("match_other", &match_t3_other);
  
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

  t_other_x_layer_t1->Branch("n_hits_in_window_other", &n_hits_in_window_other_t1);
  t_other_x_layer_t1->Branch("n_hits_in_window_other_tx", &n_hits_in_window_other_t1_tx);

  t_other_x_layer_t3->Branch("n_hits_in_window_other", &n_hits_in_window_other_t3);
#endif

  int n_veloUT_tracks = 0;
  int n_extrap_T1 = 0;
  int n_extrap_T3 = 0;
  
  ofstream output_pierre;
  output_pierre.open("output_pierre.txt"); 

  for ( uint i_event = 0; i_event < number_of_events; ++i_event ) {

    // Velo consolidated types
    const Velo::Consolidated::Tracks velo_tracks {(uint*) host_velo_tracks_atomics, (uint*)host_velo_track_hit_number, i_event, number_of_events};
    const uint velo_event_tracks_offset = velo_tracks.tracks_offset(i_event);
    const Velo::Consolidated::States velo_states {(char*)host_velo_states, velo_tracks.total_number_of_tracks};

    // UT consolidated types
    UT::Consolidated::Tracks ut_tracks {
     (uint*)host_atomics_ut,
     (uint*)host_ut_track_hit_number,
     (float*)host_ut_qop,
     (uint*)host_ut_track_velo_indices,
      i_event,
      number_of_events
      };
    const int n_veloUT_tracks_event = ut_tracks.number_of_tracks(i_event);
    const int ut_event_tracks_offset = ut_tracks.tracks_offset(i_event);
    n_veloUT_tracks += n_veloUT_tracks_event;
  
    // SciFi non-consolidated types
    const uint total_number_of_hits = host_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats]; 
    SciFi::HitCount scifi_hit_count {(uint32_t*)host_scifi_hit_count, i_event};
    
    const SciFi::SciFiGeometry scifi_geometry(host_scifi_geometry);
    
    SciFi::Hits scifi_hits(
     (uint*)host_scifi_hits,
     total_number_of_hits,
     &scifi_geometry, 
     reinterpret_cast<const float*>(host_inv_clus_res.data()));

#ifdef WITH_ROOT
    // store hit variables in tree
    for(size_t zone = 0; zone < SciFi::Constants::n_zones; zone++) {
      const auto zone_offset = scifi_hit_count.zone_offset(zone);
      for(size_t hit = 0; hit < scifi_hit_count.zone_number_of_hits(zone); hit++) {
        const auto hit_offset = zone_offset + hit;

        planeCode = scifi_hits.planeCode(hit_offset);
        LHCbID = scifi_hits.LHCbID(hit_offset);
        x0 = scifi_hits.x0[hit_offset];
        z0 = scifi_hits.z0[hit_offset];
        w  = scifi_hits.w(hit_offset);
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
    float tx,ty,qop;

    for(int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track ) {
      // veloUT track variables
      const float qop = ut_tracks.qop[i_veloUT_track];
      const int i_velo_track = ut_tracks.velo_track[i_veloUT_track];
      const MiniState velo_state {velo_states, velo_event_tracks_offset + i_velo_track};
      const int ut_track_index = ut_event_tracks_offset + i_veloUT_track;
      const float ut_x  = host_ut_x[ut_track_index];
      const float ut_tx = host_ut_tx[ut_track_index];
      const float ut_z  = host_ut_z[ut_track_index];

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
      MiniState UT_state_from_velo = state_at_z(velo_state, SciFi::MomentumForward::z_last_UT_plane);
      MiniState UT_state = state_at_z(state_UT, SciFi::MomentumForward::z_last_UT_plane);
           
      t1_extrap_worked = false;
      t3_extrap_worked = false;
      isLong = false;
      match_t1 = false;
      match_t3 = false;
      n_hits_in_window_0_t1 = 0;
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
#endif

      // propagation to first layer of T1
      int ret = extrap(
        UT_state.x, UT_state.y,
        UT_state.tx, UT_state.ty,
        qop, scifi_params_T1,
        xf_t1, yf_t1, txf_t1, tyf_t1, der_xf_qop_t1);
      
      if ( ret ) {
        n_extrap_T1++;
        t1_extrap_worked = true;
        
        // access hits in first layer of T1, layer 0 = zone 0 (y < 0) + zone 1 (y > 0)
        int x_zone_offset, n_hits;
        get_offset_and_n_hits_for_layer(0, scifi_hit_count, yf_t1, n_hits, x_zone_offset);

        // access hits in last layer of T1, layer 3 = zone 6 (y < 0) + zone 7 (y > 0)
        int n_hits_other, x_zone_offset_other;
        get_offset_and_n_hits_for_layer(6, scifi_hit_count, yf_t1, n_hits_other, x_zone_offset_other);

        // access hits in u-layer of T1, layer 1 = zone 2 (y < 0) + zone 3 (y > 0)
        int n_hits_u, x_zone_offset_u;
        get_offset_and_n_hits_for_layer(2, scifi_hit_count, yf_t1, n_hits_u, x_zone_offset_u);

        // access hits in v-layer of T1, layer 1 = zone 4 (y < 0) + zone 5 (y > 0)
        int n_hits_v, x_zone_offset_v;
        get_offset_and_n_hits_for_layer(4, scifi_hit_count, yf_t1, n_hits_v, x_zone_offset_v);
        
        // find x hit(s) in layer 0 that 
        // were truth matched to the veloUT track
        if ( true_scifi_ids.size() > 0 ) {
          isLong = true;
          match_t1 = false;
          for ( const auto true_id : true_scifi_ids ) {
            for ( int i_hit = 0; i_hit < n_hits; ++i_hit ) { 
              const int hit_index = x_zone_offset + i_hit;
              const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
              if ( true_id == lhcbid ) {
                res_x_0_t1 = xf_t1 - scifi_hits.x0[hit_index];
                true_x_t1 = scifi_hits.x0[hit_index];
                true_z_t1 = scifi_hits.z0[hit_index];
                x_extrap_t1 = xf_t1 + der_xf_qop_t1 * (xf_t1 - true_x_t1);
                match_t1 = true;
                break;
              }
            }
            if ( match_t1 ) break;
          }
          
          // Update momentum estimate with true x hit position
          // caution: xf, yf etc. are changed in the qop update step
          // -> they are not the same as above when checking the resolution (res_x_0_t1)
          if ( match_t1 ) {

            if ( i_event < 100 ) {
              output_pierre << qop << "\t" << UT_x << "\t" << UT_tx << "\t" << UT_y <<  "\t" << UT_ty << "\t" << UT_z  << "\t" << 1./p_true << "\t" << true_x_t1 << endl;
            }

            int ret_qop = update_qop_estimate(
              UT_state, qop,
              true_x_t1, scifi_params_T1, 
              xf_t1, yf_t1, txf_t1, tyf_t1, der_xf_qop_t1, qop_update_t1);
            
            if ( ret_qop ) {
              // check momentum resolution
              p_diff_after_update_t1 = std::abs(p_true) - std::abs( 1.f/qop_update_t1 );
              p_diff_before_update_t1 = std::abs(p_true) - std::abs( 1.f/qop );
              p_resolution_after_update_t1 = (std::abs(p_true) - std::abs( 1.f/qop_update_t1 )) / std::abs(p_true);
              qop_diff_after_update_t1 = 1./p_true - qop_update_t1;
              qop_diff_before_update_t1 = 1./p_true - qop;
              qop_diff_before_after_t1 = qop - qop_update_t1;
              qop_resolution_after_update_t1 = (1./p_true - qop_update_t1) * p_true;
            }

            // Distance in x to true hit in other x layer of station
            match_t1_other = false;
            for ( const auto true_id : true_scifi_ids ) {
              for ( int i_hit = 0; i_hit < n_hits_other; ++i_hit ) { 
                const int hit_index = x_zone_offset_other + i_hit;
                const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
                if ( true_id == lhcbid ) {
                  true_x_t1_other = scifi_hits.x0[hit_index];
                  res_x_other_t1 = true_x_t1 - true_x_t1_other;
                  match_t1_other = true;
                  tx_x_hits_t1 = (true_x_t1_other - true_x_t1) / SciFi::MomentumForward::dz_x_layers; // dz of x-layers within one station = 210 mm
                  break;
                }
              }
              if ( match_t1_other ) break;
            }
            
            // Check x-resolution in x-layers of T2
            // using a straight line to extrapolate
            if ( match_t1 && match_t1_other ) {
              // first x layer of T2
              const float x_pred_T2_0 = true_x_t1 + tx_x_hits_t1 * SciFi::MomentumForward::dz_x_T1_0_T2_0;
              // second x layer of T2
             const float x_pred_T2_3 = true_x_t1 + tx_x_hits_t1 * SciFi::MomentumForward::dz_x_T1_0_T2_3; 
             // access hits in first layer of T2, layer 4 = zone 8 (y < 0) + zone 9 (y > 0)
             int zone_offset_T2, n_hits_T2;
             get_offset_and_n_hits_for_layer(8, scifi_hit_count, yf_t1, n_hits_T2, zone_offset_T2);
             for ( const auto true_id : true_scifi_ids ) {
               for ( int i_hit = 0; i_hit < n_hits_T2; ++i_hit ) { 
                 const int hit_index = zone_offset_T2 + i_hit;
                 const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
                 if ( true_id == lhcbid ) {
                   float x_hit = scifi_hits.x0[hit_index];
                   res_x_T2_0 = x_hit = x_pred_T2_0;
                   match_T2_0 = true;
                 }
               }
             }
             // access hits in last layer of T2, layer 7 = zone 14 (y < 0) + zone 15 (y > 0)
             get_offset_and_n_hits_for_layer(14, scifi_hit_count, yf_t1, n_hits_T2, zone_offset_T2);
             for ( const auto true_id : true_scifi_ids ) {
               for ( int i_hit = 0; i_hit < n_hits_T2; ++i_hit ) { 
                 const int hit_index = zone_offset_T2 + i_hit;
                 const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
                 if ( true_id == lhcbid ) {
                   float x_hit = scifi_hits.x0[hit_index];
                   res_x_T2_3 = x_hit = x_pred_T2_3;
                   match_T2_3 = true;
                 }
               }
             }
             
             // first x layer of T3
             const float x_pred_T3_0 = true_x_t1 + tx_x_hits_t1 * SciFi::MomentumForward::dz_x_T1_0_T3_0;
             // second x layer of T3
             const float x_pred_T3_3 = true_x_t1 + tx_x_hits_t1 * SciFi::MomentumForward::dz_x_T1_0_T3_3; 
             // access hits in first layer of T3, layer 8 = zone 16 (y < 0) + zone 17 (y > 0)
             int zone_offset_T3, n_hits_T3;
             get_offset_and_n_hits_for_layer(16, scifi_hit_count, yf_t1, n_hits_T3, zone_offset_T3);
             for ( const auto true_id : true_scifi_ids ) {
               for ( int i_hit = 0; i_hit < n_hits_T3; ++i_hit ) { 
                 const int hit_index = zone_offset_T3 + i_hit;
                 const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
                 if ( true_id == lhcbid ) {
                   float x_hit = scifi_hits.x0[hit_index];
                   res_x_T3_0 = x_hit = x_pred_T3_0;
                   match_T3_0 = true;
                 }
               }
             }
             // access hits in last layer of T3, layer 11 = zone 22 (y < 0) + zone 23 (y > 0)
             get_offset_and_n_hits_for_layer(22, scifi_hit_count, yf_t1, n_hits_T3, zone_offset_T3);
             for ( const auto true_id : true_scifi_ids ) {
               for ( int i_hit = 0; i_hit < n_hits_T3; ++i_hit ) { 
                 const int hit_index = zone_offset_T3 + i_hit;
                 const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
                 if ( true_id == lhcbid ) {
                   float x_hit = scifi_hits.x0[hit_index];
                   res_x_T3_3 = x_hit = x_pred_T3_3;
                   match_T3_3 = true;
                 }
               }
             }
            }
          
            // Check y-resolution in u-layer using x(y=0) values
            if ( match_t1_other ) {
              float x_at_u = true_x_t1 + tx_x_hits_t1 * SciFi::MomentumForward::dz_x_u_layers;
              match_t1_u = false;
              for ( const auto true_id : true_scifi_ids ) {
                for ( int i_hit = 0; i_hit < n_hits_u; ++i_hit ) { 
                  const int hit_index = x_zone_offset_u + i_hit;
                  const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
                  if ( true_id == lhcbid ) {
                    float x_hit = scifi_hits.x0[hit_index] + yf_t1 * scifi_hits.dxdy(hit_index);
                    res_x_u_t1 = x_hit - xf_t1;
                    res_x_u_slope_t1 = x_hit - x_at_u;
                    match_t1_u = true;
                    break;
                  }
                }
                if ( match_t1_u ) break;
              }
            }
            
            // Check y-resolution in v-layer using x(y=0) values
            if ( match_t1_other ) {
              float x_at_v = true_x_t1 + tx_x_hits_t1 * SciFi::MomentumForward::dz_x_v_layers;
              match_t1_v = false;
              for ( const auto true_id : true_scifi_ids ) {
                for ( int i_hit = 0; i_hit < n_hits_v; ++i_hit ) { 
                  const int hit_index = x_zone_offset_v + i_hit;
                  const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
                  if ( true_id == lhcbid ) {
                    float x_hit = scifi_hits.x0[hit_index] + yf_t1 * scifi_hits.dxdy(hit_index);
                    res_x_v_t1 = x_hit - xf_t1;
                    res_x_v_slope_t1 = x_hit - x_at_v;
                    match_t1_v = true;
                    break;
                  }
                }
                if ( match_t1_v ) break;
              }
            }
            
          } // match in first layer of T1
        
        } // # of true SciFi IDs > 0
        
        // check combinatorics within search window in layer 0
        float slope1, slope2;
        if ( qop < 0 ) {
          slope1 = SciFi::MomentumForward::x_diff_layer_qop_slope_a;
          slope2 = SciFi::MomentumForward::x_diff_layer_qop_slope_b;
        } else {
          slope1 = -1.f * SciFi::MomentumForward::x_diff_layer_qop_slope_b;
          slope2 = -1.f * SciFi::MomentumForward::x_diff_layer_qop_slope_a;
        }
                        
        for ( int i_hit = 0; i_hit < n_hits; ++i_hit ) { 
          const int hit_index = x_zone_offset + i_hit;
          const float x = scifi_hits.x0[hit_index];
          if ( fabsf(x-xf_t1) < SciFi::MomentumForward::dx_extrap_qop_offset_T1 + SciFi::MomentumForward::dx_extrap_qop_slope_T1 * fabsf(qop) ) {
            n_hits_in_window_0_t1++;
            // check combinatorics in other x-layer of last station
            n_hits_in_window_other_t1 = 0;
            n_hits_in_window_other_t1_tx = 0;
            for ( int i_hit_other = 0; i_hit_other < n_hits_other; ++i_hit_other ) { 
              const int hit_index_other = x_zone_offset_other + i_hit_other;
              const float x_other = scifi_hits.x0[hit_index_other];
              if ( fabsf(x-x_other) < SciFi::MomentumForward::x_diff_layer_qop_offset - slope1 * qop 
                   && fabsf(x-x_other) > -1.f * SciFi::MomentumForward::x_diff_layer_qop_offset - slope2 * qop) {
                n_hits_in_window_other_t1++;
                
                // cut on tx 
                float tx_hits = (x_other-x)/SciFi::MomentumForward::dz_x_layers;
                if ( std::abs(tx_hits - txf_t1) < SciFi::MomentumForward::max_tx_diff)
                  n_hits_in_window_other_t1_tx++;
              }
            }
            t_other_x_layer_t1->Fill();
          }
        }
        n_hits_in_zone_t1 = n_hits;
      
        t_extrap_T1->Fill();
        
      } // extrapolation to T1 worked
      
      
      // extrapolate to last layer of T3 (layer 11)
      ret = extrap(
        UT_state.x, UT_state.y,
        UT_state.tx, UT_state.ty,
        qop, scifi_params_T3,
        xf_t3, yf_t3, txf_t3, tyf_t3, der_xf_qop_t3);
      
      if ( ret ) {
        n_extrap_T3++;
        t3_extrap_worked = true;
        
        
        // Access hits in last layer of T3: layer 11 = zone 22 (y < 0) + zone 23 (y > 0)
        int x_zone_offset, n_hits;
        get_offset_and_n_hits_for_layer(22, scifi_hit_count, yf_t3, n_hits, x_zone_offset);
        
        // Access hits in first layer of T3, layer 8 = zone 16 (y < 0) + zone 17 (y > 0)
        int x_zone_offset_other, n_hits_other;
        get_offset_and_n_hits_for_layer(16, scifi_hit_count, yf_t3, n_hits_other, x_zone_offset_other);
        // find x hit(s) in layer 11 that 
        // were truth matched to the veloUT track
        if ( true_scifi_ids.size() > 0 ) {
          match_t3 = false;
          for ( const auto true_id : true_scifi_ids ) {
            for ( int i_hit = 0; i_hit < n_hits; ++i_hit ) { 
              const int hit_index = x_zone_offset + i_hit;
              const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
              if ( true_id == lhcbid ) {
                res_x_0_t3 = xf_t3 - scifi_hits.x0[hit_index];
                true_x_t3 = scifi_hits.x0[hit_index];
                x_extrap_t3 = xf_t3 + der_xf_qop_t3 * (xf_t3 - true_x_t3);
                match_t3 = true;
                break;
              }
            }
            if ( match_t3 ) break;
          }
        
          // Update momentum estimate with true x hit position
          if ( match_t3 ) {
            int ret_qop = update_qop_estimate(
              UT_state, qop,
              true_x_t3, scifi_params_T3, 
              xf_t3, yf_t3, txf_t3, tyf_t3, der_xf_qop_t3, qop_update_t3);
            
            if ( ret_qop ) {
              // check momentum resolution
              p_diff_after_update_t3 = std::abs(p_true) - std::abs( 1.f/qop_update_t3 );
              p_diff_before_update_t3 = std::abs(p_true) - std::abs( 1.f/qop );
              p_resolution_after_update_t3 = (std::abs(p_true) - std::abs( 1.f/qop_update_t3 )) / std::abs(p_true);
              qop_diff_after_update_t3 = 1./p_true - qop_update_t3;
              qop_diff_before_update_t3 = 1./p_true - qop;
              qop_resolution_after_update_t3 = (1./p_true - qop_update_t3) * p_true;
            }
            
            // Distance in x to correct hit in other x layer of station
            match_t3_other = false;
            for ( const auto true_id : true_scifi_ids ) {
              for ( int i_hit = 0; i_hit < n_hits_other; ++i_hit ) { 
                const int hit_index = x_zone_offset_other + i_hit;
                const uint32_t lhcbid = scifi_hits.LHCbID(hit_index);
                if ( true_id == lhcbid ) {
                  float true_x_t3_other = scifi_hits.x0[hit_index];
                  res_x_other_t3 = true_x_t3 - true_x_t3_other;
                  tx_x_hits_t3 = (true_x_t3_other - true_x_t3) / SciFi::MomentumForward::dz_x_layers; // dz of x-layers within one station = 210 mm
                  match_t3_other = true;
                  break;
                }
              }
              if ( match_t3_other ) break;
            }
          }
          
        } // # of true SciFi IDs > 0
        
        // check combinatorics within search window in layer 11
        float slope1, slope2;
        if ( qop < 0 ) {
          slope1 = -1.f * SciFi::MomentumForward::x_diff_layer_qop_slope_b;
          slope2 = -1.f * SciFi::MomentumForward::x_diff_layer_qop_slope_a;
        } else {
          slope1 = SciFi::MomentumForward::x_diff_layer_qop_slope_a;
          slope2 = SciFi::MomentumForward::x_diff_layer_qop_slope_b;
        }
        for ( int i_hit = 0; i_hit < n_hits; ++i_hit ) { 
          const int hit_index = x_zone_offset + i_hit;
          const float x = scifi_hits.x0[hit_index];
          if ( fabsf(x-xf_t3) < SciFi::MomentumForward::dx_extrap_qop_offset_T3 + SciFi::MomentumForward::dx_extrap_qop_slope_T3 * fabsf(qop) ) {
            n_hits_in_window_0_t3++;
            // check combinatorics in other x-layer of last station
            n_hits_in_window_other_t3 = 0;
            for ( int i_hit_other = 0; i_hit_other < n_hits_other; ++i_hit_other ) { 
              const int hit_index_other = x_zone_offset_other + i_hit_other;
              const float x_other = scifi_hits.x0[hit_index_other];
              if ( fabsf(x-x_other) < SciFi::MomentumForward::x_diff_layer_qop_offset + slope1 * qop 
                   && fabsf(x-x_other) > -1.f * SciFi::MomentumForward::x_diff_layer_qop_offset + slope2 * qop) {
                n_hits_in_window_other_t3++;
              }
            }
            t_other_x_layer_t3->Fill();
          }
        }
        n_hits_in_zone_t3 = n_hits;

        t_extrap_T3->Fill();
        
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

  info_cout << "Extrapolation to T1 worked: " << float(n_extrap_T1) / n_veloUT_tracks << std::endl;
  info_cout << "Extrapolation to T3 worked: " << float(n_extrap_T3) / n_veloUT_tracks << std::endl;

  output_pierre.close();

  return 0;
}


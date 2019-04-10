#include "LFFit.cuh"

__global__ void lf_fit_parallel(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const char* dev_velo_states,
  const int* dev_atomics_ut,
  const char* dev_ut_track_hits,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
  SciFi::TrackHits* dev_scifi_lf_tracks,
  const int* dev_scifi_lf_atomics,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const MiniState* dev_ut_states,
  const SciFi::Tracking::Arrays* constArrays,
  const float* dev_magnet_polarity,
  float* dev_scifi_lf_track_params)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // Velo consolidated types
  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) dev_atomics_velo, (uint*) dev_velo_track_hit_number, event_number, number_of_events};
  const Velo::Consolidated::States velo_states {(char*) dev_velo_states, velo_tracks.total_number_of_tracks};
  const uint velo_tracks_offset_event = velo_tracks.tracks_offset(event_number);

  // UT consolidated tracks
  const UT::Consolidated::Tracks ut_tracks {(uint*) dev_atomics_ut,
                                            (uint*) dev_ut_track_hit_number,
                                            (float*) dev_ut_qop,
                                            (uint*) dev_ut_track_velo_indices,
                                            event_number,
                                            number_of_events};
  const int ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);
  const int ut_event_number_of_tracks = ut_tracks.number_of_tracks(event_number); 

  Consolidated::TracksDescription ut_tracks_counter {(uint*) dev_atomics_ut, number_of_events};
  const int ut_event_tracks_offset_ = ut_tracks_counter.tracks_offset(event_number);
  const int ut_event_number_of_tracks_ = ut_tracks_counter.number_of_tracks(event_number);
  
  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();
  const auto number_of_tracks = dev_scifi_lf_atomics[event_number]; 

  //__shared__ int hits[128][SciFi::Constants::max_track_size];
  __shared__ uint8_t n_x_hits[LookingForward::num_threads_fit];
  __shared__ uint8_t n_uv_hits[LookingForward::num_threads_fit];
  __shared__ float xAtRefAverage[LookingForward::num_threads_fit];
  __shared__ LookingForward::fitSums fit_sums; // size = (8 * LookingForward::num_threads_fit) floats
  __shared__ float tot_chi2[LookingForward::num_threads_fit];
    
  for (int i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    
    // initialize shared memory
    __syncthreads();
    if ( threadIdx.x < LookingForward::num_threads_fit ) {
      xAtRefAverage[threadIdx.x] = 0.f;
      fit_sums.s0[threadIdx.x] = 0.f;
      fit_sums.sz[threadIdx.x] = 0.f;
      fit_sums.sz2[threadIdx.x] = 0.f;
      fit_sums.sz3[threadIdx.x] = 0.f;
      fit_sums.sz4[threadIdx.x] = 0.f;
      fit_sums.sd[threadIdx.x] = 0.f;
      fit_sums.sdz[threadIdx.x] = 0.f;
      fit_sums.sdz2[threadIdx.x] = 0.f;
      tot_chi2[threadIdx.x] = 0.f;
    }
    
    SciFi::TrackHits& track = dev_scifi_lf_tracks[ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i];
    const auto velo_states_index = velo_tracks_offset_event + ut_tracks.velo_track[track.ut_track_index];
    const MiniState velo_state {velo_states, velo_states_index};
    
    float* trackParams = dev_scifi_lf_track_params + ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter * SciFi::Tracking::nTrackParams + i * SciFi::Tracking::nTrackParams;

    // Note: It is a bit faster to use this than using directly track.hits
    //int hits[SciFi::Constants::max_track_size];
    // if ( threadIdx.x == 0 ) {
    //   for (int j=0; j<track.hitsNum; ++j) {
    //     //for (int j = threadIdx.x; j < track.hitsNum; j += blockDim.x) {
    //     hits[threadIdx.x][j] = event_offset + track.hits[j];
    //   }
    // }
    
    // __syncthreads();

    //uint8_t n_x_hits = 0;
    //for (int j = threadIdx.x + 3; j < track.hitsNum; j += blockDim.x) {
    if ( threadIdx.y == 0 ) {
      for (int j = 3; j < track.hitsNum; j++) {
        const int offset = event_offset + ((int) track.hits[j]);
        const int plane_code = scifi_hits.planeCode(offset) >> 1;
        if (!constArrays->is_x_plane[plane_code]) {
          n_x_hits[threadIdx.x] = j;
          break;
        }
      }
      n_uv_hits[threadIdx.x] = track.hitsNum - n_x_hits[threadIdx.x];
    }

    __syncthreads();

    //if ( threadIdx.x == 0 ) {
      
    const float xAtRef_initial = xFromVelo(SciFi::Tracking::zReference, velo_state);
    const float zMag_initial = zMagnet(velo_state, constArrays);
    //const float xAtRef_average =
    LookingForward::get_average_x_at_reference_plane_parallel(
      track.hits,
      event_offset,
      n_x_hits[threadIdx.x], 
      scifi_hits, 
      xAtRef_initial, 
      constArrays, 
      velo_state, 
      zMag_initial,
      xAtRefAverage + threadIdx.x);
    
    __syncthreads();
    
    if ( threadIdx.y == 0 ) {
      xAtRefAverage[threadIdx.x] /= n_x_hits[threadIdx.x];
      
      // initial track parameters
      getTrackParameters(xAtRefAverage[threadIdx.x], velo_state, constArrays, trackParams);
    }
    
    __syncthreads();
    
    // fit uv hits to update parameters related to y coordinate
    // update trackParams [4] [5] [6]
    // if (!LookingForward::fitYProjection_proto(velo_state, constArrays, track.hits + n_x_hits[threadIdx.x], event_offset, n_uv_hits[threadIdx.x], scifi_hits, trackParams)) {
    //   trackParams[7] = -1.f; // set chi2 negative
    // }
    
    LookingForward::fitParabola_parallel(scifi_hits, track.hits + n_x_hits[threadIdx.x], event_offset, n_uv_hits[threadIdx.x], fit_sums, trackParams, false);

    __syncthreads();
    
    if ( threadIdx.x < LookingForward::num_threads_fit ) {
      fit_sums.s0[threadIdx.x] = 0.f;
      fit_sums.sz[threadIdx.x] = 0.f;
      fit_sums.sz2[threadIdx.x] = 0.f;
      fit_sums.sz3[threadIdx.x] = 0.f;
      fit_sums.sz4[threadIdx.x] = 0.f;
      fit_sums.sd[threadIdx.x] = 0.f;
      fit_sums.sdz[threadIdx.x] = 0.f;
      fit_sums.sdz2[threadIdx.x] = 0.f;
    }
    
    __syncthreads();
    
    // if ( threadIdx.y == 0 ) {
      
    //   // make a fit of all hits using their x coordinate   
    //   // update trackParams [0] [1] [2] (x coordinate related)   
    //   if (!LookingForward::quadraticFitX_proto(scifi_hits, track.hits, event_offset, track.hitsNum, trackParams, true)) {      trackParams[7] = -1.f; // set chi2 negative
    //   }
    // }
    
    // make a fit of all hits in parallel, using their x coordinate  
     // update trackParams [0] [1] [2] (x coordinate related)   
    LookingForward::fitParabola_parallel(scifi_hits, track.hits, event_offset, track.hitsNum, fit_sums, trackParams, true);
  
    __syncthreads();

    // calculate chi2 in parallel
    for (uint8_t i_hit = threadIdx.y; i_hit < track.hitsNum; i_hit += blockDim.y) {
      const int hit = track.hits[i_hit] + event_offset;
      const float d = trackToHitDistance(trackParams, scifi_hits, hit);
      const float chi2 = d * d * scifi_hits.w(hit);
      atomicAdd(tot_chi2 + threadIdx.x, chi2);
    }
    __syncthreads();

    if ( threadIdx.y == 0 ) {
      if ( track.hitsNum < 4 ) { 
        trackParams[7] = -1.f;
      } else {
        trackParams[7] = tot_chi2[threadIdx.x];
        trackParams[8] = (float) (track.hitsNum) - 3.f; // 3 parameters to fit
      }
    }
    
  }
    
} 

__global__ void lf_fit(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const char* dev_velo_states,
  const int* dev_atomics_ut,
  const char* dev_ut_track_hits,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
  SciFi::TrackHits* dev_scifi_lf_tracks,
  const int* dev_scifi_lf_atomics,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const MiniState* dev_ut_states,
  const SciFi::Tracking::Arrays* constArrays,
  const float* dev_magnet_polarity,
  float* dev_scifi_lf_track_params)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // Velo consolidated types
  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) dev_atomics_velo, (uint*) dev_velo_track_hit_number, event_number, number_of_events};
  const Velo::Consolidated::States velo_states {(char*) dev_velo_states, velo_tracks.total_number_of_tracks};
  const uint velo_tracks_offset_event = velo_tracks.tracks_offset(event_number);

  // UT consolidated tracks
  const UT::Consolidated::Tracks ut_tracks {(uint*) dev_atomics_ut,
                                            (uint*) dev_ut_track_hit_number,
                                            (float*) dev_ut_qop,
                                            (uint*) dev_ut_track_velo_indices,
                                            event_number,
                                            number_of_events};
  const int ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);
  const int ut_event_number_of_tracks = ut_tracks.number_of_tracks(event_number); 

  Consolidated::TracksDescription ut_tracks_counter {(uint*) dev_atomics_ut, number_of_events};
  const int ut_event_tracks_offset_ = ut_tracks_counter.tracks_offset(event_number);
  const int ut_event_number_of_tracks_ = ut_tracks_counter.number_of_tracks(event_number);
  
  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();
  const auto number_of_tracks = dev_scifi_lf_atomics[event_number]; 
  
  for (int i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    SciFi::TrackHits& track = dev_scifi_lf_tracks[ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + i];
    const auto velo_states_index = velo_tracks_offset_event + ut_tracks.velo_track[track.ut_track_index];
    const MiniState velo_state {velo_states, velo_states_index};
    
    float* trackParams = dev_scifi_lf_track_params + ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter * SciFi::Tracking::nTrackParams + i * SciFi::Tracking::nTrackParams;

    // Note: It is a bit faster to use this than using directly track.hits
    int hits[SciFi::Constants::max_track_size];
    for (int j=0; j<track.hitsNum; ++j) {
      hits[j] = event_offset + track.hits[j];
    }
    
    uint8_t n_x_hits = 0;
    for (int j = 3; j < track.hitsNum; j++) {
      const int offset = event_offset + ((int) track.hits[j]);
      const int plane_code = scifi_hits.planeCode(offset) >> 1;
      if (!constArrays->is_x_plane[plane_code]) {
        n_x_hits = j;
        break;
      }
    }
    const uint8_t n_uv_hits = track.hitsNum - n_x_hits;
    
      
    const float xAtRef_initial = xFromVelo(SciFi::Tracking::zReference, velo_state);
    const float zMag_initial = zMagnet(velo_state, constArrays);
    const float xAtRef_average =
      LookingForward::get_average_x_at_reference_plane(
        hits,
        n_x_hits, 
        scifi_hits, 
        xAtRef_initial, 
        constArrays, 
        velo_state, 
        zMag_initial);
    
    // initial track parameters
    getTrackParameters(xAtRef_average, velo_state, constArrays, trackParams);
        
    
    // fit uv hits to update parameters related to y coordinate
    // update trackParams [4] [5] [6]
    if (!LookingForward::fitParabola_proto(scifi_hits, hits + n_x_hits, n_uv_hits, trackParams, false)) {
      trackParams[7] = -1.f; // set chi2 negative
    }
    
    
    // make a fit of all hits using their x coordinate   
    // update trackParams [0] [1] [2] (x coordinate related)   
    if (!LookingForward::fitParabola_proto(scifi_hits, hits, track.hitsNum, trackParams, true)) {    
      trackParams[7] = -1.f; // set chi2 negative
    }
    
    // calculate chi2
    if ( !LookingForward::getChi2(scifi_hits, hits, track.hitsNum, trackParams) ) {
      trackParams[7] = -1.f; // set chi2 negative
    }
    
  }
    
} 

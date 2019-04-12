#include "LFQualityFilterX.cuh"

__global__ void lf_quality_filter_x(
  const int* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const int* dev_scifi_lf_atomics,
  SciFi::TrackHits* dev_scifi_lf_x_filtered_tracks,
  int* dev_scifi_lf_x_filtered_atomics)
{
  __shared__ int16_t candidate_ranking[LookingForward::maximum_number_of_candidates_per_ut_track];
  __shared__ float qualities[LookingForward::maximum_number_of_candidates_per_ut_track];
  __shared__ int16_t candidate_indices[LookingForward::maximum_number_of_candidates_per_ut_track];
  __shared__ int n_candidates;

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x; 

  // UT consolidated tracks
  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset; 
  
  for (uint16_t i = blockIdx.y; i < ut_event_number_of_tracks; i += gridDim.y) {
    const auto current_ut_track_index = ut_event_tracks_offset + i; 
    const auto number_of_tracks = dev_scifi_lf_atomics[current_ut_track_index];
 
    // Initialize shared memory buffers
    __syncthreads();
  
    if (threadIdx.x == 0) {
      n_candidates = 0;
    }
    
    __syncthreads();  
     
    // first save indices and qualities of tracks with more than three hits
    for (int i = threadIdx.x; i < number_of_tracks; i += blockDim.x) { 
      const SciFi::TrackHits& track = dev_scifi_lf_tracks[current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track + i];  
      if ( track.hitsNum > 3 ) {
        const auto insert_index = atomicAdd(&n_candidates, 1);  
        assert(insert_index < LookingForward::maximum_number_of_candidates_per_ut_track);
        candidate_indices[insert_index] = i;
        const float quality = track.quality;
        qualities[insert_index] = quality;
      }  
    }
    
    __syncthreads();
    
    // then sort tracks these tracks with more than three hits by quality
    for (int i = threadIdx.x; i < n_candidates; i += blockDim.x) {
      const float quality = qualities[i];
      int16_t insert_position = 0;
      for ( uint16_t j = 0; j < n_candidates; ++j ) {
        const float other_quality = qualities[j];
        if ( quality > other_quality || (quality == other_quality && i < j) ) {
          ++insert_position;
        }
      }
      assert(insert_position < LookingForward::maximum_number_of_candidates_per_ut_track);
      candidate_ranking[insert_position] = candidate_indices[i];
    }
     
    __syncthreads();
    
    // Save best candidates of tracks with more than three hits
    for (int i = threadIdx.x; i < n_candidates && i < LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter; i += blockDim.x) { 
      const int16_t candidate = candidate_ranking[i]; 
      if (i < LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter) {
        const auto insert_index = atomicAdd(dev_scifi_lf_x_filtered_atomics + event_number, 1);  
        const SciFi::TrackHits& track = dev_scifi_lf_tracks[current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track + candidate];  
        dev_scifi_lf_x_filtered_tracks[ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter + insert_index] = track;
      }
    } 
  }
    
}

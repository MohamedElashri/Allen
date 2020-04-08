#include "FilterMFTracks.cuh"

__global__ void FilterMFTracks::filter_mf_tracks(FilterMFTracks::Parameters parameters, const uint number_of_events)
{
  const uint muon_filtered_event = blockIdx.x;
  const uint i_event = parameters.dev_event_list_mf[muon_filtered_event];
  const uint idx_offset = muon_filtered_event * 10 * VertexFit::max_svs;
  uint* event_sv_number = parameters.dev_mf_sv_atomics + i_event;
  uint* event_svs_kf_idx = parameters.dev_svs_kf_idx + idx_offset;
  uint* event_svs_mf_idx = parameters.dev_svs_mf_idx + idx_offset;

  // Consolidated SciFi tracks.
  SciFi::Consolidated::ConstTracks scifi_tracks {parameters.dev_atomics_scifi,
                                                 parameters.dev_scifi_track_hit_number,
                                                 parameters.dev_scifi_qop,
                                                 parameters.dev_scifi_states,
                                                 parameters.dev_scifi_track_ut_indices,
                                                 i_event,
                                                 number_of_events};

  const uint event_tracks_offset = scifi_tracks.tracks_offset(i_event);
  const uint n_scifi_tracks = scifi_tracks.number_of_tracks(i_event);
  const uint event_mf_tracks_offset = parameters.dev_mf_track_offsets[i_event];
  const uint n_mf_tracks = parameters.dev_mf_track_offsets[i_event + 1] - event_mf_tracks_offset;

  const ParKalmanFilter::FittedTrack* event_kf_tracks = parameters.dev_kf_tracks + event_tracks_offset;
  const ParKalmanFilter::FittedTrack* event_mf_tracks = parameters.dev_mf_tracks + event_mf_tracks_offset;

  // Loop over KF tracks.
  for (auto i_track = threadIdx.x; i_track < n_scifi_tracks; i_track += blockDim.x) {

    const ParKalmanFilter::FittedTrack trackA = event_kf_tracks[i_track];
    if (
      trackA.pt() < parameters.kf_track_min_pt || (trackA.ipChi2 < parameters.kf_track_min_ipchi2 && !trackA.is_muon)) {
      continue;
    }

    // Loop over MF tracks.
    for (auto j_track = threadIdx.y; j_track < n_mf_tracks; j_track += blockDim.x) {

      const ParKalmanFilter::FittedTrack trackB = event_mf_tracks[j_track];
      if (trackB.pt() < parameters.mf_track_min_pt || (!trackB.is_muon)) {
        continue;
      }

      // Don't worry about the same-PV cut for now.
      uint vertex_idx = atomicAdd(event_sv_number, 1);
      event_svs_kf_idx[vertex_idx] = i_track;
      event_svs_mf_idx[vertex_idx] = j_track;
    }
  }
}
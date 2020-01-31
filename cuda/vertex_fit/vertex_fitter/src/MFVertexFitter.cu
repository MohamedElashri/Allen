#include "VertexFitter.cuh"
#include "MFVertexFitter.cuh"
#include "ParKalmanMath.cuh"
#include "ParKalmanDefinitions.cuh"

__global__ void MFVertexFit::fit_mf_vertices(MFVertexFit::Parameters parameters)
{
  const uint muon_filtered_event = blockIdx.x;
  const uint event_number = parameters.dev_event_list_mf[muon_filtered_event];
  const uint sv_offset = parameters.dev_mf_sv_offsets[event_number];
  const uint n_svs = parameters.dev_mf_sv_offsets[event_number + 1] - sv_offset;
  const uint idx_offset = 10 * VertexFit::max_svs * muon_filtered_event;
  const uint* event_svs_kf_idx = parameters.dev_svs_kf_idx + idx_offset;
  const uint* event_svs_mf_idx = parameters.dev_svs_mf_idx + idx_offset;

  // KF tracks.
  const uint kf_offset = parameters.dev_offsets_forward_tracks[event_number];
  const ParKalmanFilter::FittedTrack* kf_tracks = parameters.dev_kf_tracks + kf_offset;

  // MF tracks.
  const uint mf_offset = parameters.dev_mf_track_offsets[event_number];
  const ParKalmanFilter::FittedTrack* mf_tracks = parameters.dev_mf_tracks + mf_offset;

  // Vertices.
  VertexFit::TrackMVAVertex* event_mf_svs = parameters.dev_mf_svs + sv_offset;
  
  // Loop over svs.
  for (uint i_sv = threadIdx.x; i_sv < n_svs; i_sv += blockDim.x) {
    event_mf_svs[i_sv].chi2 = -1;
    event_mf_svs[i_sv].minipchi2 = 0;
    auto i_track = event_svs_kf_idx[i_sv];
    auto j_track = event_svs_mf_idx[i_sv];
    const ParKalmanFilter::FittedTrack trackA = kf_tracks[i_track];
    const ParKalmanFilter::FittedTrack trackB = mf_tracks[i_track];

    // Do the fit.
    doFit(trackA, trackB, event_mf_svs[i_sv]);
    event_mf_svs[i_sv].trk1 = i_track;
    event_mf_svs[i_sv].trk2 = j_track;

    // Fill extra info. Don't worry about PVs.
    fill_extra_info(event_mf_svs[i_sv], trackA, trackB);
  }
  
}

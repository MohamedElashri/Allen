#include "LFTrackQuality.cuh"

__device__ float lf_track_quality (SciFi::TrackHits& track,
  const MiniState& velo_state,
  const float VeloUT_qOverP,
  const SciFi::Tracking::Arrays* constArrays,
  const SciFi::Tracking::TMVA* tmva1,
  const SciFi::Tracking::TMVA* tmva2,
  const SciFi::Hits& scifi_hits,
  const int event_offset)
{
  float quality = LookingForward::track_min_quality;

  if (track.hitsNum < LookingForward::track_min_hits) {
    return quality;
  }

  // use only hits from x-planes to calculate the average x position on the reference plane
  int hits[SciFi::Constants::max_track_size];
  int uv_hits[SciFi::Constants::max_track_size]; // to do: make smaller
  int n_hits = 0;
  int n_uv_hits = 0;

  assert(track.hitsNum <= SciFi::Constants::max_track_size);

  // printf("Track: ut_track_index %i, hitsNum %i, hits: ", track.ut_track_index, track.hitsNum);
  // for (int i=0; i<track.hitsNum; ++i) {
  //   printf("%i, ", track.hits[i]);
  // }
  // printf("\n");

  const bool is_x_plane [12] {1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1};
  for (int i = 0; i < track.hitsNum; ++i) {
    const int offset = event_offset + ((int) track.hits[i]);
    const int plane_code = scifi_hits.planeCode(offset) >> 1;

    if (is_x_plane[plane_code]) {
      assert(n_hits <= 6);
      // first store only x hits in hits array
      hits[n_hits++] = offset;
    }
    else {
      assert(n_uv_hits <= 6);
      uv_hits[n_uv_hits++] = offset;
    }
  }
  const float xAtRef_initial = xFromVelo(SciFi::Tracking::zReference, velo_state);
  const float xParams_seed[4] = {xAtRef_initial, velo_state.tx, 0.f, 0.f};
  float zMag_initial = zMagnet(velo_state, constArrays);
  float xAtRef_average =
    LookingForward::get_average_x_at_reference_plane(hits, n_hits, scifi_hits, xParams_seed, constArrays, velo_state, zMag_initial);

  // initial track parameters
  float trackParams[SciFi::Tracking::nTrackParams];
  getTrackParameters(xAtRef_average, velo_state, constArrays, trackParams);

  // fit uv hits to update parameters related to y coordinate
  // update trackParams [4] [5] [6]
  if (!LookingForward::fitYProjection_proto(velo_state, constArrays, uv_hits, n_uv_hits, scifi_hits, trackParams)) {
    return quality;
  }

  // ad uv hits to hits array
  for (int i_hit = 0; i_hit < n_uv_hits; ++i_hit) {
    hits[n_hits++] = uv_hits[i_hit];
  }

  // make a fit of all hits using their x coordinate
  // update trackParams [0] [1] [2] (x coordinate related)
  // if (!fitParabola_proto(
  //   scifi_hits,
  //   hits,
  //   n_hits,
  //   trackParams,
  //   true)) continue;

  // // chi2 & nDoF: trackParams [7] [8]
  // if ( !getChi2(
  //   scifi_hits,
  //   hits,
  //   n_hits,
  //   trackParams,
  //   true)) continue;

  // make a fit of all hits using their x coordinate
  // update trackParams [0] [1] [2] (x coordinate related)
  // remove outliers with worst chi2
  if (!LookingForward::quadraticFitX_proto(scifi_hits, hits, n_hits, trackParams, true)) {
    return quality;
  }

  // Calculate q/p
  const float qOverP = calcqOverP(trackParams[1], constArrays, velo_state);
  const float xAtRef = trackParams[0];
  float dSlope = (velo_state.x + (SciFi::Tracking::zReference - velo_state.z) * velo_state.tx - xAtRef) /
                 (SciFi::Tracking::zReference - constArrays->zMagnetParams[0]);
  const float zMagSlope =
    constArrays->zMagnetParams[2] * velo_state.tx * velo_state.tx + constArrays->zMagnetParams[3] * velo_state.ty * velo_state.ty;
  const float zMag = constArrays->zMagnetParams[0] + constArrays->zMagnetParams[1] * dSlope * dSlope + zMagSlope;
  const float xMag = velo_state.x + (zMag - velo_state.z) * velo_state.tx;
  const float slopeT = (xAtRef - xMag) / (SciFi::Tracking::zReference - zMag);
  dSlope = slopeT - velo_state.tx;
  const float dyCoef = dSlope * dSlope * velo_state.ty;

  float bx = slopeT;
  float ay = velo_state.y + (SciFi::Tracking::zReference - velo_state.z) * velo_state.ty;
  float by = velo_state.ty + dyCoef * SciFi::Tracking::byParams;

  const float ay1 = trackParams[4]; // y at zRef, from velo state
  const float by1 = trackParams[5]; //
  const float bx1 = trackParams[1]; // slope between zRef and zMag (-> in the SciFi)

  // Pipe into TMVA, get track quality
  float mlpInput[7] = {0, 0, 0, 0, 0, 0, 0};
  mlpInput[0] = track.hitsNum; // should be nbDifferent, but we only allow hits from different planes anyway
  mlpInput[1] = qOverP;
  mlpInput[2] = VeloUT_qOverP - qOverP;                // veloUT - scifi
  if (fabsf(VeloUT_qOverP) < 1e-9f) mlpInput[2] = 0.f; // no momentum estiamte
  mlpInput[3] = velo_state.tx * velo_state.tx + velo_state.ty * velo_state.ty;
  mlpInput[4] = by - by1;
  mlpInput[5] = bx - bx1;
  mlpInput[6] = ay - ay1;

  // debug_cout << "qOverP = " << qOverP << ", qop diff = " << mlpInput[2] << ", tx^2+ty^2 = " <<  mlpInput[3] << ",
  // by-by1 = " << mlpInput[4] << ", bx-bx1 = " << mlpInput[5] << ", ay-ay1 = " << mlpInput[6] << std::endl;

  quality = GetMvaValue(mlpInput, tmva1);
  track.qop = qOverP;

  // if (quality < SciFi::Tracking::maxQuality) {
  //   SciFi::TrackHits final_track = track;
  //   track.quality = float(trackParams[7]) / float(trackParams[8]); // chi2/nDoF
  //   track.qop = qOverP;
  //   selected_tracks.push_back(final_track);
  // }

  return quality;
}
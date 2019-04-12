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
  float quality = 0.f;

  // LookingForward::track_min_starting_quality
  // || track.get_quality() > 20.f
  if (track.hitsNum < LookingForward::track_min_hits) {
    return quality;
  }

  // Note: It is a bit faster to use this than using directly track.hits
  int hits[SciFi::Constants::max_track_size];
  for (int i=0; i<track.hitsNum; ++i) {
    hits[i] = event_offset + track.hits[i];
  }

  uint8_t n_x_hits = 0;
  for (int i=3; i<track.hitsNum; ++i) {
    const int offset = event_offset + ((int) track.hits[i]);
    const int plane_code = scifi_hits.planeCode(offset) >> 1;
    if (!constArrays->is_x_plane[plane_code]) {
      n_x_hits = i;
      break;
    }
  }
  const uint8_t n_uv_hits = track.hitsNum - n_x_hits;

  const float xAtRef_initial = xFromVelo(SciFi::Tracking::zReference, velo_state);
  const float zMag_initial = zMagnet(velo_state, constArrays);
  const float xAtRef_average =
    LookingForward::get_average_x_at_reference_plane(hits, n_x_hits, scifi_hits, xAtRef_initial, velo_state.tx, constArrays, velo_state, zMag_initial);

  // initial track parameters
  float trackParams[SciFi::Tracking::nTrackParams];
  getTrackParameters(xAtRef_average, velo_state, constArrays, trackParams);

  // fit uv hits to update parameters related to y coordinate
  // update trackParams [4] [5] [6]
  if (!LookingForward::fitYProjection_proto(velo_state, constArrays, hits + n_x_hits, n_uv_hits, scifi_hits, trackParams)) {
    return quality;
  }

  // make a fit of all hits using their x coordinate
  // update trackParams [0] [1] [2] (x coordinate related)
  // remove outliers with worst chi2
  if (!LookingForward::quadraticFitX_proto(scifi_hits, hits, track.hitsNum, trackParams, true)) {
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

  const float bx = slopeT;
  const float ay = velo_state.y + (SciFi::Tracking::zReference - velo_state.z) * velo_state.ty;
  const float by = velo_state.ty + dyCoef * SciFi::Tracking::byParams;

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

  quality = GetMvaValue(mlpInput, tmva1);
  track.qop = qOverP;

  return quality;
}

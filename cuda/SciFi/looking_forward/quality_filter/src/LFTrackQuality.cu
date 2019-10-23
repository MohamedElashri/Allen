#include "LFTrackQuality.cuh"

__device__ float lf_track_quality(
  const SciFi::TrackHits& track,
  const MiniState& velo_state,
  const float VeloUT_qOverP,
  const float* trackParams,
  const SciFi::Tracking::Arrays* constArrays,
  const float magnet_polarity,
  const SciFi::Tracking::TMVA* tmva1)
{
  float quality = 0.f;
  if (trackParams[7] > 0) { // fit converged
    const float qOverP = calcqOverP(trackParams[1], constArrays, velo_state, magnet_polarity);
    // const float qOverP = track.qop;
    const float xAtRef = trackParams[0];
    float dSlope = (velo_state.x + (SciFi::Tracking::zReference - velo_state.z) * velo_state.tx - xAtRef) /
                   (SciFi::Tracking::zReference - constArrays->zMagnetParams[0]);
    const float zMagSlope = constArrays->zMagnetParams[2] * velo_state.tx * velo_state.tx +
                            constArrays->zMagnetParams[3] * velo_state.ty * velo_state.ty;
    const float zMag = constArrays->zMagnetParams[0] + constArrays->zMagnetParams[1] * dSlope * dSlope + zMagSlope;
    const float xMag = velo_state.x + (zMag - velo_state.z) * velo_state.tx;
    const float slopeT = (xAtRef - xMag) / (SciFi::Tracking::zReference - zMag);
    dSlope = slopeT - velo_state.tx;
    const float dyCoef = dSlope * dSlope * velo_state.ty;

    const float bx = slopeT;
    const float ay = velo_state.y + (SciFi::Tracking::zReference - velo_state.z) * velo_state.ty;
    const float by = velo_state.ty + dyCoef * SciFi::Tracking::byParams;

    const float ay1 = trackParams[4]; // y at zRef, from velo state
    const float by1 = trackParams[5]; // y slope between zRef and zMag
    const float bx1 = trackParams[1]; // x slope between zRef and zMag (-> in the SciFi)

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
    // track.qop = qOverP;
  }

  return quality;
}

#include "LFSearchInitialWindowsImpl.cuh"

__host__ __device__ inline float evalCubicParameterization(const float value_at_ref, const float t, const float z)
{
  float dz = z - SciFi::Tracking::zReference;
  return value_at_ref + t * dz;
}

__host__ __device__ void lf_search_initial_windows_impl(
  const SciFi::Hits& scifi_hits,
  const SciFi::HitCount& scifi_hit_count,
  const float xAtRef,
  const float yAtRef,
  const MiniState& velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  const float qOverP,
  const int side,
  int* initial_windows,
  const int number_of_tracks)
{
  // Find size of search window on reference plane, using Velo slopes and min pT as input
  float dxRef = 0.9f * calcDxRef(SciFi::Tracking::minPt, velo_state);
  // find position within magnet where bending happens
  float zMag = zMagnet(velo_state, constArrays);

  const float q = qOverP > 0.f ? 1.f : -1.f;
  const float dir = q * SciFi::Tracking::magscalefactor * (-1.f);

  float slope2 = velo_state.tx * velo_state.tx + velo_state.ty * velo_state.ty;
  const float pt = sqrtf(fabsf(1.f / (qOverP * qOverP))) * (slope2) / (1.f + slope2);
  const bool wSignTreatment = SciFi::Tracking::useWrongSignWindow && pt > SciFi::Tracking::wrongSignPT;

  float dxRefWS = 0.f;
  if (wSignTreatment) {
    // DvB: what happens if we use the actual momentum from VeloUT here instead of a constant?
    dxRefWS = 0.9f * calcDxRef(
                       SciFi::Tracking::wrongSignPT,
                       velo_state); // make windows a bit too small - FIXME check effect of this, seems wrong
  }

  int iZoneStartingPoint = side > 0 ? constArrays->zoneoffsetpar : 0;

  for (int iZone = iZoneStartingPoint; iZone < iZoneStartingPoint + constArrays->zoneoffsetpar; iZone++) {
    // Initialize windows
    const auto relative_iZone = iZone - iZoneStartingPoint;

    assert(iZone - iZoneStartingPoint < SciFi::Constants::n_zones);
    assert(iZone - iZoneStartingPoint < 12);
    const float zZone = constArrays->xZone_zPos[iZone - iZoneStartingPoint];
    const float xInZone = evalCubicParameterization(xAtRef, velo_state.tx, zZone);
    const float yInZone = evalCubicParameterization(yAtRef, velo_state.ty, zZone);

    // Now the code checks if the x and y are in the zone limits. I am really not sure
    // why this is done here, surely could just check if within limits for the last zone
    // in T3 and go from there? Need to think more about this.
    //
    // Here for now I assume the same min/max x and y for all stations, this again needs to
    // be read from some file blablabla although actually I suspect having some general tolerances
    // here is anyway good enough since we are doing a straight line extrapolation in the first place
    // check (roughly) whether the extrapolated velo track is within the current zone
    if (side > 0) {
      if (
        !isInside(xInZone, SciFi::Tracking::xLim_Min, SciFi::Tracking::xLim_Max) ||
        !isInside(yInZone, SciFi::Tracking::yLim_Min, SciFi::Tracking::yLim_Max))
        continue;
    }
    else {
      if (
        !isInside(xInZone, SciFi::Tracking::xLim_Min, SciFi::Tracking::xLim_Max) ||
        !isInside(yInZone, side * SciFi::Tracking::yLim_Max, side * SciFi::Tracking::yLim_Min))
        continue;
    }

    // extrapolate dxRef (x window on reference plane) to plane of current zone
    const float xTol = (zZone < SciFi::Tracking::zReference) ?
                         dxRef * zZone / SciFi::Tracking::zReference :
                         dxRef * (zZone - zMag) / (SciFi::Tracking::zReference - zMag);
    float xMin = xInZone - xTol;
    float xMax = xInZone + xTol;

    if (SciFi::Tracking::useMomentumEstimate) { // For VeloUT tracks, suppress check if track actually has qOverP set,
                                                // get the option right!
      float xTolWS = 0.0;
      if (wSignTreatment) {
        xTolWS = (zZone < SciFi::Tracking::zReference) ?
                   dxRefWS * zZone / SciFi::Tracking::zReference :
                   dxRefWS * (zZone - zMag) / (SciFi::Tracking::zReference - zMag);
      }
      if (dir > 0) {
        xMin = xInZone - xTolWS;
      }
      else {
        xMax = xInZone + xTolWS;
      }
    }

    // Get the hits within the bounds
    assert(iZone < SciFi::Constants::n_layers);
    assert(constArrays->xZones[iZone] < SciFi::Constants::n_zones);
    const int x_zone_offset_begin = scifi_hit_count.zone_offset(constArrays->xZones[iZone]);
    const int x_zone_offset_end = x_zone_offset_begin + scifi_hit_count.zone_number_of_hits(constArrays->xZones[iZone]);
    const int itH = getLowerBound(scifi_hits.x0, xMin, x_zone_offset_begin, x_zone_offset_end);
    const int itEnd = getLowerBound(scifi_hits.x0, xMax, x_zone_offset_begin, x_zone_offset_end);

    // Initialize windows
    initial_windows[relative_iZone * 8 * number_of_tracks] = itH;
    initial_windows[(relative_iZone * 8 + 1) * number_of_tracks] = itEnd - itH;

    assert(itH >= x_zone_offset_begin && itH <= x_zone_offset_end);
    assert(itEnd >= x_zone_offset_begin && itEnd <= x_zone_offset_end);

    // Skip making range but continue if the end is before or equal to the start
    if (!(itEnd > itH)) continue;

    // Now match the stereo hits
    const float this_uv_z = constArrays->uvZone_zPos[iZone - iZoneStartingPoint];
    const float xInUv = evalCubicParameterization(xAtRef, velo_state.tx, this_uv_z);
    const float zRatio = (this_uv_z - zMag) / (zZone - zMag);
    const float dx = yInZone * constArrays->uvZone_dxdy[iZone - iZoneStartingPoint];
    const float xCentral = xInZone + dx;
    const float xPredUv = xInUv + (scifi_hits.x0[itH] - xInZone) * zRatio - dx;
    const float maxDx = SciFi::Tracking::tolYCollectX +
                        (fabsf(scifi_hits.x0[itH] - xCentral) + fabsf(yInZone)) * SciFi::Tracking::tolYSlopeCollectX;
    const float xMinUV = xPredUv - maxDx;

    // Get bounds in UV layers
    // do one search on the same side as the x module
    // if we are close to y = 0, also look within a region on the other side module ("triangle search")
    assert(constArrays->uvZones[iZone] < SciFi::Constants::n_zones);
    const int uv_zone_offset_begin = scifi_hit_count.zone_offset(constArrays->uvZones[iZone]);
    const int uv_zone_offset_end =
      uv_zone_offset_begin + scifi_hit_count.zone_number_of_hits(constArrays->uvZones[iZone]);

    const int itUV1 = getLowerBound(scifi_hits.x0, xMinUV, uv_zone_offset_begin, uv_zone_offset_end);

    const float xPredUVProto = xInUv - xInZone * zRatio - dx;
    const float maxDxProto = SciFi::Tracking::tolYCollectX + fabsf(yInZone) * SciFi::Tracking::tolYSlopeCollectX;

    initial_windows[(relative_iZone * 8 + 2) * number_of_tracks] = itUV1;
    initial_windows[(relative_iZone * 8 + 3) * number_of_tracks] = uv_zone_offset_end;

    float* initial_windows_f = (float*) &initial_windows[0];
    initial_windows_f[(relative_iZone * 8 + 4) * number_of_tracks] = xPredUVProto;
    initial_windows_f[(relative_iZone * 8 + 5) * number_of_tracks] = zRatio;
    initial_windows_f[(relative_iZone * 8 + 6) * number_of_tracks] = maxDxProto;
    initial_windows_f[(relative_iZone * 8 + 7) * number_of_tracks] = xCentral;
  }
}

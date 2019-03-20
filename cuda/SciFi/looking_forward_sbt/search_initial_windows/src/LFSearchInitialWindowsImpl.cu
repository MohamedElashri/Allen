#include "LFSearchInitialWindowsImpl.cuh"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "BinarySearch.cuh"

__device__ inline float linear_parameterization(const float value_at_ref, const float t, const float z)
{
  float dz = z - SciFi::Tracking::zReference;
  return value_at_ref + t * dz;
}
 
__device__ void lf_search_initial_windows_p_impl(
  const SciFi::Hits& scifi_hits,
  const SciFi::HitCount& scifi_hit_count,
  const MiniState& velo_state,
  const MiniState& UT_state,
  const SciFi::Tracking::Arrays* constArrays,
  const LookingForward::Constants* looking_forward_constants,
  const float qop,
  const int side,
  int* initial_windows,
  const int number_of_tracks)
{ 
  // use parametrization to propagate from UT to SciFi
  // zRef is between layers 4 and 5 
  const auto x_at_ref = LookingForward::propagate_x_from_velo(UT_state, qop, 5, looking_forward_constants);
  
  const float xTol = 0.8f * LookingForward::dx_calc(velo_state.tx, qop);    
  //float zMag = zMagnet(velo_state, constArrays); 
   
  int iZoneStartingPoint = side > 0 ? constArrays->zoneoffsetpar : 0; 
  
  for (int i=threadIdx.y; i<LookingForward::number_of_x_layers; i+=blockDim.y) { 
    const auto iZone = iZoneStartingPoint + i;
    const auto izone_rel = iZone - iZoneStartingPoint;
    const float zZone = constArrays->xZone_zPos[izone_rel];
    
    const float dz_x = (zZone - SciFi::Tracking::zReference); 
    const float xInZone = LookingForward::scifi_propagation(x_at_ref, UT_state.tx, qop, dz_x);   
    const float yInZone = yFromVelo(zZone, velo_state); 
    
    // if (side > 0) {
    //   if (
    //       !isInside(xInZone, SciFi::Tracking::xLim_Min, SciFi::Tracking::xLim_Max) ||
    //       !isInside(yInZone, SciFi::Tracking::yLim_Min, SciFi::Tracking::yLim_Max))
    //     continue;
    // }
    // else {
    //   if (
    //       !isInside(xInZone, SciFi::Tracking::xLim_Min, SciFi::Tracking::xLim_Max) ||
    //       !isInside(yInZone, side * SciFi::Tracking::yLim_Max, side * SciFi::Tracking::yLim_Min))
    //     continue;
    // } 
    
    float xMin = xInZone - xTol;
    float xMax = xInZone + xTol;
        
    // Get the hits within the bounds
    const int x_zone_offset_begin = scifi_hit_count.zone_offset(constArrays->xZones[iZone]);
    const int x_zone_size = scifi_hit_count.zone_number_of_hits(constArrays->xZones[iZone]);
    int hits_within_bounds_start = binary_search_leftmost(scifi_hits.x0 + x_zone_offset_begin, x_zone_size, xMin);
    const int hits_within_bounds_size = binary_search_leftmost(scifi_hits.x0 + x_zone_offset_begin + hits_within_bounds_start, x_zone_size - hits_within_bounds_start, xMax);
    hits_within_bounds_start += x_zone_offset_begin;

    // Initialize windows
    initial_windows[i * 8 * number_of_tracks] = hits_within_bounds_start;
    initial_windows[(i * 8 + 1) * number_of_tracks] = hits_within_bounds_size;
    
    // Now match the stereo hits
    const float this_uv_z = constArrays->uvZone_zPos[izone_rel];
    const float dz_uv = this_uv_z - SciFi::Tracking::zReference;
    const float yInUVZone = yFromVelo(this_uv_z, velo_state); 
    const float dx = yInUVZone * constArrays->uvZone_dxdy[izone_rel]; 
    const float xPredUV = LookingForward::scifi_propagation(x_at_ref, UT_state.tx, qop, dz_uv) - dx;  
    const int uv_layer = constArrays->uvZones[iZone] / 2; 
    // To Do: study this window
    const float xBound = 70.f * looking_forward_constants->extrapolation_stddev[uv_layer];
    const float maxDx = xBound; 

    const float xMinUV = xPredUV - maxDx;
    const float xMaxUV = xPredUV + maxDx; 

    // const float zRatio = (this_uv_z - zMag) / (zZone - zMag);
    // const float xPredUVProto = xPredUV - xInZone * zRatio;
    // const float maxDxProto = SciFi::Tracking::tolYCollectX + std::abs(yInZone) * SciFi::Tracking::tolYSlopeCollectX;
    // const float xCentral = xInZone + dx;

    // Get bounds in UV layers
    // do one search on the same side as the x module
    // if we are close to y = 0, also look within a region on the other side module ("triangle search")
    const int uv_zone_offset_begin = scifi_hit_count.zone_offset(constArrays->uvZones[iZone]);
    const int uv_zone_size = scifi_hit_count.zone_number_of_hits(constArrays->uvZones[iZone]);
    int hits_within_uv_bounds_start = binary_search_leftmost(scifi_hits.x0 + uv_zone_offset_begin, uv_zone_size, xMinUV);
    const int hits_within_uv_bounds_size = binary_search_leftmost(scifi_hits.x0 + uv_zone_offset_begin + hits_within_uv_bounds_start, uv_zone_size - hits_within_uv_bounds_start, xMaxUV);
    hits_within_uv_bounds_start += uv_zone_offset_begin;
    
    initial_windows[(i * 8 + 2) * number_of_tracks] = hits_within_uv_bounds_start;
    initial_windows[(i * 8 + 3) * number_of_tracks] = hits_within_uv_bounds_size;

    // float* initial_windows_f = (float*) &initial_windows[0];
    // initial_windows_f[(i * 8 + 4) * number_of_tracks] = xPredUVProto;
    // initial_windows_f[(i * 8 + 5) * number_of_tracks] = zRatio;
    // initial_windows_f[(i * 8 + 6) * number_of_tracks] = maxDxProto;
    // initial_windows_f[(i * 8 + 7) * number_of_tracks] = xCentral;
  }
 
}

__device__ void lf_search_initial_windows_impl(
  const SciFi::Hits& scifi_hits,
  const SciFi::HitCount& scifi_hit_count,
  const float xAtRef,
  const float yAtRef,
  const MiniState& velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  const float qop,
  const int side,
  int* initial_windows,
  const int number_of_tracks)
{ 
  // Find size of search window on reference plane, using Velo slopes and min pT as input
  float dxRef = 0.9f * calcDxRef(SciFi::Tracking::minPt, velo_state);
  // find position within magnet where bending happens
  float zMag = zMagnet(velo_state, constArrays); 

  const float q = qop > 0.f ? 1.f : -1.f;
  const float dir = q * SciFi::Tracking::magscalefactor * (-1.f);

  const float slope2 = velo_state.tx * velo_state.tx + velo_state.ty * velo_state.ty;
  const float pt = std::sqrt(slope2 / (1.f + slope2)) / std::abs(qop);
  const bool wSignTreatment = SciFi::Tracking::useWrongSignWindow && pt > SciFi::Tracking::wrongSignPT;

  float dxRefWS = 0.f;
  if (wSignTreatment) {
    // DvB: what happens if we use the actual momentum from VeloUT here instead of a constant?
    dxRefWS = 0.9f * calcDxRef(
                       SciFi::Tracking::wrongSignPT,
                       velo_state); // make windows a bit too small - FIXME check effect of this, seems wrong
  }

  int iZoneStartingPoint = side > 0 ? constArrays->zoneoffsetpar : 0;

  for (int i=threadIdx.y; i<LookingForward::number_of_x_layers; i+=blockDim.y) { 
    const auto iZone = iZoneStartingPoint + i;
    const float zZone = constArrays->xZone_zPos[iZone - iZoneStartingPoint];
    const float xInZone = linear_parameterization(xAtRef, velo_state.tx, zZone);
    const float yInZone = linear_parameterization(yAtRef, velo_state.ty, zZone);

    // if (side > 0) {
    //   if (
    //     !isInside(xInZone, SciFi::Tracking::xLim_Min, SciFi::Tracking::xLim_Max) ||
    //     !isInside(yInZone, SciFi::Tracking::yLim_Min, SciFi::Tracking::yLim_Max))
    //     continue;
    // }
    // else {
    //   if (
    //     !isInside(xInZone, SciFi::Tracking::xLim_Min, SciFi::Tracking::xLim_Max) ||
    //     !isInside(yInZone, side * SciFi::Tracking::yLim_Max, side * SciFi::Tracking::yLim_Min))
    //     continue;
    // }

    // extrapolate dxRef (x window on reference plane) to plane of current zone
    const float xTol = (zZone < SciFi::Tracking::zReference) ?
                         dxRef * zZone / SciFi::Tracking::zReference :
                         dxRef * (zZone - zMag) / (SciFi::Tracking::zReference - zMag);
    float xMin = xInZone - xTol;
    float xMax = xInZone + xTol;

    if (SciFi::Tracking::useMomentumEstimate) { // For VeloUT tracks, suppress check if track actually has qop set,
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
    const int x_zone_offset_begin = scifi_hit_count.zone_offset(constArrays->xZones[iZone]);
    const int x_zone_size = scifi_hit_count.zone_number_of_hits(constArrays->xZones[iZone]);
    int hits_within_bounds_start = binary_search_leftmost(scifi_hits.x0 + x_zone_offset_begin, x_zone_size, xMin);
    const int hits_within_bounds_size = binary_search_leftmost(scifi_hits.x0 + x_zone_offset_begin + hits_within_bounds_start, x_zone_size - hits_within_bounds_start, xMax);
    hits_within_bounds_start += x_zone_offset_begin;

    // Initialize windows
    initial_windows[i * 8 * number_of_tracks] = hits_within_bounds_start;
    initial_windows[(i * 8 + 1) * number_of_tracks] = hits_within_bounds_size;

    // Skip making range but continue if the size is zero
    if (hits_within_bounds_size > 0) {
      // Now match the stereo hits
      const float this_uv_z = constArrays->uvZone_zPos[iZone - iZoneStartingPoint];
      const float xInUv = linear_parameterization(xAtRef, velo_state.tx, this_uv_z);
      const float zRatio = (this_uv_z - zMag) / (zZone - zMag);
      const float dx = yInZone * constArrays->uvZone_dxdy[iZone - iZoneStartingPoint];
      const float xCentral = xInZone + dx;
      const float xPredUv = xInUv + (scifi_hits.x0[hits_within_bounds_start] - xInZone) * zRatio - dx;
      const float maxDx = SciFi::Tracking::tolYCollectX +
                          (std::abs(scifi_hits.x0[hits_within_bounds_start] - xCentral) + std::abs(yInZone)) * SciFi::Tracking::tolYSlopeCollectX;
      const float xMinUV = xPredUv - maxDx;
      const float xPredUVProto = xInUv - xInZone * zRatio - dx;
      const float maxDxProto = SciFi::Tracking::tolYCollectX + std::abs(yInZone) * SciFi::Tracking::tolYSlopeCollectX;

      // Get bounds in UV layers
      // do one search on the same side as the x module
      // if we are close to y = 0, also look within a region on the other side module ("triangle search")
      const int uv_zone_offset_begin = scifi_hit_count.zone_offset(constArrays->uvZones[iZone]);
      const int uv_zone_size = scifi_hit_count.zone_number_of_hits(constArrays->uvZones[iZone]);
      const int hits_within_uv_bounds = binary_search_leftmost(scifi_hits.x0 + uv_zone_offset_begin, uv_zone_size, xMinUV);

      initial_windows[(i * 8 + 2) * number_of_tracks] = hits_within_uv_bounds + uv_zone_offset_begin;
      initial_windows[(i * 8 + 3) * number_of_tracks] = uv_zone_size - hits_within_uv_bounds;

      float* initial_windows_f = (float*) &initial_windows[0];
      initial_windows_f[(i * 8 + 4) * number_of_tracks] = xPredUVProto;
      initial_windows_f[(i * 8 + 5) * number_of_tracks] = zRatio;
      initial_windows_f[(i * 8 + 6) * number_of_tracks] = maxDxProto;
      initial_windows_f[(i * 8 + 7) * number_of_tracks] = xCentral;
    }
  }
}

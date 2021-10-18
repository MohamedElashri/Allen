/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once
#include <iostream>
#include <iomanip>

#include "BackendCommon.h"
#include "States.cuh"

struct CaloGeometry {
  uint32_t code_offset = 0;
  uint32_t card_channels = 0;
  uint32_t max_index = 0;
  float pedestal = 0.f;
  uint16_t* channels = nullptr;
  uint16_t* neighbors = nullptr;
  float* xy = nullptr;
  float* gain = nullptr;
  float* toLocalMatrix = nullptr;
  float* calo_planes = nullptr;
  float module_size = 0.f;
  uint32_t* digits_ranges = nullptr;
  uint32_t vec_sourceids_size = 0;
  uint32_t* vec_sourceids = nullptr;
  uint32_t vec_febs_size = 0;
  uint32_t* vec_febs = nullptr;
  uint32_t vec_febIndices_size = 0;
  uint32_t* vec_febIndices = nullptr;

  __device__ __host__ CaloGeometry(const char* raw_geometry)
  {
    const char* p = raw_geometry;
    code_offset = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip code_offset
    card_channels = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip card_channels
    max_index = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip max_index
    pedestal = *((float*) p);
    p += sizeof(float); // Skip pedestal
    const auto channels_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip channels_size
    channels = (uint16_t*) p;
    p += sizeof(uint16_t) * channels_size; // Skip channels
    const auto neighbors_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip neighbors_size
    neighbors = (uint16_t*) p;
    p += sizeof(uint16_t) * neighbors_size; // Skip neighbors
    const uint32_t xy_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip xy_size
    xy = (float*) p;
    p += sizeof(float) * xy_size; // Skip xy
    const uint32_t gain_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip gain_size
    gain = (float*) p;
    p += sizeof(float) * gain_size; // Skip gain
    const uint32_t toLocalMatrix_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip toLocalMatrix_size
    toLocalMatrix = (float*) p;
    p += sizeof(float) * toLocalMatrix_size; // Skip toLocalMatrix
    const uint32_t calo_planes_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip calo_planes_size
    calo_planes = (float*) p;
    p += sizeof(float) * calo_planes_size; // Skip calo_planes
    module_size = *((float*) p);
    p += sizeof(float); // Skip module_size
    const uint32_t digits_ranges_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip digits_ranges_size
    digits_ranges = (uint32_t*) p;
    p += sizeof(float) * digits_ranges_size; // Skip digits_ranges
    vec_febs_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip vec_febs_size
    vec_febs = (uint32_t*) p;
    p += sizeof(uint32_t) * vec_febs_size; // Skip vec_febs
    vec_febIndices_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip vec_febIndices_size
    vec_febIndices = (uint32_t*) p;
    //    p += sizeof(uint32_t) * vec_febIndices_size; // Skip vec_febs
  }

  __device__ __host__ inline uint32_t getFEB(uint32_t source_id, int nFeb) const
  {
    return vec_febs[3 * (source_id & 0x7ff) + nFeb];
  }

  __device__ __host__ inline uint32_t getFEBindex(uint32_t source_id, int nFeb) const
  {
    return vec_febIndices[3 * (source_id & 0x7ff) + nFeb];
  }

  __device__ __host__ inline float getX(uint16_t cellid) const { return xy[2 * cellid]; }

  __device__ __host__ inline float getY(uint16_t cellid) const { return xy[2 * cellid + 1]; }

  // Get area, where 0 = Outer region, 1 = Middle region, 2 = Inner region
  __device__ __host__ inline int getECALArea(uint16_t cellid) const
  {
    return cellid < digits_ranges[1] ? 0 : (cellid < digits_ranges[2] ? 1 : (cellid < digits_ranges[3] ? 2 : -1));
  }

  // Convert ADC to energy
  __device__ __host__ inline float getE(uint16_t cellid, int16_t adc) const { return gain[cellid] * (adc - pedestal); }

  // Intercept track with calo plane, where 0 is front, 1 is showermax, 2 is back
  __device__ __host__ inline float getZFromTrackToCaloplaneIntersection(MiniState state, int plane) const
  {
    // Get front, showermax or back plane a,b,c,d parameters (A plane in 3D is defined as a*x+b*y+c*z+d=0)
    float a(0.f), b(0.f), c(0.f), d(0.f);
    // Front plane
    if (plane == 0) {
      a = calo_planes[0];
      b = calo_planes[1];
      c = calo_planes[2];
      d = calo_planes[3];
    }
    // Showermax plane
    else if (plane == 1) {
      a = calo_planes[4];
      b = calo_planes[5];
      c = calo_planes[6];
      d = calo_planes[7];
    }
    // Back plane
    else if (plane == 2) {
      a = calo_planes[8];
      b = calo_planes[9];
      c = calo_planes[10];
      d = calo_planes[11];
    }
    else {
      return 99999.f;
    }

    // Compute z position of intersection between the track line and the calo plane
    float z = (-a * state.x + a * state.tx * state.z - b * state.y + b * state.ty * state.z - d) /
              (a * state.tx + b * state.ty + c);
    // float x = state.x + state.tx * (z - state.z);
    // float y = state.y + state.ty * (z - state.z);

    return z;
  }

  // Get CellID from x,y,z coordinates (only valid for the ECAL)
  __device__ __host__ inline uint16_t getEcalID(float x, float y, float z) const
  {
    // Hardcode the cell size of the ECAL
    float cell_size_outer = module_size;
    float cell_size_middle = module_size / 2.f;
    float cell_size_inner = module_size / 3.f;

    // Transform global coordinates to local system. Only change y, because x is unaffected and z is not used here
    y = toLocalMatrix[5] * y + toLocalMatrix[6] * z + toLocalMatrix[7];

    // ECAL acceptance
    if (
      fabsf(x) < cell_size_outer * 32 && fabsf(y) < cell_size_outer * 26 &&
      !(fabsf(x) < cell_size_outer * 3 - cell_size_inner && fabsf(y) < cell_size_outer * 2)) {
      // Outer region
      if (!(fabsf(x) < cell_size_outer * 16 && fabsf(y) < cell_size_outer * 10)) {
        // Lower part
        if (y < -cell_size_outer * 10) {
          return floorf(x / cell_size_outer) + 32 + (floorf(y / cell_size_outer) + 26) * 64;
        }
        // Upper part
        else if (y > cell_size_outer * 10) {
          return floorf(x / cell_size_outer) + 32 + (floorf(y / cell_size_outer) - 10) * 64 + 1664;
        }
        // Left middle part
        else if (x < -cell_size_outer * 16) {
          return floorf(x / cell_size_outer) + 32 + (floorf(y / cell_size_outer) + 10) * 32 + 1024;
        }
        // Right middle part
        else {
          return floorf(x / cell_size_outer) - 16 + (floorf(y / cell_size_outer) + 10) * 32 + 1040;
        }
      }
      // Middle region
      else if (!(fabsf(x) < cell_size_outer * 8 && fabsf(y) < cell_size_outer * 6)) {
        // Lower part
        if (y < -cell_size_outer * 6) {
          return floorf(x / cell_size_middle) + 32 + (floorf(y / cell_size_middle) + 20) * 64 + 2688;
        }
        // Upper part
        else if (y > cell_size_outer * 6) {
          return floorf(x / cell_size_middle) + 32 + (floorf(y / cell_size_middle) - 12) * 64 + 3968;
        }
        // Left middle part
        else if (x < -cell_size_outer * 8) {
          return floorf(x / cell_size_middle) + 32 + (floorf(y / cell_size_middle) + 12) * 32 + 3200;
        }
        // Right middle part
        else {
          return floorf(x / cell_size_middle) - 16 + (floorf(y / cell_size_middle) + 12) * 32 + 3216;
        }
      }
      // Inner region
      else {
        // Lower part
        if (y < -cell_size_outer * 2) {
          return floorf(x / cell_size_inner) + 24 + (floorf(y / cell_size_inner) + 18) * 48 + 4480;
        }
        // Upper part
        else if (y > cell_size_outer * 2) {
          return floorf(x / cell_size_inner) + 24 + (floorf(y / cell_size_inner) - 6) * 48 + 5440;
        }
        // Left middle part
        else if (x < -(cell_size_outer * 3 - cell_size_inner)) {
          return floorf(x / cell_size_inner) + 24 + (floorf(y / cell_size_inner) + 6) * 32 + 5056;
        }
        // Right middle part
        else {
          return floorf(x / cell_size_inner) - 8 + (floorf(y / cell_size_inner) + 6) * 32 + 5072;
        }
      }
    }
    else {
      return 9999;
    }
  }
};

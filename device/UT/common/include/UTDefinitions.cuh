#pragma once

#include "SystemOfUnits.h"
#include "VeloEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "UTRaw.cuh"

#include <ostream>
#include <stdint.h>
#include <vector>

namespace UT {
  namespace Decoding {

    static constexpr int frac_mask = 0x0003U; // frac
    static constexpr int chan_mask = 0x3FFCU; // channel
    static constexpr int thre_mask = 0x8000U; // threshold

    static constexpr int frac_offset = 0;  // frac
    static constexpr int chan_offset = 2;  // channel
    static constexpr int thre_offset = 15; // threshold

    static constexpr uint ut_number_of_sectors_per_board = 6;
    static constexpr uint ut_number_of_geometry_sectors = 1048;
    static constexpr uint ut_decoding_in_order_threads_x = 64;
    static constexpr uint ut_max_hits_shared_sector_group = 256;

  } // namespace Decoding

  static constexpr int num_atomics = 3;

  namespace Constants {
    static constexpr uint num_thr_compassut = 128;
    static constexpr uint max_value_considered_before_found = 16;

    /* Detector description
       There are two stations with two layers each
    */
    static constexpr uint n_layers = 4;
    static constexpr uint n_regions_in_layer = 3;

    /* Cut-offs */
    static constexpr uint max_num_tracks = 400; // to do: what is the best / safest value here?
    static constexpr uint max_track_size = 4;

    // zMidUT is a position of normalization plane which should
    // to be close to z middle of UT ( +- 5 cm ).
    // No need to update with small UT movement.
    static constexpr float zMidUT = 2484.6f;
    //  distToMomentum is properly recalculated in UTMagnetTool when B field changes
    static constexpr float distToMomentum = 4.0212e-05f;
    static constexpr float zKink = 1780.0f;

    static constexpr float maxPseudoChi2 = 1280.0f;
    static constexpr float maxXSlope = 0.350f;
    static constexpr float maxYSlope = 0.300f;
    static constexpr float centralHoleSize = 33.0f * Gaudi::Units::mm;
    static constexpr float passHoleSize = 40.0f * Gaudi::Units::mm;
    static constexpr bool passTracks = false;

    // Scale the z-component, to not run into numerical problems with floats
    // first add to sum values from hit at xMidField, zMidField hit
    static constexpr float zDiff = 0.001f * (zKink - zMidUT);
    //
    static constexpr float magFieldParams_0 = 2010.0f;
    static constexpr float magFieldParams_1 = -2240.0f;
    static constexpr float magFieldParams_2 = -71330.f;
    //
    static constexpr float LD3Hits = -0.5f;
  } // namespace Constants
} // namespace UT

struct UTBoards {
  uint32_t number_of_boards;
  uint32_t number_of_channels;
  uint32_t* stripsPerHybrids;
  uint32_t* stations;
  uint32_t* layers;
  uint32_t* detRegions;
  uint32_t* sectors;
  uint32_t* chanIDs;

  __device__ __host__ UTBoards(const char* ut_boards)
  {
    uint32_t* p = (uint32_t*) ut_boards;
    number_of_boards = *p;
    p += 1;
    number_of_channels = UT::Decoding::ut_number_of_sectors_per_board * number_of_boards;
    stripsPerHybrids = p;
    p += number_of_boards;
    stations = p;
    p += number_of_channels;
    layers = p;
    p += number_of_channels;
    detRegions = p;
    p += number_of_channels;
    sectors = p;
    p += number_of_channels;
    chanIDs = p;
    p += number_of_channels;
  }

  UTBoards(const std::vector<char>& ut_boards) : UTBoards {ut_boards.data()} {}
};

struct UTGeometry {
  uint32_t number_of_sectors = 0;
  uint32_t* firstStrip = nullptr;
  float* pitch = nullptr;
  float* dy = nullptr;
  float* dp0diX = nullptr;
  float* dp0diY = nullptr;
  float* dp0diZ = nullptr;
  float* p0X = nullptr;
  float* p0Y = nullptr;
  float* p0Z = nullptr;
  float* cos = nullptr;

  __device__ __host__ UTGeometry(const char* ut_geometry)
  {
    uint32_t* p = (uint32_t*) ut_geometry;
    number_of_sectors = *((uint32_t*) p);
    p += 1;
    firstStrip = (uint32_t*) p;
    p += UT::Decoding::ut_number_of_geometry_sectors;
    pitch = (float*) p;
    p += UT::Decoding::ut_number_of_geometry_sectors;
    dy = (float*) p;
    p += UT::Decoding::ut_number_of_geometry_sectors;
    dp0diX = (float*) p;
    p += UT::Decoding::ut_number_of_geometry_sectors;
    dp0diY = (float*) p;
    p += UT::Decoding::ut_number_of_geometry_sectors;
    dp0diZ = (float*) p;
    p += UT::Decoding::ut_number_of_geometry_sectors;
    p0X = (float*) p;
    p += UT::Decoding::ut_number_of_geometry_sectors;
    p0Y = (float*) p;
    p += UT::Decoding::ut_number_of_geometry_sectors;
    p0Z = (float*) p;
    p += UT::Decoding::ut_number_of_geometry_sectors;
    cos = (float*) p;
    p += UT::Decoding::ut_number_of_geometry_sectors;
  }

  UTGeometry(const std::vector<char>& ut_geometry) : UTGeometry {ut_geometry.data()} {}
};

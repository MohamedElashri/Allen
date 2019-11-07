#pragma once

#include <stdint.h>
#include <vector>
#include <ostream>

#include "CudaCommon.h"
#include "Common.h"
#include "Logger.h"
#include "States.cuh"
#include "SciFiRaw.cuh"

#include "assert.h"

namespace SciFi {

  // need 3 arrays (size: number_of_events) for copy_and_prefix_sum_scifi_t
  static constexpr int num_atomics = 3;

  namespace Tracking {

    // The base PT threshold which is common to all algorithms
    constexpr float minPt = 500 * Gaudi::Units::MeV;

    constexpr int max_scifi_hits = 20; // for x and u/v layers
    constexpr int nTrackParams = 9;

    constexpr float tolYMag = 10.f * Gaudi::Units::mm;
    constexpr float tolYMagSlope = 0.015f;

    // parameterizations
    constexpr float byParams = -0.667996f;
    constexpr float cyParams = -3.68424e-05f;

    // stereo hit matching
    // Not used in Looking Forward when using qop from VeloUT
    constexpr float tolYCollectX = 3.5f * Gaudi::Units::mm;        // 4.1* Gaudi::Units::mm ;
    constexpr float tolYSlopeCollectX = 0.001f * Gaudi::Units::mm; // 0.0018 * Gaudi::Units::mm ;

    // veloUT momentum estimate
    constexpr bool useMomentumEstimate = true;
    constexpr bool useWrongSignWindow = true;
    constexpr float wrongSignPT = 500.f * Gaudi::Units::MeV;
    constexpr float wrongSignQoP = 1.f / wrongSignPT;

    // z Reference plane
    constexpr float zReference = 8520.f * Gaudi::Units::mm; // in T2
    constexpr float zRefInv = 1.f / zReference;

    // TODO: CHECK THESE VALUES USING FRAMEWORK
    constexpr float xLim_Max = 3300.f;
    constexpr float yLim_Max = 2500.f;
    constexpr float xLim_Min = -3300.f;
    constexpr float yLim_Min = -25.f;

    // TO BE READ FROM XML EVENTUALLY
    // constexpr float magscalefactor = -1;
    constexpr int zoneoffsetpar = 6;

    struct Arrays {
      // Returns whether the current layer is an X plane
      const bool is_x_plane[12] {1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1};

      // the Magnet Parametrization
      // parameterized in offset [0], (slope difference due to kick)^2 [1],
      // tx^2 [2], ty^2 [3]
      const float zMagnetParams[4] = {5212.38f, 406.609f, -1102.35f, -498.039f};

      // more Parametrizations
      const float xParams[2] = {18.6195f, -5.55793f};

      // momentum Parametrization
      const float momentumParams[6] = {1.21014f, 0.637339f, -0.200292f, 0.632298f, 3.23793f, -27.0259f};

      // covariance values
      const float covarianceValues[5] = {4.0f, 400.0f, 4.e-6f, 1.e-4f, 0.1f};

      // definition of zones
      // access upper with offset of 6
      const int zoneoffsetpar = 6;
      const int xZones[12] = {0, 6, 8, 14, 16, 22, 1, 7, 9, 15, 17, 23};
      const int uvZones[12] = {2, 4, 10, 12, 18, 20, 3, 5, 11, 13, 19, 21};

      // ASSORTED GEOMETRY VALUES, eventually read this from some xml
      const float xZone_zPos[6] = {7826.f, 8036.f, 8508.f, 8718.f, 9193.f, 9403.f};
      const float uvZone_zPos[6] =
        {7896.f, 7966.f, 8578.f, 8648.f, 9263.f, 9333.f}; //, 7896., 7966., 8578., 8648., 9263., 9333.};
      const float uvZone_dxdy[12] = {0.0874892f,
                                     -0.0874892f,
                                     0.0874892f,
                                     -0.0874892f,
                                     0.0874892f,
                                     -0.0874892f,
                                     0.0874892f,
                                     -0.0874892f,
                                     0.0874892f,
                                     -0.0874892f,
                                     0.0874892f,
                                     -0.0874892f};
      const float Zone_dzdy[24] = {0.0036010f};

      // this is used by looking_forward_sbt maybe this is not the right place to put it
      const float uv_dx[6] = {1.6739478541449213f,
                              1.6738495069872612f,
                              1.935683825160498f,
                              1.9529279746403518f,
                              2.246931985749485f,
                              2.2797556995480273f};
    };

  } // namespace Tracking

  namespace Constants {
    // Detector description
    // There are three stations with four layers each
    static constexpr uint n_stations = 3;
    static constexpr uint n_layers_per_station = 4;
    static constexpr uint n_zones = 24;
    static constexpr uint n_layers = 12;
    static constexpr uint n_mats = 1024;

    // FIXME_GEOMETRY_HARDCODING
    // todo: use dzdy defined in geometry, read by mat
    static constexpr float dzdy = 0.003601f;

    /**
     * The following constants are based on the number of modules per quarter.
     * There are currently 80 raw banks per SciFi station:
     *
     *   The first two stations (first 160 raw banks) encode 4 modules per quarter.
     *   The last station (raw banks 161 to 240) encode 5 modules per quarter.
     *
     * The raw data is sorted such that every four consecutive modules are either
     * monotonically increasing or monotonically decreasing, following a particular pattern.
     * Thus, it is possible to decode the first 160 raw banks in v4 in parallel since the
     * position of each hit is known by simply knowing the current iteration in the raw bank,
     * and using that information as a relative index, given the raw bank offset.
     * This kind of decoding is what we call "direct decoding".
     *
     * However, the last 80 raw banks cannot be decoded in this manner. Therefore, the
     * previous method is employed for these last raw banks, consisting in a two-step
     * decoding.
     *
     * The constants below capture this idea. The prefix sum needed contains information about
     * "mat groups" (the first 160 raw banks, since the offset of the group is enough).
     * However, for the last sector, every mat offset is stored individually.
     */
    static constexpr uint n_consecutive_raw_banks = 160;
    static constexpr uint n_mats_per_consec_raw_bank = 4;
    static constexpr uint n_mat_groups_and_mats = 544;
    static constexpr uint mat_index_substract = n_consecutive_raw_banks * 3;
    static constexpr uint n_mats_without_group = n_mats - n_consecutive_raw_banks * n_mats_per_consec_raw_bank;

    static constexpr float ZEndT = 9410.f * Gaudi::Units::mm; // FIXME_GEOMETRY_HARDCODING

    /* Cut-offs */
    static constexpr uint max_numhits_per_event = 10000;
    static constexpr uint max_hit_candidates_per_layer = 200;

    // Looking Forward
    static constexpr int max_SciFi_tracks_per_UT_track = 10;
    static constexpr int max_tracks = 1000;
    static constexpr int max_lf_tracks = 6000;
    static constexpr int max_track_size = n_layers;

    static constexpr int max_track_candidates = 2000;
    static constexpr int max_track_candidate_size = 4;
    static constexpr int hit_layer_offset = 6;
  } // namespace Constants

  /**
   * @brief SciFi geometry description typecast.
   */
  struct SciFiGeometry {
    size_t size;
    uint32_t number_of_stations;
    uint32_t number_of_layers_per_station;
    uint32_t number_of_layers;
    uint32_t number_of_quarters_per_layer;
    uint32_t number_of_quarters;
    uint32_t* number_of_modules; // for each quarter
    uint32_t number_of_mats_per_module;
    uint32_t number_of_mats;
    uint32_t number_of_tell40s;
    uint32_t* bank_first_channel;
    uint32_t max_uniqueMat;
    float* mirrorPointX;
    float* mirrorPointY;
    float* mirrorPointZ;
    float* ddxX;
    float* ddxY;
    float* ddxZ;
    float* uBegin;
    float* halfChannelPitch;
    float* dieGap;
    float* sipmPitch;
    float* dxdy;
    float* dzdy;
    float* globaldy;

    __device__ __host__ SciFiGeometry() {}

    /**
     * @brief Typecast from std::vector.
     */
    SciFiGeometry(const std::vector<char>& geometry);

    /**
     * @brief Just typecast, no size check.
     */
    __device__ __host__ SciFiGeometry(const char* geometry);
  };

  struct SciFiChannelID {
    uint32_t channelID;
    __device__ __host__ uint32_t channel() const;
    __device__ __host__ uint32_t sipm() const;
    __device__ __host__ uint32_t mat() const;
    __device__ __host__ uint32_t uniqueMat() const;
    __device__ __host__ uint32_t correctedUniqueMat() const;
    __device__ __host__ uint32_t module() const;
    __device__ __host__ uint32_t correctedModule() const;
    __device__ __host__ uint32_t uniqueModule() const;
    __device__ __host__ uint32_t quarter() const;
    __device__ __host__ uint32_t uniqueQuarter() const;
    __device__ __host__ uint32_t layer() const;
    __device__ __host__ uint32_t uniqueLayer() const;
    __device__ __host__ uint32_t station() const;
    __device__ __host__ uint32_t die() const;
    __device__ __host__ bool isBottom() const;
    __device__ __host__ bool reversedZone() const;
    __device__ __host__ SciFiChannelID operator+=(const uint32_t& other);
    __host__ std::string toString();
    __device__ __host__ SciFiChannelID(const uint32_t channelID);
    // from FTChannelID.h (generated)
    enum channelIDMasks {
      channelMask = 0x7fL,
      sipmMask = 0x180L,
      matMask = 0x600L,
      moduleMask = 0x3800L,
      quarterMask = 0xc000L,
      layerMask = 0x30000L,
      stationMask = 0xc0000L,
      uniqueLayerMask = layerMask | stationMask,
      uniqueQuarterMask = quarterMask | layerMask | stationMask,
      uniqueModuleMask = moduleMask | quarterMask | layerMask | stationMask,
      uniqueMatMask = matMask | moduleMask | quarterMask | layerMask | stationMask,
      uniqueSiPMMask = sipmMask | matMask | moduleMask | quarterMask | layerMask | stationMask
    };
    enum channelIDBits {
      channelBits = 0,
      sipmBits = 7,
      matBits = 9,
      moduleBits = 11,
      quarterBits = 14,
      layerBits = 16,
      stationBits = 18
    };
  };

  __device__ uint32_t channelInBank(uint32_t c);
  __device__ uint16_t getLinkInBank(uint16_t c);
  __device__ int cell(uint16_t c);
  __device__ int fraction(uint16_t c);
  __device__ bool cSize(uint16_t c);

} // namespace SciFi

#pragma once

#include <stdint.h>
#include <vector>
#include <ostream>
#include <sstream>
#include "CudaCommon.h"
#include "Common.h"
#include "Logger.h"
#include "States.cuh"
#include "SciFiRaw.cuh"

#include "assert.h"

namespace SciFi {

  // need 3 arrays (size: number_of_events) for copy_and_prefix_sum_scifi_t
  static constexpr int num_atomics = 3;

  namespace Constants {
    // Detector description
    // There are three stations with four layers each
    static constexpr unsigned n_stations = 3;
    static constexpr unsigned n_layers_per_station = 4;
    static constexpr unsigned n_zones = 24;
    static constexpr unsigned n_layers = 12;
    static constexpr unsigned n_mats = 1024;

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
    static constexpr unsigned n_consecutive_raw_banks = 160;
    static constexpr unsigned n_mats_per_consec_raw_bank = 4;
    static constexpr unsigned n_mat_groups_and_mats = 544;
    static constexpr unsigned mat_index_substract = n_consecutive_raw_banks * 3;
    static constexpr unsigned n_mats_without_group = n_mats - n_consecutive_raw_banks * n_mats_per_consec_raw_bank;

    // FIXME_GEOMETRY_HARDCODING
    // todo: use dzdy defined in geometry, read by mat
    static constexpr float dzdy = 0.003601f;
    static constexpr float ZEndT = 9410.f * Gaudi::Units::mm; // FIXME_GEOMETRY_HARDCODING

    // Looking Forward
    static constexpr int max_track_size = n_layers;
    static constexpr int max_track_candidate_size = 4;
    static constexpr int hit_layer_offset = 6;
    static constexpr int max_SciFi_tracks_per_UT_track = 1;

    // This constant is for the HostBuffer reserve method, when validating
    static constexpr int max_tracks = 1000;
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
     * @brief Just typecast, no size check.
     */
    __device__ __host__ SciFiGeometry(const char* geometry)
    {
      const char* p = geometry;

      number_of_stations = *((uint32_t*) p);
      p += sizeof(uint32_t);
      number_of_layers_per_station = *((uint32_t*) p);
      p += sizeof(uint32_t);
      number_of_layers = *((uint32_t*) p);
      p += sizeof(uint32_t);
      number_of_quarters_per_layer = *((uint32_t*) p);
      p += sizeof(uint32_t);
      number_of_quarters = *((uint32_t*) p);
      p += sizeof(uint32_t);
      number_of_modules = (uint32_t*) p;
      p += number_of_quarters * sizeof(uint32_t);
      number_of_mats_per_module = *((uint32_t*) p);
      p += sizeof(uint32_t);
      number_of_mats = *((uint32_t*) p);
      p += sizeof(uint32_t);
      number_of_tell40s = *((uint32_t*) p);
      p += sizeof(uint32_t);
      bank_first_channel = (uint32_t*) p;
      p += number_of_tell40s * sizeof(uint32_t);
      max_uniqueMat = *((uint32_t*) p);
      p += sizeof(uint32_t);
      mirrorPointX = (float*) p;
      p += sizeof(float) * max_uniqueMat;
      mirrorPointY = (float*) p;
      p += sizeof(float) * max_uniqueMat;
      mirrorPointZ = (float*) p;
      p += sizeof(float) * max_uniqueMat;
      ddxX = (float*) p;
      p += sizeof(float) * max_uniqueMat;
      ddxY = (float*) p;
      p += sizeof(float) * max_uniqueMat;
      ddxZ = (float*) p;
      p += sizeof(float) * max_uniqueMat;
      uBegin = (float*) p;
      p += sizeof(float) * max_uniqueMat;
      halfChannelPitch = (float*) p;
      p += sizeof(float) * max_uniqueMat;
      dieGap = (float*) p;
      p += sizeof(float) * max_uniqueMat;
      sipmPitch = (float*) p;
      p += sizeof(float) * max_uniqueMat;
      dxdy = (float*) p;
      p += sizeof(float) * max_uniqueMat;
      dzdy = (float*) p;
      p += sizeof(float) * max_uniqueMat;
      globaldy = (float*) p;
      p += sizeof(float) * max_uniqueMat;

      size = p - geometry;
    }

    /**
     * @brief Typecast from std::vector.
     */
    SciFiGeometry(const std::vector<char>& geometry) : SciFiGeometry::SciFiGeometry(geometry.data()) {}
  };

  struct SciFiChannelID {
    uint32_t channelID;

    __host__ std::string toString()
    {
      std::ostringstream s;
      s << "{ SciFiChannelID : "
        << " channel =" << std::to_string(channel()) << " sipm =" << std::to_string(sipm())
        << " mat =" << std::to_string(mat()) << " module=" << std::to_string(module())
        << " quarter=" << std::to_string(quarter()) << " layer=" << std::to_string(layer())
        << " station=" << std::to_string(station()) << " }";
      return s.str();
    }

    __device__ __host__ uint32_t channel() const { return (uint32_t)((channelID & channelMask) >> channelBits); }

    __device__ __host__ uint32_t sipm() const { return ((channelID & sipmMask) >> sipmBits); }

    __device__ __host__ uint32_t mat() const { return ((channelID & matMask) >> matBits); }

    __device__ __host__ uint32_t module() const { return ((channelID & moduleMask) >> moduleBits); }

    __device__ __host__ unsigned correctedModule() const
    {
      // Returns local module ID in ascending x order.
      // There may be a faster way to do this.
      unsigned uQuarter = uniqueQuarter() - 16;
      unsigned module_count = uQuarter >= 32 ? 6 : 5;
      unsigned q = uQuarter % 4;
      if (q == 0 || q == 2) return module_count - 1 - module();
      if (q == 1 || q == 3) return module();
      return 0;
    }

    __device__ __host__ uint32_t quarter() const { return ((channelID & quarterMask) >> quarterBits); }

    __device__ __host__ uint32_t layer() const { return ((channelID & layerMask) >> layerBits); }

    __device__ __host__ uint32_t station() const { return ((channelID & stationMask) >> stationBits); }

    __device__ __host__ uint32_t uniqueLayer() const { return ((channelID & uniqueLayerMask) >> layerBits); }

    __device__ __host__ uint32_t uniqueMat() const { return ((channelID & uniqueMatMask) >> matBits); }

    __device__ __host__ uint32_t correctedUniqueMat() const
    {
      // Returns global mat ID in ascending x order without any gaps.
      // Geometry dependent. No idea how to not hardcode this.
      uint32_t quarter = uniqueQuarter() - 16;
      return (quarter < 32 ? quarter : 32) * 5 * 4 + (quarter >= 32 ? quarter - 32 : 0) * 6 * 4 +
             4 * correctedModule() + (reversedZone() ? 3 - mat() : mat());
    }

    __device__ __host__ uint32_t uniqueModule() const { return ((channelID & uniqueModuleMask) >> moduleBits); }

    __device__ __host__ uint32_t uniqueQuarter() const { return ((channelID & uniqueQuarterMask) >> quarterBits); }

    __device__ __host__ uint32_t die() const { return ((channelID & 0x40) >> 6); }

    __device__ __host__ bool isBottom() const { return (quarter() == 0 || quarter() == 1); }

    __device__ __host__ bool reversedZone() const
    {
      unsigned zone = ((uniqueQuarter() - 16) >> 1) % 4;
      return zone == 1 || zone == 2;
    }

    __device__ __host__ SciFiChannelID(const uint32_t channelID) : channelID(channelID) {}

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

  __device__ inline uint32_t channelInBank(const uint32_t c) { return (c >> SciFiRawBankParams::cellShift); }

  __device__ inline uint16_t getLinkInBank(const uint16_t c) { return (c >> SciFiRawBankParams::linkShift); }

  __device__ inline int cell(const uint16_t c)
  {
    return (c >> SciFiRawBankParams::cellShift) & SciFiRawBankParams::cellMaximum;
  }

  __device__ inline int fraction(const uint16_t c)
  {
    return (c >> SciFiRawBankParams::fractionShift) & SciFiRawBankParams::fractionMaximum;
  }

  __device__ inline bool cSize(const uint16_t c)
  {
    return (c >> SciFiRawBankParams::sizeShift) & SciFiRawBankParams::sizeMaximum;
  }
} // namespace SciFi

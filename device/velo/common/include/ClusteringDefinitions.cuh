/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "CudaCommon.h"
#include <cstdint>
#include <vector>
#include <cassert>
#include <cstring>
#include "Logger.h"
#include "VeloDefinitions.cuh"

namespace VeloClustering {
  static constexpr uint32_t mask_bottom = 0xFFFEFFFF;
  static constexpr uint32_t mask_top = 0xFFFF7FFF;
  static constexpr uint32_t mask_top_left = 0x7FFF7FFF;
  static constexpr uint32_t mask_bottom_right = 0xFFFEFFFE;
  static constexpr uint32_t mask_ltr_top_right = 0x7FFF0000;
  static constexpr uint32_t mask_rtl_bottom_left = 0x0000FFFE;
  static constexpr uint32_t max_clustering_iterations = 12;
  static constexpr uint32_t lookup_table_size = 9;
} // namespace VeloClustering

namespace Allen {
  namespace VPChannelID {
    /// Offsets of bitfield channelID
    enum channelIDBits { rowBits = 0, colBits = 8, chipBits = 16, sensorBits = 18 };

    /// Bitmasks for bitfield channelID
    enum channelIDMasks { rowMask = 0xffL, colMask = 0xff00L, chipMask = 0x30000L, sensorMask = 0xffc0000L };

    enum channelIDtype { Velo = 1, TT, IT, OT, Rich, Calo, Muon, VP, FT = 10, UT, HC };
  } // namespace VPChannelID

  /// Offsets of bitfield lhcbID
  enum lhcbIDBits { IDBits = 0, detectorTypeBits = 28 };
} // namespace Allen

namespace VP {
  static constexpr unsigned NModules = Velo::Constants::n_modules;
  static constexpr unsigned NSensorsPerModule = 4;
  static constexpr unsigned NSensors = NModules * NSensorsPerModule;
  static constexpr unsigned NChipsPerSensor = 3;
  static constexpr unsigned NRows = 256;
  static constexpr unsigned NColumns = 256;
  static constexpr unsigned NSensorColumns = NColumns * NChipsPerSensor;
  static constexpr unsigned NPixelsPerSensor = NSensorColumns * NRows;
  static constexpr unsigned ChipColumns = 256;
  static constexpr unsigned ChipColumns_division = 8;
  static constexpr unsigned ChipColumns_mask = 0xFF;
  static constexpr double Pitch = 0.055;
} // namespace VP

struct VeloRawEvent {
  uint32_t number_of_raw_banks;
  uint32_t* raw_bank_offset;
  char* payload;

  __device__ __host__ VeloRawEvent(const char* event)
  {
    const char* p = event;
    number_of_raw_banks = *((uint32_t*) p);
    p += sizeof(uint32_t);
    raw_bank_offset = (uint32_t*) p;
    p += (number_of_raw_banks + 1) * sizeof(uint32_t);
    payload = (char*) p;
  }
};

struct VeloRawBank {
  uint32_t sensor_index;
  uint32_t sp_count;
  uint32_t* sp_word;

  // For MEP format
  __device__ __host__ VeloRawBank(uint32_t source_id, const char* fragment)
  {
    sensor_index = source_id;
    const char* p = fragment;
    sp_count = *((uint32_t*) p);
    p += sizeof(uint32_t);
    sp_word = (uint32_t*) p;
  }

  // For Allen format
  __device__ __host__ VeloRawBank(const char* raw_bank)
  {
    const char* p = raw_bank;
    sensor_index = *((uint32_t*) p);
    p += sizeof(uint32_t);
    sp_count = *((uint32_t*) p);
    p += sizeof(uint32_t);
    sp_word = (uint32_t*) p;
  }
};

/**
 * @brief Velo geometry description typecast.
 */
struct VeloGeometry {
  size_t n_trans;
  float module_zs[Velo::Constants::n_modules];
  float local_x[Velo::Constants::number_of_sensor_columns];
  float x_pitch[Velo::Constants::number_of_sensor_columns];
  float ltg[12 * Velo::Constants::n_sensors];

  /**
   * @brief Typecast from std::vector.
   */
  VeloGeometry(std::vector<char> const& geometry)
  {
    char const* p = geometry.data();

    auto copy_array = [&p](const size_t N, float* d) {
      const size_t n = ((size_t*) p)[0];
      if (n != N) {
        error_cout << n << " != " << N << std::endl;
      }
      p += sizeof(size_t);
      std::memcpy(d, p, sizeof(float) * n);
      p += sizeof(float) * n;
    };

    copy_array(Velo::Constants::n_modules, module_zs);
    copy_array(Velo::Constants::number_of_sensor_columns, local_x);
    copy_array(Velo::Constants::number_of_sensor_columns, x_pitch);

    size_t n_ltg = ((size_t*) p)[0];
    assert(n_ltg == Velo::Constants::n_sensors);
    p += sizeof(size_t);
    n_trans = ((size_t*) p)[0];
    assert(n_trans == 12);
    p += sizeof(size_t);
    for (size_t i = 0; i < n_ltg; ++i) {
      std::memcpy(ltg + n_trans * i, p, n_trans * sizeof(float));
      p += sizeof(float) * n_trans;
    }
    const size_t size = p - geometry.data();

    if (size != geometry.size()) {
      error_cout << "Size mismatch for geometry" << std::endl;
    }
  }
};

__device__ __host__ inline uint32_t get_channel_id(const unsigned sensor, const unsigned chip, const unsigned col, const unsigned row)
{
  return (sensor << Allen::VPChannelID::sensorBits) | (chip << Allen::VPChannelID::chipBits) |
         (col << Allen::VPChannelID::colBits) | row;
}

__device__ __host__ inline int32_t get_lhcb_id(const int32_t cid)
{
  return (Allen::VPChannelID::VP << Allen::detectorTypeBits) + cid;
}

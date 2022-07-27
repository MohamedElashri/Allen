/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include <cstdint>
#include <vector>
#include <cassert>
#include <cstring>
#include "Logger.h"
#include "VeloDefinitions.cuh"
#include <MEPTools.h>

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
    enum channelIDBits { rowBits = 0, colBits = 8, chipBits = 16, sensorBits = 18, orfyBits = 26, orfxBits = 27 };

    /// Bitmasks for bitfield channelID
    enum channelIDMasks {
      rowMask = 0xffL,
      colMask = 0xff00L,
      chipMask = 0x30000L,
      sensorMask = 0x3fc0000L,
      orfyMask = 0x4000000L,
      orfxMask = 0x8000000L
    };

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

namespace Velo {
  template<int decoding_version>
  struct VeloRawBank {

    // two sensors per bank so count banks as well as sensors
    uint32_t sourceID = 0;
    uint32_t count = 0;
    uint32_t const* word = nullptr;
    uint16_t size = 0;
    uint16_t type = 0;

    // For MEP format
    __device__ __host__ VeloRawBank(uint32_t source_id, const char* fragment, uint16_t s, uint8_t t)
    {
      type = t;
      sourceID = source_id;
      uint32_t const* p = reinterpret_cast<uint32_t const*>(fragment);
      if constexpr (decoding_version == 2 || decoding_version == 3) {
        count = *p;
        p += 1;
      }
      word = p;
      size = s;
    }

    // For Allen format
    __device__ __host__ VeloRawBank(const char* raw_bank, uint16_t s, uint8_t t) :
      VeloRawBank(*reinterpret_cast<uint32_t const*>(raw_bank), raw_bank + sizeof(uint32_t), s, t)
    {}

    inline __device__ __host__ uint32_t sensor_pair() const { return sourceID & 0x1FFU; }

    inline __device__ __host__ uint32_t sensor_index0() const { return (sourceID & 0x1FFU) << 1; }

    inline __device__ __host__ uint32_t sensor_index1() const { return ((sourceID & 0x1FFU) << 1) | 0x1; }
  };

  template<unsigned decoding_version>
  struct VeloRawEvent {
  private:
    uint32_t m_number_of_raw_banks = 0;
    uint32_t const* m_raw_bank_offset = nullptr;
    uint8_t const* m_raw_bank_types = nullptr;
    uint16_t const* m_raw_bank_sizes = nullptr;
    char const* m_payload = nullptr;

    __device__ __host__ void initialize(const char* event, const uint16_t* sizes, const unsigned char* types)
    {
      const char* p = event;
      m_number_of_raw_banks = *reinterpret_cast<uint32_t const*>(p);
      p += sizeof(uint32_t);
      m_raw_bank_offset = reinterpret_cast<uint32_t const*>(p);
      p += (m_number_of_raw_banks + 1) * sizeof(uint32_t);
      m_payload = p;
      m_raw_bank_types = types;
      m_raw_bank_sizes = sizes;
    }

  public:
    __device__ __host__ VeloRawEvent(const char* event, const uint16_t* sizes, const unsigned char* types)
    {
      initialize(event, sizes, types);
    }

    __device__ __host__ VeloRawEvent(
      const char* dev_velo_raw_input,
      const unsigned* dev_velo_raw_input_offsets,
      const unsigned* dev_velo_raw_input_sizes,
      const unsigned* dev_velo_raw_input_types,
      const unsigned event_number)
    {
      initialize(
        dev_velo_raw_input + dev_velo_raw_input_offsets[event_number],
        Allen::bank_sizes(dev_velo_raw_input_sizes, event_number),
        Allen::bank_types(dev_velo_raw_input_types, event_number));
    }

    __device__ __host__ unsigned number_of_raw_banks() const { return m_number_of_raw_banks; }

    __device__ __host__ VeloRawBank<decoding_version> raw_bank(const unsigned index) const
    {
      return VeloRawBank<decoding_version> {
        m_payload + m_raw_bank_offset[index], m_raw_bank_sizes[index], m_raw_bank_types[index]};
    }
  };

  template<int decoding_version, bool mep_layout>
  using RawEvent =
    std::conditional_t<mep_layout, MEP::RawEvent<VeloRawBank<decoding_version>>, VeloRawEvent<decoding_version>>;
} // namespace Velo

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

__device__ __host__ inline uint32_t get_channel_id(
  const unsigned sensor,
  const unsigned chip,
  const unsigned col,
  const unsigned row,
  const unsigned orfx = 0,
  const unsigned orfy = 0)
{
  return (orfx << Allen::VPChannelID::orfxBits) | (orfy << Allen::VPChannelID::orfyBits) |
         (sensor << Allen::VPChannelID::sensorBits) | (chip << Allen::VPChannelID::chipBits) |
         (col << Allen::VPChannelID::colBits) | row;
}

__device__ __host__ inline int32_t get_lhcb_id(const int32_t cid)
{
  return (Allen::VPChannelID::VP << Allen::detectorTypeBits) + cid;
}

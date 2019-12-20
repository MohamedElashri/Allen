#include <cassert>
#include <cstring>
#include "ClusteringDefinitions.cuh"

__device__ __host__ VeloRawEvent::VeloRawEvent(const char* event)
{
  const char* p = event;
  number_of_raw_banks = *((uint32_t*) p);
  p += sizeof(uint32_t);
  raw_bank_offset = (uint32_t*) p;
  p += (number_of_raw_banks + 1) * sizeof(uint32_t);
  payload = (char*) p;
}

__device__ __host__ VeloRawBank::VeloRawBank(const char* raw_bank)
{
  const char* p = raw_bank;
  sensor_index = *((uint32_t*) p);
  p += sizeof(uint32_t);
  sp_count = *((uint32_t*) p);
  p += sizeof(uint32_t);
  sp_word = (uint32_t*) p;
}

VeloGeometry::VeloGeometry(std::vector<char> const& geometry)
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

__device__ __host__ uint32_t get_channel_id(const uint sensor, const uint chip, const uint col, const uint row)
{
  return (sensor << LHCb::VPChannelID::sensorBits) | (chip << LHCb::VPChannelID::chipBits) |
         (col << LHCb::VPChannelID::colBits) | row;
}

__device__ __host__ int32_t get_lhcb_id(const int32_t cid) { return (LHCb::VPChannelID::VP << LHCb::detectorTypeBits) + cid; }

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
  std::cout << "read " << Velo::Constants::n_modules << " modules: " << std::endl;
  for ( int i = 0; i < Velo::Constants::n_modules; ++i ) {
    std::cout << " zs = " << module_zs[i] << std::endl;
  }
  copy_array(Velo::Constants::number_of_sensor_columns, local_x);
  std::cout << "read " << Velo::Constants::number_of_sensor_columns << " local_x: " << std::endl;
  for ( int i = 0; i < Velo::Constants::number_of_sensor_columns; ++i ) {
    std::cout << " local_x = " << local_x[i] << std::endl;
  }
  copy_array(Velo::Constants::number_of_sensor_columns, x_pitch);
  std::cout << "read " << Velo::Constants::number_of_sensor_columns << " x_pitch: " << std::endl;
  for ( int i = 0; i < Velo::Constants::number_of_sensor_columns; ++i ) {
    std::cout << " x_pitch = " << x_pitch[i] << std::endl;
  }

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

__device__ __host__ uint32_t get_channel_id(unsigned int sensor, unsigned int chip, unsigned int col, unsigned int row)
{
  return (sensor << Allen::VPChannelID::sensorBits) | (chip << Allen::VPChannelID::chipBits) |
         (col << Allen::VPChannelID::colBits) | row;
}

__device__ __host__ int32_t get_lhcb_id(int32_t cid) { return (Allen::VPChannelID::VP << Allen::detectorTypeBits) + cid; }

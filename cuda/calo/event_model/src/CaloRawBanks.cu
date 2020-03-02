#include <CaloRawBanks.cuh>

__device__ __host__ CaloRawBank::CaloRawBank() {
}

__device__ __host__ CaloRawBank::CaloRawBank(const char* raw_bank)
{
  const char* p = raw_bank;
  source_id = *((uint32_t*) p);
  p += sizeof(uint32_t);

  uint32_t trig_size = *((uint32_t*) p) & 0x7F;
  adc_size = ( *((uint32_t*) p) >> 7 ) & 0x7F;

  // Skipping header and trigger bits.
  data = (uint32_t*) (p + 4 + (trig_size + 3) / 4);
}

__device__ __host__ CaloRawBank::CaloRawBank(const uint32_t sid, const char* fragment)
{
  source_id = sid;

  uint32_t trig_size = *((uint32_t*) fragment) & 0x7F;
  adc_size = ( *((uint32_t*) fragment) >> 7 ) & 0x7F;

  // Skipping header and trigger bits.
  data = (uint32_t*) (fragment + 4 + (trig_size + 3) / 4);
}

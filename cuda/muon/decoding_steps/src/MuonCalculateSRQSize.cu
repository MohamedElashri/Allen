#include <MEPTools.h>
#include <MuonCalculateSRQSize.cuh>

__device__ void calculate_srq_size(
  Muon::MuonRawToHits const* muon_raw_to_hits,
  unsigned int const event_number,
  int const batch_index,
  Muon::MuonRawBank const& raw_bank,
  unsigned int* storage_station_region_quarter_sizes)
{

  const auto tell_number = raw_bank.sourceID;

  uint16_t* p = raw_bank.data;

  // Note: Review this logic
  p += (*p + 3) & 0xFFFE;
  for (int j = 0; j < batch_index; ++j) {
    p += 1 + *p;
  }

  const auto batch_size = *p;
  for (int j = 1; j < batch_size + 1; ++j) {
    const auto pp = *(p + j);
    const auto add = (pp & 0x0FFF);
    const auto tdc_value = ((pp & 0xF000) >> 12);
    const auto tileId = muon_raw_to_hits->muonGeometry->getADDInTell1(tell_number, add);

    if (tileId != 0) {
      const auto stationRegionQuarter = Muon::MuonTileID::stationRegionQuarter(tileId);
      atomicAdd(storage_station_region_quarter_sizes + stationRegionQuarter, 1);
    }
  }
}

__global__ void muon_calculate_srq_size::muon_calculate_srq_size(muon_calculate_srq_size::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const auto event_id = parameters.dev_event_list[blockIdx.x];
  const auto raw_event = Muon::MuonRawEvent(parameters.dev_muon_raw + parameters.dev_muon_raw_offsets[event_id]);
  uint* storage_station_region_quarter_sizes =
    parameters.dev_storage_station_region_quarter_sizes +
    event_number * Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;

  // number_of_raw_banks = 10
  // batches_per_bank = 4
  constexpr uint32_t batches_per_bank_mask = 0x3;
  constexpr uint32_t batches_per_bank_shift = 2;
  for (uint i = threadIdx.x; i < Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank;
       i += blockDim.x) {
    const auto bank_index = i >> batches_per_bank_shift;
    const auto batch_index = i & batches_per_bank_mask;
    const auto raw_bank = raw_event.getMuonBank(bank_index);

    calculate_srq_size(
      parameters.dev_muon_raw_to_hits,
      event_number,
      batch_index,
      raw_bank,
      storage_station_region_quarter_sizes);
  }
}

__global__ void muon_calculate_srq_size::muon_calculate_srq_size_mep(muon_calculate_srq_size::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const auto event_id = parameters.dev_event_list[blockIdx.x];
  uint* storage_station_region_quarter_sizes =
    parameters.dev_storage_station_region_quarter_sizes +
    event_number * Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;

  // number_of_raw_banks = 10
  // batches_per_bank = 4
  constexpr uint32_t batches_per_bank_mask = 0x3;
  constexpr uint32_t batches_per_bank_shift = 2;
  for (uint i = threadIdx.x; i < Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank;
       i += blockDim.x) {
    const auto bank_index = i >> batches_per_bank_shift;
    const auto batch_index = i & batches_per_bank_mask;
    const auto raw_bank =
      MEP::raw_bank<Muon::MuonRawBank>(parameters.dev_muon_raw, parameters.dev_muon_raw_offsets, event_id, bank_index);

    calculate_srq_size(
      parameters.dev_muon_raw_to_hits,
      event_number,
      batch_index,
      raw_bank,
      storage_station_region_quarter_sizes);
  }
}

#include <MEPTools.h>
#include <MuonPopulateTileAndTDC.cuh>

__device__ void decode_muon_bank(
  Muon::MuonRawToHits const* muon_raw_to_hits,
  int const batch_index,
  Muon::MuonRawBank const& raw_bank,
  const uint* storage_station_region_quarter_offsets,
  uint* atomics_muon,
  uint* dev_storage_tile_id,
  uint* dev_storage_tdc_value)
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
      const auto insert_index = atomicAdd(atomics_muon + stationRegionQuarter, 1);
      dev_storage_tile_id[storage_station_region_quarter_offsets[stationRegionQuarter] + insert_index] = tileId;
      dev_storage_tdc_value[storage_station_region_quarter_offsets[stationRegionQuarter] + insert_index] = tdc_value;
    }
  }
}

__global__ void muon_populate_tile_and_tdc::muon_populate_tile_and_tdc(muon_populate_tile_and_tdc::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const auto event_id = parameters.dev_event_list[blockIdx.x];
  const auto raw_event = Muon::MuonRawEvent(parameters.dev_muon_raw + parameters.dev_muon_raw_offsets[event_id]);
  const auto storage_station_region_quarter_offsets =
    parameters.dev_storage_station_region_quarter_offsets +
    event_number * Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;
  uint* atomics_muon = 
    parameters.dev_atomics_muon +
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

    decode_muon_bank(
      parameters.dev_muon_raw_to_hits,
      batch_index,
      raw_bank,
      storage_station_region_quarter_offsets,
      atomics_muon,
      parameters.dev_storage_tile_id,
      parameters.dev_storage_tdc_value);
  }
}

__global__ void muon_populate_tile_and_tdc::muon_populate_tile_and_tdc_mep(muon_populate_tile_and_tdc::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const auto event_id = parameters.dev_event_list[blockIdx.x];
  const auto storage_station_region_quarter_offsets =
    parameters.dev_storage_station_region_quarter_offsets +
    event_number * Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;
  uint* atomics_muon = 
    parameters.dev_atomics_muon +
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

    decode_muon_bank(
      parameters.dev_muon_raw_to_hits,
      batch_index,
      raw_bank,
      storage_station_region_quarter_offsets,
      atomics_muon,
      parameters.dev_storage_tile_id,
      parameters.dev_storage_tdc_value);
  }
}

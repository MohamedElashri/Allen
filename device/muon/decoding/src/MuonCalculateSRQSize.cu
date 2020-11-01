/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <MuonCalculateSRQSize.cuh>

void muon_calculate_srq_size::muon_calculate_srq_size_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_muon_raw_to_hits_t>(arguments, 1);
  set_size<dev_storage_station_region_quarter_sizes_t>(
    arguments,
    first<host_number_of_events_t>(arguments) * Muon::Constants::n_layouts * Muon::Constants::n_stations *
      Muon::Constants::n_regions * Muon::Constants::n_quarters);
}

void muon_calculate_srq_size::muon_calculate_srq_size_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& stream,
  cudaEvent_t&) const
{
  // FIXME: this should be done as part of the consumers, but
  // currently it cannot. This is because it is not possible to
  // indicate dependencies between Consumer and/or Producers.
  Muon::MuonRawToHits muonRawToHits {constants.dev_muon_tables, constants.dev_muon_geometry};

  cudaCheck(cudaMemcpyAsync(
    data<dev_muon_raw_to_hits_t>(arguments), &muonRawToHits, sizeof(muonRawToHits), cudaMemcpyHostToDevice, stream));

  initialize<dev_storage_station_region_quarter_sizes_t>(arguments, 0, stream);

  if (runtime_options.mep_layout) {
    global_function(muon_calculate_srq_size_mep)(
      size<dev_event_list_t>(arguments),
      Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank,
      stream)(arguments);
  }
  else {
    global_function(muon_calculate_srq_size)(
      size<dev_event_list_t>(arguments),
      Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank,
      stream)(arguments);
  }
}

__device__ void calculate_srq_size(
  Muon::MuonRawToHits const* muon_raw_to_hits,
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
    const auto tileId = muon_raw_to_hits->muonGeometry->getADDInTell1(tell_number, add);

    if (tileId != 0) {
      const auto tile = Muon::MuonTileID(tileId);

      const auto x1 =
        getLayoutX(muon_raw_to_hits->muonTables, Muon::MuonTables::stripXTableNumber, tile.station(), tile.region());
      const auto y1 =
        getLayoutY(muon_raw_to_hits->muonTables, Muon::MuonTables::stripXTableNumber, tile.station(), tile.region());
      const auto x2 =
        getLayoutX(muon_raw_to_hits->muonTables, Muon::MuonTables::stripYTableNumber, tile.station(), tile.region());
      const auto y2 =
        getLayoutY(muon_raw_to_hits->muonTables, Muon::MuonTables::stripYTableNumber, tile.station(), tile.region());
      const auto layout1 = (x1 > x2 ? Muon::MuonLayout {x1, y1} : Muon::MuonLayout {x2, y2});

      // Store tiles according to their station, region, quarter and layout,
      // to prepare data for easy process in muonaddcoordscrossingmaps.
      const auto storage_srq_layout =
        Muon::Constants::n_layouts * tile.stationRegionQuarter() + (tile.layout() != layout1);
      atomicAdd(storage_station_region_quarter_sizes + storage_srq_layout, 1);
    }
  }
}

__global__ void muon_calculate_srq_size::muon_calculate_srq_size(muon_calculate_srq_size::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const auto raw_event = Muon::MuonRawEvent(parameters.dev_muon_raw + parameters.dev_muon_raw_offsets[event_number]);
  unsigned* storage_station_region_quarter_sizes =
    parameters.dev_storage_station_region_quarter_sizes + event_number * Muon::Constants::n_layouts *
                                                            Muon::Constants::n_stations * Muon::Constants::n_regions *
                                                            Muon::Constants::n_quarters;

  // number_of_raw_banks = 10
  // batches_per_bank = 4
  constexpr uint32_t batches_per_bank_mask = 0x3;
  constexpr uint32_t batches_per_bank_shift = 2;
  for (unsigned i = threadIdx.x; i < Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank;
       i += blockDim.x) {
    const auto bank_index = i >> batches_per_bank_shift;
    const auto batch_index = i & batches_per_bank_mask;
    const auto raw_bank = raw_event.getMuonBank(bank_index);

    calculate_srq_size(parameters.dev_muon_raw_to_hits, batch_index, raw_bank, storage_station_region_quarter_sizes);
  }
}

__global__ void muon_calculate_srq_size::muon_calculate_srq_size_mep(muon_calculate_srq_size::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  unsigned* storage_station_region_quarter_sizes =
    parameters.dev_storage_station_region_quarter_sizes + event_number * Muon::Constants::n_layouts *
                                                            Muon::Constants::n_stations * Muon::Constants::n_regions *
                                                            Muon::Constants::n_quarters;

  // number_of_raw_banks = 10
  // batches_per_bank = 4
  constexpr uint32_t batches_per_bank_mask = 0x3;
  constexpr uint32_t batches_per_bank_shift = 2;
  for (unsigned i = threadIdx.x; i < Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank;
       i += blockDim.x) {
    const auto bank_index = i >> batches_per_bank_shift;
    const auto batch_index = i & batches_per_bank_mask;
    const auto raw_bank = MEP::raw_bank<Muon::MuonRawBank>(
      parameters.dev_muon_raw, parameters.dev_muon_raw_offsets, event_number, bank_index);

    calculate_srq_size(parameters.dev_muon_raw_to_hits, batch_index, raw_bank, storage_station_region_quarter_sizes);
  }
}

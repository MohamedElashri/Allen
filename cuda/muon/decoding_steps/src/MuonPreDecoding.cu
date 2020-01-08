#include "MuonPreDecoding.cuh"

void muon_pre_decoding_t::set_arguments_size(
  ArgumentRefManager<T> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  set_size<dev_muon_raw_t>(arguments, std::get<0>(runtime_options.host_muon_events).size_bytes());
  set_size<dev_muon_raw_offsets_t>(arguments, std::get<1>(runtime_options.host_muon_events).size_bytes());
  set_size<dev_muon_raw_to_hits_t>(arguments, 1);
  set_size<dev_storage_station_region_quarter_offsets_t>(arguments, 
    value<host_number_of_selected_events_t>(arguments) * Muon::Constants::n_stations * Muon::Constants::n_regions *
      Muon::Constants::n_quarters +
    1);
  set_size<dev_storage_tile_id_t>(arguments, 
    value<host_number_of_selected_events_t>(arguments) * Muon::Constants::max_numhits_per_event);
  set_size<dev_storage_tdc_value_t>(arguments, 
    value<host_number_of_selected_events_t>(arguments) * Muon::Constants::max_numhits_per_event);
  set_size<dev_atomics_muon_t>(arguments, 2 * value<host_number_of_selected_events_t>(arguments));
}

void muon_pre_decoding_t::operator()(
  const ArgumentRefManager<T>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  // FIXME: this should be done as part of the consumers, but
  // currently it cannot. This is because it is not possible to
  // indicate dependencies between Consumer and/or Producers.
  Muon::MuonRawToHits muonRawToHits {constants.dev_muon_tables, constants.dev_muon_geometry};

  cudaCheck(cudaMemcpyAsync(
    offset<dev_muon_raw_to_hits_t>(arguments),
    &muonRawToHits,
    sizeof(muonRawToHits),
    cudaMemcpyHostToDevice,
    cuda_stream));

  cudaCheck(cudaMemcpyAsync(
    offset<dev_muon_raw_t>(arguments),
    std::get<0>(runtime_options.host_muon_events).begin(),
    std::get<0>(runtime_options.host_muon_events).size_bytes(),
    cudaMemcpyHostToDevice,
    cuda_stream));

  cudaCheck(cudaMemcpyAsync(
    offset<dev_muon_raw_offsets_t>(arguments),
    std::get<1>(runtime_options.host_muon_events).begin(),
    std::get<1>(runtime_options.host_muon_events).size_bytes(),
    cudaMemcpyHostToDevice,
    cuda_stream));

  cudaCheck(cudaMemsetAsync(
    offset<dev_storage_station_region_quarter_offsets_t>(arguments),
    0,
    size<dev_storage_station_region_quarter_offsets_t>(arguments),
    cuda_stream));

  cudaCheck(cudaMemsetAsync(offset<dev_atomics_muon_t>(arguments), 0, size<dev_atomics_muon_t>(arguments), cuda_stream));

  function(
    value<host_number_of_selected_events_t>(arguments),
    Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank,
    cuda_stream)(
    offset<dev_event_list_t>(arguments),
    offset<dev_muon_raw_t>(arguments),
    offset<dev_muon_raw_offsets_t>(arguments),
    offset<dev_muon_raw_to_hits_t>(arguments),
    offset<dev_storage_station_region_quarter_offsets_t>(arguments),
    offset<dev_storage_tile_id_t>(arguments),
    offset<dev_storage_tdc_value_t>(arguments),
    offset<dev_atomics_muon_t>(arguments));
}

__global__ void muon_pre_decoding(
  const uint* event_list,
  const char* events,
  const unsigned int* offsets,
  const Muon::MuonRawToHits* muon_raw_to_hits,
  uint* dev_storage_station_region_quarter_offsets,
  uint* dev_storage_tile_id,
  uint* dev_storage_tdc_value,
  uint* dev_atomics_muon)
{
  const auto event_number = blockIdx.x;
  const auto event_id = event_list[blockIdx.x];
  const auto raw_event = Muon::MuonRawEvent(events + offsets[event_id]);
  uint* storage_station_region_quarter_offsets =
    dev_storage_station_region_quarter_offsets +
    event_number * Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;
  auto storage_tile_id = dev_storage_tile_id + event_number * Muon::Constants::max_numhits_per_event;
  auto storage_tdc_value = dev_storage_tdc_value + event_number * Muon::Constants::max_numhits_per_event;

  // number_of_raw_banks = 10
  // batches_per_bank = 4
  constexpr uint32_t batches_per_bank_mask = 0x3;
  constexpr uint32_t batches_per_bank_shift = 2;
  for (uint i = threadIdx.x; i < Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank;
       i += blockDim.x) {
    const auto bank_index = i >> batches_per_bank_shift;
    const auto batch_index = i & batches_per_bank_mask;

    const auto raw_bank = raw_event.getMuonBank(bank_index);
    const auto tell_number = raw_bank.sourceID;

    uint16_t* p = raw_bank.data;

    // Note: Review this logic
    p += (*p + 3) & 0xFFFE;
    for (uint j = 0; j < batch_index; ++j) {
      p += 1 + *p;
    }

    const auto batch_size = *p;
    for (int j = 1; j < batch_size + 1; ++j) {
      const auto pp = *(p + j);
      const auto add = (pp & 0x0FFF);
      const auto tdc_value = ((pp & 0xF000) >> 12);
      const auto tileId = muon_raw_to_hits->muonGeometry->getADDInTell1(tell_number, add);

      if (tileId != 0) {
        const auto insert_index = atomicAdd(dev_atomics_muon + event_number, 1);
        storage_tile_id[insert_index] = tileId;
        storage_tdc_value[insert_index] = tdc_value;

        // Also add to storageStationRegionQuarterOccurrencesOffset
        const auto stationRegionQuarter = Muon::MuonTileID::stationRegionQuarter(tileId);
        atomicAdd(storage_station_region_quarter_offsets + stationRegionQuarter, 1);
      }
    }
  }
}

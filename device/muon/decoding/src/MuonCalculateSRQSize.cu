/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <MuonCalculateSRQSize.cuh>
#include <gsl/gsl>
#include "MuonDefinitions.cuh"
#include <BankTypes.h>

INSTANTIATE_ALGORITHM(muon_calculate_srq_size::muon_calculate_srq_size_t)

__device__ void calculate_srq_size_tell1(
  Muon::MuonRawToHits const* muon_raw_to_hits,
  int const batch_index,
  Muon::MuonRawBank<2> const& raw_bank,
  unsigned int* storage_station_region_quarter_sizes)
{
  const auto tell_number = raw_bank.sourceID;
  const uint16_t* p = raw_bank.data;

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
      const auto layout1 = getLayout(muon_raw_to_hits->muonTables, tile)[0];

      const auto storage_srq_layout =
        Muon::Constants::n_layouts * tile.stationRegionQuarter() + (tile.layout() != layout1);
      atomicAdd(storage_station_region_quarter_sizes + storage_srq_layout, 1);
    }
  }
}

__device__ void calculate_srq_size_tell40(
  Muon::MuonRawToHits const* muon_raw_to_hits,
  int const batch_index,
  Muon::MuonRawBank<3> const& raw_bank,
  unsigned int* storage_station_region_quarter_sizes)
{

  const auto* p = raw_bank.data;

  // for (int j = 0; j < batch_index; ++j) {
  //   p += 1 + *p;
  // }
  // const auto batch_size = *p;
  // for (int j = 1; j < batch_size + 1; ++j) {

  const auto tell_pci = raw_bank.sourceID & 0x00FF;
  const auto tell_number = tell_pci / 2 + 1;
  const auto pci_number = tell_pci % 2;
  const auto tell_station = muon_raw_to_hits->muonGeometry->whichStationIsTell40(tell_number - 1);
  const auto active_links = muon_raw_to_hits->muonGeometry->NumberOfActiveLink(tell_number, pci_number);

  // printf("SRQSize: sourceID = %u, raw_bank.last - raw_bank.data = %ld, tell_station = %u, active_links = %u \n",
  // raw_bank.sourceID,  raw_bank.last - raw_bank.data, tell_station, active_links);

  const gsl::span<const uint8_t> range8 {raw_bank.data, (raw_bank.last - raw_bank.data) / sizeof(uint8_t)};
  auto range_data = range8.subspan(1);
  unsigned int link_start_pointer = (range8[0] & 0x20) >> 5 ? 3 : 0;
  unsigned int map_connected_fibers[24] = {};
  unsigned int synch_evt = (*p & 0x10) >> 4;
  if (!synch_evt) {
    unsigned int number_of_readout_fibers =
      muon_raw_to_hits->muonGeometry->get_number_of_readout_fibers(range8, active_links, map_connected_fibers);
    // printf( "Number of readout fibers is %d \n", number_of_readout_fibers );

    for (unsigned int link = 0; link < number_of_readout_fibers; link++) {
      unsigned int reroutered_link = map_connected_fibers[link];

      auto regionOfLink = muon_raw_to_hits->muonGeometry->RegionOfLink(tell_number, pci_number, reroutered_link);
      auto quarterOfLink = muon_raw_to_hits->muonGeometry->QuarterOfLink(tell_number, pci_number, reroutered_link);
      // printf("at link %u, reroutered link %u, tell_number %u, pci_number %u, regionOfLink = %u, quarterOfLink = %u
      // \n", link, reroutered_link, tell_number, pci_number, regionOfLink, quarterOfLink);

      uint8_t curr_byte = range_data[link_start_pointer];
      unsigned int size_of_link = ((curr_byte & 0xF0) >> 4) + 1;

      // printf("size of link is %u, link_start_pointer is %u\n", size_of_link, link_start_pointer);

      if (size_of_link > 1) {
        auto range_link_HitsMap = range_data.subspan(link_start_pointer, 7);

        bool first_hitmap_byte = false;
        bool last_hitmap_byte = true;
        unsigned int count_byte = 0;
        unsigned int pos_in_link = 0;

        for (auto r = range_link_HitsMap.rbegin(); r < range_link_HitsMap.rend(); r++) {
          // loop in reverse mode hits map is 47->0
          count_byte++;
          if (count_byte == 7) first_hitmap_byte = true;
          if (count_byte > 7) break;

          uint8_t data_copy = *r;
          for (unsigned int bit_pos_1 = 8; bit_pos_1 > 0; --bit_pos_1) {
            unsigned int bit_pos = bit_pos_1 - 1;

            if (first_hitmap_byte && bit_pos < 4) continue;
            if (last_hitmap_byte && bit_pos > 3) continue;

            if (data_copy & Muon::Constants::single_bit_position[bit_pos]) {
              auto tileId =
                muon_raw_to_hits->muonGeometry->TileInTell40(tell_number, pci_number, reroutered_link, pos_in_link);

              if (tileId != 0) {
                const auto tile = Muon::MuonTileID(tileId);
                const auto layout1 = getLayout(muon_raw_to_hits->muonTables, tile)[0];

                if (tell_station * 16 + regionOfLink * 4 + quarterOfLink < 64) {
                  const auto storage_srq_layout =
                    Muon::Constants::n_layouts * tile.stationRegionQuarter() + (tile.layout() != layout1);
                  atomicAdd(storage_station_region_quarter_sizes + storage_srq_layout, 1);
                }
              }
            }
            pos_in_link++;
          }
          last_hitmap_byte = false;
        }
      }
      link_start_pointer = link_start_pointer + size_of_link;
    }
  }
}
// printf( "THIS IS THE END OF THE CALCULATESRQ SIZE \n" );
//}

template<bool mep_layout>
__global__ void muon_calculate_srq_size_kernel(
  muon_calculate_srq_size::Parameters parameters,
  unsigned int muon_bank_version,
  unsigned int number_of_events)
{
  // const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  // printf("Number of events = %u \n", number_of_events);

  for (unsigned event_index = 0; event_index < number_of_events; ++event_index) {
    const unsigned event_number = parameters.dev_event_list[event_index];
    // printf("at index %u, event_number = %u \n", event_index, event_number);

    // number_of_raw_banks = 10
    // batches_per_bank = 4
    unsigned* storage_station_region_quarter_sizes =
      parameters.dev_storage_station_region_quarter_sizes + event_number * Muon::Constants::n_layouts *
                                                              Muon::Constants::n_stations * Muon::Constants::n_regions *
                                                              Muon::Constants::n_quarters;

    constexpr uint32_t batches_per_bank_mask = 0x3;
    constexpr uint32_t batches_per_bank_shift = 2;

    if (muon_bank_version == 2) {
      const auto raw_event = Muon::RawEvent<mep_layout, 2> {parameters.dev_muon_raw,
                                                            parameters.dev_muon_raw_offsets,
                                                            parameters.dev_muon_raw_sizes,
                                                            parameters.dev_muon_raw_types,
                                                            event_number};

      for (unsigned i = threadIdx.x; i < raw_event.number_of_raw_banks() * Muon::batches_per_bank; i += blockDim.x) {
        const auto bank_index = i >> batches_per_bank_shift;
        const auto batch_index = i & batches_per_bank_mask;
        const auto raw_bank = raw_event.raw_bank(bank_index);
        calculate_srq_size_tell1(
          parameters.dev_muon_raw_to_hits, batch_index, raw_bank, storage_station_region_quarter_sizes);
      }
    }
    else if (muon_bank_version == 3) {
      const auto raw_event = Muon::RawEvent<mep_layout, 3> {parameters.dev_muon_raw,
                                                            parameters.dev_muon_raw_offsets,
                                                            parameters.dev_muon_raw_sizes,
                                                            parameters.dev_muon_raw_types,
                                                            event_number};

      // for (unsigned i = threadIdx.x; i < raw_event.number_of_raw_banks() * Muon::batches_per_bank; i += blockDim.x) {
      for (unsigned i = 0; i < raw_event.number_of_raw_banks(); i += blockDim.x) {
        const int bank_index = i;
        const int batch_index = 0;

        // const auto bank_index = i >> batches_per_bank_shift;
        // const auto batch_index = i & batches_per_bank_mask;
        const auto raw_bank = raw_event.raw_bank(bank_index);

        if (raw_bank.type != LHCb::RawBank::BankType::Muon) continue; // skip invalid raw banks
        // printf("I will enter in the new calculatingSRQsize part for event %u, bank_index %u, batch_index %u \n ",
        // event_number, bank_index, batch_index);

        calculate_srq_size_tell40(
          parameters.dev_muon_raw_to_hits, batch_index, raw_bank, storage_station_region_quarter_sizes);
      }
    }
    else {
      throw StrException("MuonCalculateSRQSize : unrecognized muon raw bank version \n");
    }
  }
}

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
  const Allen::Context& context) const
{
  // FIXME: this should be done as part of the consumers, but
  // currently it cannot. This is because it is not possible to
  // indicate dependencies between Consumer and/or Producers.
  Muon::MuonRawToHits muonRawToHits {constants.dev_muon_tables, constants.dev_muon_geometry};

  Allen::memcpy_async(
    data<dev_muon_raw_to_hits_t>(arguments), &muonRawToHits, sizeof(muonRawToHits), Allen::memcpyHostToDevice, context);

  Allen::memset_async<dev_storage_station_region_quarter_sizes_t>(arguments, 0, context);
  const unsigned int muon_bank_version = first<host_raw_bank_version_t>(arguments);

  global_function(
    runtime_options.mep_layout ? muon_calculate_srq_size_kernel<true> : muon_calculate_srq_size_kernel<false>)(
    1, // size<dev_event_list_t>(arguments),
    // FIXME
    1, // 10 * Muon::batches_per_bank,
    context)(arguments, muon_bank_version, size<dev_event_list_t>(arguments));

  // global_function( runtime_options.mep_layout ? muon_calculate_srq_size_kernel<true> :
  // 		   muon_calculate_srq_size_kernel<false>)(
  // 							  size<dev_event_list_t>(arguments),     //1
  // 							  10 * Muon::batches_per_bank, //1
  // 							  context)(arguments, muon_bank_version);
}

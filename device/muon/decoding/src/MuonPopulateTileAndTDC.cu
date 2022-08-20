/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <MuonPopulateTileAndTDC.cuh>
#include <BankTypes.h>

INSTANTIATE_ALGORITHM(muon_populate_tile_and_tdc::muon_populate_tile_and_tdc_t)

template<int decoding_version>
__device__ void decode_muon_bank(
  Muon::MuonRawToHits const* muon_raw_to_hits,
  Muon::MuonRawBank<decoding_version> const& raw_bank,
  const unsigned* storage_station_region_quarter_offsets,
  unsigned* atomics_muon,
  unsigned* dev_storage_tile_id,
  unsigned* dev_storage_tdc_value)
{
  if constexpr (decoding_version == 2) {
    for (unsigned batch_index = threadIdx.y; batch_index < Muon::batches_per_bank; batch_index += blockDim.y) {
      const auto tell_number = raw_bank.sourceID;
      const uint16_t* p = raw_bank.data;

      p += (*p + 3) & 0xFFFE;
      for (unsigned j = 0; j < batch_index; ++j) {
        p += 1 + *p;
      }

      const auto batch_size = *p;
      for (int j = 1; j < batch_size + 1; ++j) {
        const auto pp = *(p + j);
        const auto add = (pp & 0x0FFF);
        const auto tdc_value = ((pp & 0xF000) >> 12);
        const auto tileId = muon_raw_to_hits->muonGeometry->getADDInTell1(tell_number, add);

        if (tileId != 0) {
          const auto tile = Muon::MuonTileID(tileId);
          const auto layout1 = getLayout(muon_raw_to_hits->muonTables, tile)[0];

          // Store tiles according to their station, region, quarter and layout,
          // to prepare data for easy process in muonaddcoordscrossingmaps.
          const auto storage_srq_layout =
            Muon::Constants::n_layouts * tile.stationRegionQuarter() + (tile.layout() != layout1);

          const auto insert_index = atomicAdd(atomics_muon + storage_srq_layout, 1);
          dev_storage_tile_id[storage_station_region_quarter_offsets[storage_srq_layout] + insert_index] = tileId;
          dev_storage_tdc_value[storage_station_region_quarter_offsets[storage_srq_layout] + insert_index] = tdc_value;
        }
      }
    }
  }
  else {
    const auto tell_pci = raw_bank.sourceID & 0x00FF;
    const auto tell_number = tell_pci / 2 + 1;
    const auto pci_number = tell_pci % 2;
    const auto tell_station = muon_raw_to_hits->muonGeometry->whichStationIsTell40(tell_number - 1);
    const auto active_links = muon_raw_to_hits->muonGeometry->NumberOfActiveLink(tell_number, pci_number);

    const Allen::device::span<const uint8_t> range8 {raw_bank.data, (raw_bank.last - raw_bank.data) / sizeof(uint8_t)};
    auto range_data = range8.subspan(1);
    unsigned link_start_pointer = (range8[0] & 0x20) >> 5 ? 3 : 0;
    unsigned map_connected_fibers[24] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    unsigned synch_evt = (range8[0] & 0x10) >> 4;
    if (!synch_evt) {
      unsigned number_of_readout_fibers =
        muon_raw_to_hits->muonGeometry->get_number_of_readout_fibers(range8, active_links, map_connected_fibers);

      for (unsigned link = threadIdx.y; link < number_of_readout_fibers; link += blockDim.y) {
        unsigned reroutered_link = map_connected_fibers[link];

        auto regionOfLink = muon_raw_to_hits->muonGeometry->RegionOfLink(tell_number, pci_number, reroutered_link);
        auto quarterOfLink = muon_raw_to_hits->muonGeometry->QuarterOfLink(tell_number, pci_number, reroutered_link);

        unsigned current_pointer = link_start_pointer;
        auto size_of_link = (static_cast<unsigned>(range_data[current_pointer]) >> 4) + 1;
        for (unsigned j = 0; j < link; ++j) {
          current_pointer += size_of_link;
          size_of_link = (static_cast<unsigned>(range_data[current_pointer]) >> 4) + 1;
        }

        if (size_of_link > 1) {
          auto range_link_HitsMap = range_data.subspan(current_pointer, 7);
          auto range_link_TDC = range_data.subspan(current_pointer + 6, size_of_link - 6);

          bool first_hitmap_byte = false;
          bool last_hitmap_byte = true;
          unsigned count_byte = 0;
          unsigned pos_in_link = 0;
          unsigned nSynch_hits_number = 0;
          unsigned TDC_counter = range_link_TDC.size() * 2 - 1;

          for (auto r = range_link_HitsMap.rbegin(); r < range_link_HitsMap.rend(); r++) {
            // loop in reverse mode hits map is 47->0
            count_byte++;
            if (count_byte == 7) first_hitmap_byte = true;
            if (count_byte > 7) break;
            for (unsigned bit_pos_1 = 8; bit_pos_1 > 0; --bit_pos_1) {
              unsigned bit_pos = bit_pos_1 - 1;

              if (first_hitmap_byte && bit_pos < 4) continue;
              if (last_hitmap_byte && bit_pos > 3) continue;
              if (*r & Muon::Constants::single_bit_position()[bit_pos]) {
                auto tileId =
                  muon_raw_to_hits->muonGeometry->TileInTell40(tell_number, pci_number, reroutered_link, pos_in_link);

                if (tileId != 0) {
                  const auto tile = Muon::MuonTileID(tileId);
                  const auto layout1 = getLayout(muon_raw_to_hits->muonTables, tile)[0];

                  unsigned tdc_value = 0;
                  if (nSynch_hits_number < TDC_counter) {
                    if (nSynch_hits_number == 0)
                      tdc_value = range_link_TDC[0] & 0x0F;
                    else {
                      auto mask = nSynch_hits_number % 2 == 0 ? 0x0F : 0xF0;
                      auto shift = nSynch_hits_number % 2 == 0 ? 0 : 4;
                      tdc_value = range_link_TDC[1 + (nSynch_hits_number - 1) / 2] & mask >> shift;
                    }
                  }

                  nSynch_hits_number++;

                  // Store tiles according to their station, region, quarter and layout,
                  // to prepare data for easy process in muonaddcoordscrossingmaps.
                  if (tell_station * 16 + regionOfLink * 4 + quarterOfLink < 64) {
                    const auto storage_srq_layout =
                      Muon::Constants::n_layouts * tile.stationRegionQuarter() + (tile.layout() != layout1);
                    const auto insert_index = atomicAdd(atomics_muon + storage_srq_layout, 1);
                    dev_storage_tile_id[storage_station_region_quarter_offsets[storage_srq_layout] + insert_index] =
                      tileId;
                    dev_storage_tdc_value[storage_station_region_quarter_offsets[storage_srq_layout] + insert_index] =
                      tdc_value;
                  }
                }
              }
              pos_in_link++;
            }
            last_hitmap_byte = false;
          }
        }
      }
    }
  }
}

template<int decoding_version, bool mep_layout>
__global__ void muon_populate_tile_and_tdc_kernel(muon_populate_tile_and_tdc::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const auto storage_station_region_quarter_offsets =
    parameters.dev_storage_station_region_quarter_offsets +
    event_number * 2 * Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;
  unsigned* atomics_muon = parameters.dev_atomics_muon + event_number * 2 * Muon::Constants::n_stations *
                                                           Muon::Constants::n_regions * Muon::Constants::n_quarters;

  const auto raw_event = Muon::RawEvent<mep_layout, decoding_version> {parameters.dev_muon_raw,
                                                                       parameters.dev_muon_raw_offsets,
                                                                       parameters.dev_muon_raw_sizes,
                                                                       parameters.dev_muon_raw_types,
                                                                       event_number};

  for (unsigned bank_index = threadIdx.x; bank_index < raw_event.number_of_raw_banks(); bank_index += blockDim.x) {
    const auto raw_bank = raw_event.raw_bank(bank_index);

    if (raw_bank.type != LHCb::RawBank::BankType::Muon) continue; // skip invalid raw banks

    decode_muon_bank<decoding_version>(
      parameters.dev_muon_raw_to_hits,
      raw_bank,
      storage_station_region_quarter_offsets,
      atomics_muon,
      parameters.dev_storage_tile_id,
      parameters.dev_storage_tdc_value);
  }
}

void muon_populate_tile_and_tdc::muon_populate_tile_and_tdc_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_storage_tile_id_t>(arguments, first<host_muon_total_number_of_tiles_t>(arguments));
  set_size<dev_storage_tdc_value_t>(arguments, first<host_muon_total_number_of_tiles_t>(arguments));
  set_size<dev_atomics_muon_t>(
    arguments,
    first<host_number_of_events_t>(arguments) * 2 * Muon::Constants::n_stations * Muon::Constants::n_regions *
      Muon::Constants::n_quarters);
}

void muon_populate_tile_and_tdc::muon_populate_tile_and_tdc_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_atomics_muon_t>(arguments, 0, context);
  Allen::memset_async<dev_storage_tile_id_t>(arguments, 0, context);
  Allen::memset_async<dev_storage_tdc_value_t>(arguments, 0, context);

  const auto bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) return; // no Muon banks present in data
  auto kernel_fn = bank_version == 2 ? (runtime_options.mep_layout ? muon_populate_tile_and_tdc_kernel<2, true> :
                                                                     muon_populate_tile_and_tdc_kernel<2, false>) :
                                       (runtime_options.mep_layout ? muon_populate_tile_and_tdc_kernel<3, true> :
                                                                     muon_populate_tile_and_tdc_kernel<3, false>);

  global_function(kernel_fn)(size<dev_event_list_t>(arguments), dim3(64, 4), context)(arguments);
}

/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <MuonCalculateSRQSize.cuh>
#include <gsl/gsl>
#include "MuonDefinitions.cuh"
#include <BankTypes.h>

INSTANTIATE_ALGORITHM(muon_calculate_srq_size::muon_calculate_srq_size_t)

template<int decoding_version>
__device__ void calculate_srq_size(
  Muon::MuonRawToHits const* muon_raw_to_hits,
  Muon::MuonRawBank<decoding_version> const& raw_bank,
  unsigned* storage_station_region_quarter_sizes)
{

  if constexpr (decoding_version == 2) {
    for (unsigned batch_index = threadIdx.y; batch_index < Muon::batches_per_bank; batch_index += blockDim.y) {
      const auto tell_number = raw_bank.sourceID;
      const uint16_t* p = raw_bank.data;

      // Note: Review this logic
      p += (*p + 3) & 0xFFFE;
      for (unsigned j = 0; j < batch_index; ++j) {
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
  }
  else { // decoding_version == 3
    const auto* p = raw_bank.data;

    const auto tell_pci = raw_bank.sourceID & 0x00FF;
    const auto tell_number = tell_pci / 2 + 1;
    const auto pci_number = tell_pci % 2;
    const auto tell_station = muon_raw_to_hits->muonGeometry->whichStationIsTell40(tell_number - 1);
    const auto active_links = muon_raw_to_hits->muonGeometry->NumberOfActiveLink(tell_number, pci_number);

    const Allen::device::span<const uint8_t> range8 {raw_bank.data, (raw_bank.last - raw_bank.data) / sizeof(uint8_t)};
    const auto range_data = range8.subspan(1);
    const unsigned link_start_pointer = ((range8[0] & 0x20) >> 5) ? 3 : 0;
    unsigned map_connected_fibers[24] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    unsigned synch_evt = (*p & 0x10) >> 4;
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

          bool first_hitmap_byte = false;
          bool last_hitmap_byte = true;
          unsigned count_byte = 0;
          unsigned pos_in_link = 0;

          for (auto r = range_link_HitsMap.rbegin(); r < range_link_HitsMap.rend(); r++) {
            // loop in reverse mode hits map is 47->0
            count_byte++;
            if (count_byte == 7) first_hitmap_byte = true;
            if (count_byte > 7) break;

            uint8_t data_copy = *r;
            for (unsigned bit_pos_1 = 8; bit_pos_1 > 0; --bit_pos_1) {
              unsigned bit_pos = bit_pos_1 - 1;

              if (first_hitmap_byte && bit_pos < 4) continue;
              if (last_hitmap_byte && bit_pos > 3) continue;

              if (data_copy & Muon::Constants::single_bit_position()[bit_pos]) {
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
      }
    }
  }
}

template<int decoding_version, bool mep_layout>
__global__ void muon_calculate_srq_size_kernel(
  muon_calculate_srq_size::Parameters parameters,
  unsigned const event_start)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  unsigned* storage_station_region_quarter_sizes =
    parameters.dev_storage_station_region_quarter_sizes + event_number * Muon::Constants::n_layouts *
                                                            Muon::Constants::n_stations * Muon::Constants::n_regions *
                                                            Muon::Constants::n_quarters;

  const auto raw_event = Muon::RawEvent<mep_layout, decoding_version> {parameters.dev_muon_raw,
                                                                       parameters.dev_muon_raw_offsets,
                                                                       parameters.dev_muon_raw_sizes,
                                                                       parameters.dev_muon_raw_types,
                                                                       event_number + event_start};

  for (unsigned bank_index = threadIdx.x; bank_index < raw_event.number_of_raw_banks(); bank_index += blockDim.x) {
    const auto raw_bank = raw_event.raw_bank(bank_index);

    if (raw_bank.type != LHCb::RawBank::BankType::Muon) continue; // skip invalid raw banks

    calculate_srq_size<decoding_version>(
      parameters.dev_muon_raw_to_hits, raw_bank, storage_station_region_quarter_sizes);
  }
}

void muon_calculate_srq_size::muon_calculate_srq_size_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  // Ensure the bank version is supported
  const auto bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) return; // no Muon banks present in data
  if (bank_version != 2 && bank_version != 3) {
    throw StrException("Muon bank version not supported (" + std::to_string(bank_version) + ")");
  }

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
  const auto bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) return; // no Muon banks present in data

  // FIXME: this should be done as part of the consumers, but
  // currently it cannot. This is because it is not possible to
  // indicate dependencies between Consumer and/or Producers.
  auto host_muonrawtohits = make_host_buffer<Muon::MuonRawToHits>(arguments, 1);
  host_muonrawtohits[0] = Muon::MuonRawToHits {constants.dev_muon_tables, constants.dev_muon_geometry};

  Allen::copy_async(
    get<dev_muon_raw_to_hits_t>(arguments), host_muonrawtohits.get(), context, Allen::memcpyHostToDevice);
  Allen::memset_async<dev_storage_station_region_quarter_sizes_t>(arguments, 0, context);

  auto kernel_fn = bank_version == 2 ? (runtime_options.mep_layout ? muon_calculate_srq_size_kernel<2, true> :
                                                                     muon_calculate_srq_size_kernel<2, false>) :
                                       (runtime_options.mep_layout ? muon_calculate_srq_size_kernel<3, true> :
                                                                     muon_calculate_srq_size_kernel<3, false>);

  global_function(kernel_fn)(size<dev_event_list_t>(arguments), dim3(64, 4), context)(
    arguments, std::get<0>(runtime_options.event_interval));
}

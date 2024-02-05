/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <RichDecoding.cuh>
#include <HostPrefixSum.h>
#include <RichTel40CableMapping.cuh>
#include <RichPDMDBDecodeMapping.cuh>
#include <MEPTools.h>

INSTANTIATE_ALGORITHM(rich_decoding::rich_decoding_t)

__device__ unsigned rich_calculate_number_of_hits_in_raw_bank(
  const Allen::RawBank& bank,
  const Rich::Future::DAQ::Allen::Tel40CableMapping* cable_mapping,
  const Rich::Future::DAQ::Allen::PDMDBDecodeMapping* pdmdb_mapping)
{
  unsigned number_of_hits = 0;
  std::array<
    Rich::Future::DAQ::PackedFrameSizes::IntType,
    Rich::Future::DAQ::Allen::Tel40CableMapping::MaxConnectionsPerTel40>
    connSizes {};

  auto tel40ID = bank.source_id;
  const auto& connMeta = cable_mapping->tel40Meta(tel40ID);
  const auto nSizeWords = connMeta.nActiveLinks;
  const auto nPackedSizeW = (nSizeWords / 2) + (nSizeWords % 2);

  auto dataW = bank.data;
  auto bankEnd = bank.data + bank.size;
  auto iPayloadWord = 0u;
  auto iWord = 0u;

  for (; iWord < nPackedSizeW && dataW != bankEnd; ++dataW, ++iWord, iPayloadWord += 2) {
    // Extract the sizes from the packed word
    const Rich::Future::DAQ::PackedFrameSizes sizes(*dataW);
    // extract sizes for each packed value
    connSizes[iPayloadWord] = sizes.size1();
    connSizes[iPayloadWord + 1] = sizes.size0();
  }

  const auto& connData = cable_mapping->tel40Data(tel40ID);
  if (connMeta.hasInactiveLinks) {
    for (unsigned iL = 0; iL < connData.size(); ++iL) {
      if (!connData[iL].isActive) {
        for (auto i = connData.size() - 1; i > iL; --i) {
          connSizes[i] = connSizes[i - 1];
        }
        connSizes[iL] = 0;
      }
    }
  }

  // finally loop over payload words and decode hits
  // note iterator starts from where the above header loop ended...
  unsigned iLink {0};
  while (dataW != bankEnd && iLink < connSizes.size()) {
    // Do we have any words to decode for this link
    if (connSizes[iLink] > 0) {
      // Get the Tel40 Data for this connection
      const auto& cData = connData[iLink];

      // get the PDMDB data
      const auto& frameData = pdmdb_mapping->getFrameData(cData);

      // Loop over the words for this link
      uint16_t iW = 0;
      while (iW < connSizes[iLink] && dataW != bankEnd) {

        // check MSB for this word
        const auto isNZS = (0x80 & *dataW) != 0;

        if (!isNZS) {
          // ZS decoding... word is bit index

          // load the anode data for this bit
          if ((unsigned) (*dataW) < frameData.size()) {
            const auto& aData = frameData[*dataW];

            // Data 'could' be invalid, e.g. radiation-induced-upsets
            // so cannot make this a hard error
            if (aData.ec != -1 && aData.pmtInEC != -1 && aData.anode != -1) {
              number_of_hits++;
            }
          }

          // move to next word
          ++iW;
          ++dataW;
        }
        else {
          // NZS decoding...

          // which half of the payload are we in ?
          const bool firstHalf = (0 == iW && connSizes[iLink] > 5);
          // Number of words to decode depends on which half of the payload we are in
          const auto nNZSwords = (firstHalf ? 6 : 5);
          // bit offset per half
          const auto halfBitOffset = (firstHalf ? 39 : 0);

          // look forward last NZS word and read backwards to match frame bit order
          for (auto iNZS = nNZSwords - 1; iNZS >= 0; --iNZS) {

            // read the NZS word
            auto nzsW = *(dataW + iNZS);
            // if word zero clear MSB as this is the NZS flag
            if (0 == iNZS) {
              nzsW &= 0x7F;
            }

            // does this word hold any active bits ?
            if (nzsW > 0) {

              // Bit offset for this word
              const auto bitOffset = halfBitOffset + (8 * (nNZSwords - 1 - iNZS));

              // word has data so loop over bits to extract
              for (auto iLB = 0; iLB < 8; ++iLB) {
                // is bit on ?
                // if ( isBitOn( nzsW, iLB ) ) {
                if ((nzsW & (1 << iLB)) != 0) {

                  // form frame bit value
                  const auto bit = iLB + bitOffset;

                  // load the anode data for this bit
                  if ((size_t)(bit) < frameData.size()) {
                    const auto& aData = frameData[bit];

                    // Data 'could' be invalid, e.g. radiation-induced-upsets
                    // so cannot make this a hard error
                    if (aData.ec != -1 && aData.pmtInEC != -1 && aData.anode != -1) {
                      number_of_hits++;
                    }
                  }

                } // bit is on
              }   // loop over word bits

            } // word has any data

          } // loop over all NZS words

          // Finally skip the read NZS words
          iW += nNZSwords;
          dataW += nNZSwords;
        }
      }

    } // no data for this link, so just move on

    // move to next Tel40 link
    ++iLink;
  } // data word loop

  return number_of_hits;
}

template<bool mep_layout>
__global__ void rich_calculate_number_of_hits(
  rich_decoding::Parameters parameters,
  const unsigned event_start,
  const Rich::Future::DAQ::Allen::Tel40CableMapping* cable_mapping,
  const Rich::Future::DAQ::Allen::PDMDBDecodeMapping* pdmdb_mapping)
{
  const auto event_number = parameters.dev_event_list[blockIdx.x];

  // Read raw event
  const auto raw_event = Allen::RawEvent<mep_layout> {parameters.dev_rich_raw_input,
                                                      parameters.dev_rich_raw_input_offsets,
                                                      parameters.dev_rich_raw_input_sizes,
                                                      parameters.dev_rich_raw_input_types,
                                                      event_number + event_start};

  for (unsigned bank_number = threadIdx.x; bank_number < raw_event.number_of_raw_banks; bank_number += blockDim.x) {
    const auto bank = raw_event.raw_bank(bank_number);
    const auto number_of_hits_in_raw_bank =
      rich_calculate_number_of_hits_in_raw_bank(bank, cable_mapping, pdmdb_mapping);
    if (number_of_hits_in_raw_bank > 0) {
      atomicAdd(parameters.dev_rich_number_of_hits + event_number, number_of_hits_in_raw_bank);
    }
  }
}

__device__ void rich_decode_bank(
  const Allen::RawBank& bank,
  const Rich::Future::DAQ::Allen::Tel40CableMapping* cable_mapping,
  const Rich::Future::DAQ::Allen::PDMDBDecodeMapping* pdmdb_mapping,
  unsigned* event_inserted_hits,
  Allen::RichSmartID* event_smart_ids)
{
  std::array<
    Rich::Future::DAQ::PackedFrameSizes::IntType,
    Rich::Future::DAQ::Allen::Tel40CableMapping::MaxConnectionsPerTel40>
    connSizes {};

  auto tel40ID = bank.source_id;
  const auto& connMeta = cable_mapping->tel40Meta(tel40ID);
  const auto nSizeWords = connMeta.nActiveLinks;
  const auto nPackedSizeW = (nSizeWords / 2) + (nSizeWords % 2);

  auto dataW = bank.data;
  auto bankEnd = bank.data + bank.size;
  auto iPayloadWord = 0u;
  auto iWord = 0u;

  for (; iWord < nPackedSizeW && dataW != bankEnd; ++dataW, ++iWord, iPayloadWord += 2) {
    // Extract the sizes from the packed word
    const Rich::Future::DAQ::PackedFrameSizes sizes(*dataW);
    // extract sizes for each packed value
    connSizes[iPayloadWord] = sizes.size1();
    connSizes[iPayloadWord + 1] = sizes.size0();
  }

  const auto& connData = cable_mapping->tel40Data(tel40ID);
  if (connMeta.hasInactiveLinks) {
    for (unsigned iL = 0; iL < connData.size(); ++iL) {
      if (!connData[iL].isActive) {
        for (auto i = connData.size() - 1; i > iL; --i) {
          connSizes[i] = connSizes[i - 1];
        }
        connSizes[iL] = 0;
      }
    }
  }

  // finally loop over payload words and decode hits
  // note iterator starts from where the above header loop ended...
  unsigned iLink {0};
  while (dataW != bankEnd && iLink < connSizes.size()) {
    // Do we have any words to decode for this link
    if (connSizes[iLink] > 0) {
      // Get the Tel40 Data for this connection
      const auto& cData = connData[iLink];

      // get the PDMDB data
      const auto& frameData = pdmdb_mapping->getFrameData(cData);

      // Loop over the words for this link
      uint16_t iW = 0;
      while (iW < connSizes[iLink] && dataW != bankEnd) {

        // check MSB for this word
        const auto isNZS = (0x80 & *dataW) != 0;

        if (!isNZS) {
          // ZS decoding... word is bit index

          // load the anode data for this bit
          if ((unsigned) (*dataW) < frameData.size()) {

            const auto& aData = frameData[*dataW];

            // Data 'could' be invalid, e.g. radiation-induced-upsets
            // so cannot make this a hard error
            if (aData.ec != -1 && aData.pmtInEC != -1 && aData.anode != -1) {
              // make a smart ID
              auto hitID = Allen::RichSmartID {cData.smartID}; // sets RICH, side, module and PMT type

              // Add the PMT and pixel info
              const auto nInMod = (aData.ec * (0 != ((hitID.key() >> 27) & 0x1) ? 1 : 4)) + aData.pmtInEC;
              hitID.setData(
                cData.moduleNum,
                Allen::RichSmartID::ShiftPDMod,
                Allen::RichSmartID::MaskPDMod,
                Allen::RichSmartID::MaskPDIsSet);
              hitID.setData(nInMod, Allen::RichSmartID::ShiftPDNumInMod, Allen::RichSmartID::MaskPDNumInMod);

              const auto row = aData.anode / 8;
              const auto col = 8 - 1 - (aData.anode % 8);
              hitID.setData(
                row,
                Allen::RichSmartID::ShiftPixelRow,
                Allen::RichSmartID::MaskPixelRow,
                Allen::RichSmartID::MaskPixelRowIsSet);
              hitID.setData(
                col,
                Allen::RichSmartID::ShiftPixelCol,
                Allen::RichSmartID::MaskPixelCol,
                Allen::RichSmartID::MaskPixelColIsSet);

              const auto insert_index = atomicAdd(event_inserted_hits, 1);
              event_smart_ids[insert_index] = hitID;
            }
          }

          // move to next word
          ++iW;
          ++dataW;
        }
        else {
          // NZS decoding...

          // which half of the payload are we in ?
          const bool firstHalf = (0 == iW && connSizes[iLink] > 5);
          // Number of words to decode depends on which half of the payload we are in
          const auto nNZSwords = (firstHalf ? 6 : 5);
          // bit offset per half
          const auto halfBitOffset = (firstHalf ? 39 : 0);

          // look forward last NZS word and read backwards to match frame bit order
          for (auto iNZS = nNZSwords - 1; iNZS >= 0; --iNZS) {

            // read the NZS word
            auto nzsW = *(dataW + iNZS);
            // if word zero clear MSB as this is the NZS flag
            if (0 == iNZS) {
              nzsW &= 0x7F;
            }

            // does this word hold any active bits ?
            if (nzsW > 0) {

              // Bit offset for this word
              const auto bitOffset = halfBitOffset + (8 * (nNZSwords - 1 - iNZS));

              // word has data so loop over bits to extract
              for (auto iLB = 0; iLB < 8; ++iLB) {
                // is bit on ?
                // if ( isBitOn( nzsW, iLB ) ) {
                if ((nzsW & (1 << iLB)) != 0) {

                  // form frame bit value
                  const auto bit = iLB + bitOffset;

                  // load the anode data for this bit
                  if ((size_t)(bit) < frameData.size()) {
                    const auto& aData = frameData[bit];
                    // Data 'could' be invalid, e.g. radiation-induced-upsets
                    // so cannot make this a hard error
                    if (aData.ec != -1 && aData.pmtInEC != -1 && aData.anode != -1) {

                      // make a smart ID
                      auto hitID = Allen::RichSmartID {cData.smartID}; // sets RICH, side, module and PMT type

                      // Add the PMT and pixel info
                      const auto nInMod = (aData.ec * (0 != ((hitID.key() >> 27) & 0x1) ? 1 : 4)) + aData.pmtInEC;
                      hitID.setData(
                        cData.moduleNum,
                        Allen::RichSmartID::ShiftPDMod,
                        Allen::RichSmartID::MaskPDMod,
                        Allen::RichSmartID::MaskPDIsSet);
                      hitID.setData(nInMod, Allen::RichSmartID::ShiftPDNumInMod, Allen::RichSmartID::MaskPDNumInMod);

                      const auto row = aData.anode / 8;
                      const auto col = 8 - 1 - (aData.anode % 8);
                      hitID.setData(
                        row,
                        Allen::RichSmartID::ShiftPixelRow,
                        Allen::RichSmartID::MaskPixelRow,
                        Allen::RichSmartID::MaskPixelRowIsSet);
                      hitID.setData(
                        col,
                        Allen::RichSmartID::ShiftPixelCol,
                        Allen::RichSmartID::MaskPixelCol,
                        Allen::RichSmartID::MaskPixelColIsSet);

                      const auto insert_index = atomicAdd(event_inserted_hits, 1);
                      event_smart_ids[insert_index] = hitID;
                    }
                  }

                } // bit is on
              }   // loop over word bits

            } // word has any data

          } // loop over all NZS words

          // Finally skip the read NZS words
          iW += nNZSwords;
          dataW += nNZSwords;
        }
      }

    } // no data for this link, so just move on

    // move to next Tel40 link
    ++iLink;
  } // data word loop
}

template<bool mep_layout>
__global__ void rich_decoding_kernel(
  rich_decoding::Parameters parameters,
  const unsigned event_start,
  const Rich::Future::DAQ::Allen::Tel40CableMapping* cable_mapping,
  const Rich::Future::DAQ::Allen::PDMDBDecodeMapping* pdmdb_mapping,
  unsigned* dev_rich_number_of_inserted_hits)
{
  const auto event_number = parameters.dev_event_list[blockIdx.x];

  auto event_inserted_hits = dev_rich_number_of_inserted_hits + event_number;
  auto event_smart_ids = parameters.dev_smart_ids + parameters.dev_rich_hit_offsets[event_number];

  // Read raw event
  const auto raw_event = Allen::RawEvent<mep_layout> {parameters.dev_rich_raw_input,
                                                      parameters.dev_rich_raw_input_offsets,
                                                      parameters.dev_rich_raw_input_sizes,
                                                      parameters.dev_rich_raw_input_types,
                                                      event_number + event_start};

  for (unsigned bank_number = threadIdx.x; bank_number < raw_event.number_of_raw_banks; bank_number += blockDim.x) {
    const auto bank = raw_event.raw_bank(bank_number);
    rich_decode_bank(bank, cable_mapping, pdmdb_mapping, event_inserted_hits, event_smart_ids);
  }
}

void rich_decoding::rich_decoding_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_rich_number_of_hits_t>(arguments, size<dev_event_list_t>(arguments));
  set_size<dev_rich_hit_offsets_t>(arguments, size<dev_event_list_t>(arguments) + 1);
  set_size<host_rich_hit_offsets_t>(arguments, size<dev_event_list_t>(arguments) + 1);
  set_size<host_rich_total_number_of_hits_t>(arguments, 1);
}

void rich_decoding::rich_decoding_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const Allen::Context& context) const
{
  const auto bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version != 10) {
    throw StrException("Rich bank version not supported (" + std::to_string(bank_version) + ")");
  }

  auto cable_mapping = reinterpret_cast<Rich::Future::DAQ::Allen::Tel40CableMapping*>(constants.dev_rich_cable_mapping);
  auto pdmdb_mapping =
    reinterpret_cast<Rich::Future::DAQ::Allen::PDMDBDecodeMapping*>(constants.dev_rich_pdmdb_mapping);

  // Calculate number of hits into dev_rich_number_of_hits_t
  Allen::memset_async<dev_rich_number_of_hits_t>(arguments, 0, context);
  global_function(
    runtime_options.mep_layout ? rich_calculate_number_of_hits<true> : rich_calculate_number_of_hits<false>)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_x_t>(), context)(
    arguments, std::get<0>(runtime_options.event_interval), cable_mapping, pdmdb_mapping);

  // Copy to host
  data<host_rich_hit_offsets_t>(arguments)[0] = 0;
  Allen::copy<host_rich_hit_offsets_t, dev_rich_number_of_hits_t>(
    arguments, context, size<dev_rich_number_of_hits_t>(arguments), 1, 0);

  // Prefix sum
  host_prefix_sum::host_prefix_sum_impl(
    data<host_rich_hit_offsets_t>(arguments),
    size<host_rich_hit_offsets_t>(arguments),
    data<host_rich_total_number_of_hits_t>(arguments));

  // Copy prefix summed container to device
  Allen::copy_async<dev_rich_hit_offsets_t, host_rich_hit_offsets_t>(arguments, context);

  // Decode RICH hits
  auto dev_rich_number_of_inserted_hits = make_device_buffer<unsigned>(arguments, size<dev_event_list_t>(arguments));
  Allen::memset_async(
    dev_rich_number_of_inserted_hits.data(), 0, dev_rich_number_of_inserted_hits.size_bytes(), context);
  resize<dev_smart_ids_t>(arguments, first<host_rich_total_number_of_hits_t>(arguments));

  global_function(runtime_options.mep_layout ? rich_decoding_kernel<true> : rich_decoding_kernel<false>)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_x_t>(), context)(
    arguments,
    std::get<0>(runtime_options.event_interval),
    cable_mapping,
    pdmdb_mapping,
    dev_rich_number_of_inserted_hits.data());

  if (property<verbosity_t>() >= logger::debug) {
    // Print output
    print<dev_rich_hit_offsets_t>(arguments);
    print<dev_smart_ids_t>(arguments);
  }
}

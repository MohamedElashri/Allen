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
#include "SciFiPreDecode.cuh"
#include <MEPTools.h>
#include "assert.h"

INSTANTIATE_ALGORITHM(scifi_pre_decode::scifi_pre_decode_t)

template<int decoding_version, bool mep_layout>
__global__ void
scifi_pre_decode_kernel(scifi_pre_decode::Parameters parameters, const unsigned event_start, const char* scifi_geometry)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  SciFi::SciFiGeometry geom(scifi_geometry);
  const auto scifi_raw_event = SciFi::RawEvent<mep_layout>(
    parameters.dev_scifi_raw_input,
    parameters.dev_scifi_raw_input_offsets,
    parameters.dev_scifi_raw_input_sizes,
    parameters.dev_scifi_raw_input_types,
    event_number + event_start);

  const uint32_t* hit_offsets = parameters.dev_scifi_hit_offsets + event_number * SciFi::Constants::n_sipms;

  // Main execution loop
  for (unsigned iRawBank = threadIdx.x; iRawBank < scifi_raw_event.number_of_raw_banks(); iRawBank += blockDim.x) {

    auto rawbank = scifi_raw_event.raw_bank(iRawBank);
    if (rawbank.type != LHCb::RawBank::FTCluster) continue;

    const auto iRowInMap = SciFi::getRowInMap(rawbank, geom);
    if (iRowInMap == geom.number_of_banks) continue;
    const auto [starting_it, last] = SciFi::readAndCheckRawBank(rawbank);
    if (last == starting_it) continue;
    const unsigned number_of_iterations = last - starting_it;
    int last_uniqueMat = -1;
    uint32_t* cluster_reference = nullptr;
    uint32_t mat_count = 0;
    int direction = 1;
    for (unsigned it_number = 0; it_number < number_of_iterations; ++it_number) {
      auto it = starting_it + it_number;
      const uint16_t c = *it;
      uint32_t ch;
      if constexpr (decoding_version == 4 || decoding_version == 6) {
        ch = geom.bank_first_channel[iRawBank] + SciFi::channelInBank(c); //---LoH: only works for versions 4-6
      }
      else { // Decoding v7 and v8
        auto globalSiPM = SciFi::getGlobalSiPMFromIndex(geom, iRowInMap, c);
        if (globalSiPM == SciFi::SciFiChannelID::kInvalidChannelID) // Link not found or local link > 24. Should never
                                                                    // happen but seen in early data.
          continue;
        ch = globalSiPM + SciFi::channelInLink(c);
      }
      const auto chid = SciFi::SciFiChannelID(ch);
      uint32_t correctedMat = chid.globalMatIdx_Xorder();
      if ((int) correctedMat != last_uniqueMat) {
        last_uniqueMat = correctedMat;
        cluster_reference = parameters.dev_cluster_references + hit_offsets[correctedMat];
        direction = chid.reversedZone() ? -1 : 1;
        mat_count = chid.reversedZone() ? hit_offsets[correctedMat + 1] - hit_offsets[correctedMat] - 1 : 0;
      }
      const auto store_sorted_fn = [&](uint32_t cluster_chan, uint8_t cluster_fraction, uint8_t pseudoSize) {
        cluster_reference[mat_count] =
          SciFi::ClusterReference::makeClusterReference(cluster_chan, cluster_fraction, pseudoSize);
        mat_count += direction;
      };

      uint8_t cluster_fraction = SciFi::fraction(c);

      if constexpr (decoding_version == 4) {
        // In v4 decoding clusters may have pseudosize only equal to 0 or 4
        uint8_t pseudoSize = SciFi::cSize(c) ? 0 : 4;
        store_sorted_fn(ch, cluster_fraction, pseudoSize);
      }
      else if constexpr (decoding_version >= 6) {
        if (!SciFi::cSize(c)) {
          // Single cluster
          store_sorted_fn(ch, cluster_fraction, 4);
        }
        else {
          const unsigned c2 = *(it + 1);
          if (SciFi::lastClusterSiPM(c, c2, it, last))
            // last cluster in bank or in sipm
            store_sorted_fn(ch, cluster_fraction, 0);
          else if (SciFi::wellOrdered(c, c2) && SciFi::startLargeCluster<decoding_version>(c)) {
            if (SciFi::endLargeCluster<decoding_version>(c2)) {
              const unsigned int widthClus = (SciFi::cell(c2) - SciFi::cell(c) + 2);
              if (widthClus > 8) {
                unsigned j = 0;
                for (; j < widthClus - 4; j += 4)
                  // big cluster(s)
                  store_sorted_fn(ch + j, 1, 0);
                // add the last edge
                store_sorted_fn(ch + j + (widthClus - j - 1) / 2 - 1, (widthClus - 1) % 2, 0);
              }
              else
                store_sorted_fn(ch + (widthClus - 1) / 2 - 1, (widthClus - 1) % 2, widthClus);
              ++it_number;
            }
            else { /* Corrupt cluster type 1 */
              ++it_number;
            }
          }
          else { /* ERROR */
            if (!SciFi::wellOrdered(c, c2)) ++it_number;
          }
        }
      }
    }
  }
}

void scifi_pre_decode::scifi_pre_decode_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Ensure the bank version is supported
  const auto bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) return; // no SciFi banks present in data
  if (bank_version < 4 || bank_version > 8) {
    throw StrException("SciFi bank version not supported (" + std::to_string(bank_version) + ")");
  }

  set_size<dev_cluster_references_t>(arguments, first<host_accumulated_number_of_scifi_hits_t>(arguments));
}

void scifi_pre_decode::scifi_pre_decode_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const Allen::Context& context) const
{
  auto const bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) return; // no SciFi banks present in data

  // Mapping is:
  // * Version 4, version 5: Use v4 decoding
  // * Version 6: Use v6 decoding
  auto kernel_fn = (bank_version == 4 || bank_version == 5) ?
                     (runtime_options.mep_layout ? global_function(scifi_pre_decode_kernel<4, true>) :
                                                   global_function(scifi_pre_decode_kernel<4, false>)) :
                     (bank_version == 6) ?
                     (runtime_options.mep_layout ? global_function(scifi_pre_decode_kernel<6, true>) :
                                                   global_function(scifi_pre_decode_kernel<6, false>)) :
                     (bank_version == 7 || (bank_version == 8 && property<decode_v8_as_v7_t>())) ?
                     (runtime_options.mep_layout ? global_function(scifi_pre_decode_kernel<7, true>) :
                                                   global_function(scifi_pre_decode_kernel<7, false>)) :
                     (runtime_options.mep_layout ? global_function(scifi_pre_decode_kernel<8, true>) :
                                                   global_function(scifi_pre_decode_kernel<8, false>));

  kernel_fn(dim3(size<dev_event_list_t>(arguments)), dim3(SciFi::SciFiRawBankParams::NbBanksMax), context)(
    arguments, std::get<0>(runtime_options.event_interval), constants.dev_scifi_geometry);
}

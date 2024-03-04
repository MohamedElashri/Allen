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
#include <MEPTools.h>
#include <SciFiCalculateClusterCount.cuh>
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(scifi_calculate_cluster_count::scifi_calculate_cluster_count_t)

/**
 * @brief This function calculates the amount of clusters in all mats.
 * @details More details about the SciFi format:
 *          https://cds.cern.ch/record/2630154/files/LHCb-INT-2018-024.pdf
 *
 * Kernel for decoding from MEP layout
 */
template<int decoding_version, bool mep_layout>
__global__ void scifi_calculate_cluster_count_kernel(
  scifi_calculate_cluster_count::Parameters parameters,
  const unsigned event_start,
  const char* scifi_geometry)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const auto scifi_raw_event = SciFi::RawEvent<mep_layout>(
    parameters.dev_scifi_raw_input,
    parameters.dev_scifi_raw_input_offsets,
    parameters.dev_scifi_raw_input_sizes,
    parameters.dev_scifi_raw_input_types,
    event_number + event_start);
  const SciFi::SciFiGeometry geom(scifi_geometry);
  uint32_t* hit_count = parameters.dev_scifi_hit_count + event_number * SciFi::Constants::n_sipms;

  for (unsigned iRawBank = threadIdx.x; iRawBank < scifi_raw_event.number_of_raw_banks(); iRawBank += blockDim.x) {
    uint32_t* hits_module;

    auto rawbank = scifi_raw_event.raw_bank(iRawBank);
    if (rawbank.type != LHCb::RawBank::FTCluster) continue;

    const auto iRowInMap = SciFi::getRowInMap(rawbank, geom);
    if (iRowInMap == geom.number_of_banks) continue;
    const auto [starting_it, last] = SciFi::readAndCheckRawBank(rawbank);
    for (auto* it = starting_it; it < last; ++it) { // loop over the clusters
      uint16_t c = *it;
      SciFi::SciFiChannelID chid(SciFi::SciFiChannelID::kInvalidChannelID);
      if constexpr (decoding_version != 7 && decoding_version != 8) {
        uint32_t ch = geom.bank_first_channel[iRawBank] + SciFi::channelInBank(c);
        chid = SciFi::SciFiChannelID(ch);
      }
      else {
        chid = SciFi::SciFiChannelID(SciFi::getGlobalSiPMFromIndex(geom, iRowInMap, c));
        if (chid.channelID == SciFi::SciFiChannelID::kInvalidChannelID) /*FIX*/ {
          auto* counter = parameters.link_error_counter + event_number;
          atomicAdd(counter, 1);
          continue;
        }
      }
      const uint32_t uniqueGroupOrMat = chid.globalMatIdx_Xorder();
      hits_module = &hit_count[uniqueGroupOrMat];

      if constexpr (decoding_version == 4) {
        // v4 code does not use a special format for a large clusters, then can be added directly
        atomicAdd(hits_module, 1);
      }
      else if constexpr (decoding_version >= 6) {
        if (!SciFi::cSize(c)) { // Not flagged as large
          atomicAdd(hits_module, 1);
        }
        else { // flagged as first edge of large cluster
          unsigned c2 = *(it + 1);
          // last cluster in bank or in sipm
          if (SciFi::lastClusterSiPM(c, c2, it, last))
            atomicAdd(hits_module, 1);
          else if (SciFi::wellOrdered(c, c2) && SciFi::startLargeCluster<decoding_version>(c)) {
            if (SciFi::endLargeCluster<decoding_version>(c2)) {
              unsigned int widthClus = (SciFi::cell(c2) - SciFi::cell(c) + 2);
              if (widthClus > 8)
                // number of for loop passes in decoder + one additional
                atomicAdd(hits_module, (widthClus - 1) / 4 + 1);
              else
                atomicAdd(hits_module, 1);
              ++it;
            }
            else { /* Corrupt cluster type 1 */
              ++it;
            }
          }
          else { /* ERROR */
            if (!SciFi::wellOrdered(c, c2))
              ++it;
            else {
            }
          }
        }
      }
    }
  }
}

__global__ void scifi_compress_hits_offset(scifi_calculate_cluster_count::Parameters parameters)
{
  const unsigned event_number = blockIdx.x;
  for (unsigned i = threadIdx.x; i < SciFi::Constants::n_zones + 1; i += blockDim.x) { // for cpu backend...
    auto quarter = i * 2;
    auto first_sipm_in_zone = (quarter * 5 + (quarter >= 32 ? quarter - 32 : 0)) * SciFi::Constants::n_sipms_per_module;
    parameters.dev_scifi_hit_offsets[event_number * SciFi::Constants::n_zones + i] =
      parameters.dev_scifi_hit_count[event_number * SciFi::Constants::n_sipms + first_sipm_in_zone];
  }
}

void scifi_calculate_cluster_count::scifi_calculate_cluster_count_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_scifi_hit_count_t>(arguments, first<host_number_of_events_t>(arguments) * SciFi::Constants::n_sipms + 1);
  set_size<dev_scifi_hit_offsets_t>(
    arguments, first<host_number_of_events_t>(arguments) * SciFi::Constants::n_zones + 1);
  set_size<dev_scifi_link_error_counter_t>(arguments, first<host_number_of_events_t>(arguments));

  // The total sum holder just holds a single unsigned integer.
  set_size<host_total_sum_holder_t>(arguments, 1);
}

void scifi_calculate_cluster_count::scifi_calculate_cluster_count_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_scifi_hit_count_t>(arguments, 0, context);
  Allen::memset_async<dev_scifi_link_error_counter_t>(arguments, 0, context);

  auto const bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) return; // no SciFi banks present in data

  auto kernel_fn = (bank_version == 4 || bank_version == 5) ?
                     (runtime_options.mep_layout ? global_function(scifi_calculate_cluster_count_kernel<4, true>) :
                                                   global_function(scifi_calculate_cluster_count_kernel<4, false>)) :
                     (bank_version == 6) ?
                     (runtime_options.mep_layout ? global_function(scifi_calculate_cluster_count_kernel<6, true>) :
                                                   global_function(scifi_calculate_cluster_count_kernel<6, false>)) :
                     (bank_version == 7 || (bank_version == 8 && property<decode_v8_as_v7_t>())) ?
                     (runtime_options.mep_layout ? global_function(scifi_calculate_cluster_count_kernel<7, true>) :
                                                   global_function(scifi_calculate_cluster_count_kernel<7, false>)) :
                     (runtime_options.mep_layout ? global_function(scifi_calculate_cluster_count_kernel<8, true>) :
                                                   global_function(scifi_calculate_cluster_count_kernel<8, false>));

  kernel_fn(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, std::get<0>(runtime_options.event_interval), constants.dev_scifi_geometry);

  unsigned array_size = size<dev_scifi_hit_count_t>(arguments) - 1;
  PrefixSum::prefix_sum(*this, arguments, context, data<dev_scifi_hit_count_t>(arguments), array_size);

  Allen::copy<host_total_sum_holder_t, dev_scifi_hit_count_t>(
    arguments, context, 1, 0, size<dev_scifi_hit_count_t>(arguments) - 1);

  global_function(scifi_compress_hits_offset)(
    dim3(first<host_number_of_events_t>(arguments)), dim3(SciFi::Constants::n_zones + 1), context)(arguments);
}

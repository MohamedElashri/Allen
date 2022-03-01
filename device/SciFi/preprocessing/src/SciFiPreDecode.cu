/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "SciFiPreDecode.cuh"
#include <MEPTools.h>
#include "assert.h"

INSTANTIATE_ALGORITHM(scifi_pre_decode::scifi_pre_decode_t)

__device__ void store_sorted_cluster_reference(
  SciFi::ConstHitCount& hit_count,
  const uint32_t uniqueMat,
  const uint32_t chan,
  const uint32_t* shared_mat_offsets,
  uint32_t* shared_mat_count,
  const int raw_bank,
  const int it,
  uint32_t* cluster_references,
  const int condition,
  const int delta)
{
  uint32_t uniqueGroupOrMat;
  // adaptation to hybrid decoding
  if (uniqueMat < SciFi::Constants::n_consecutive_raw_banks * SciFi::Constants::n_mats_per_consec_raw_bank)
    uniqueGroupOrMat = uniqueMat / SciFi::Constants::n_mats_per_consec_raw_bank;
  else
    uniqueGroupOrMat = uniqueMat - SciFi::Constants::mat_index_substract;

  uint32_t hitIndex = shared_mat_count[uniqueGroupOrMat]++;

  const SciFi::SciFiChannelID id {chan};
  if (id.reversedZone()) {
    hitIndex = hit_count.mat_group_or_mat_number_of_hits(uniqueGroupOrMat) - 1 - hitIndex;
  }
  assert(hitIndex < hit_count.mat_group_or_mat_number_of_hits(uniqueGroupOrMat));
  assert(uniqueGroupOrMat < SciFi::Constants::n_mat_groups_and_mats);
  hitIndex += shared_mat_offsets[uniqueGroupOrMat];

  cluster_references[hitIndex] =
    (raw_bank & 0xFF) << 24 | (it & 0xFF) << 16 | (condition & 0x07) << 13 | (delta & 0xFF);
}

template<int decoding_version, bool mep_layout>
__global__ void scifi_pre_decode_kernel(scifi_pre_decode::Parameters parameters, const char* scifi_geometry)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  SciFi::SciFiGeometry geom(scifi_geometry);
  const auto scifi_raw_event =
    SciFi::RawEvent<mep_layout>(parameters.dev_scifi_raw_input, parameters.dev_scifi_raw_input_offsets, parameters.dev_scifi_raw_input_sizes, event_number);

  SciFi::ConstHitCount hit_count {parameters.dev_scifi_hit_offsets, event_number};

  __shared__ uint32_t shared_mat_offsets[SciFi::Constants::n_mat_groups_and_mats];
  __shared__ uint32_t shared_mat_count[SciFi::Constants::n_mat_groups_and_mats];

  for (unsigned i = threadIdx.x; i < SciFi::Constants::n_mat_groups_and_mats; i += blockDim.x) {
    shared_mat_offsets[i] = *hit_count.mat_offsets_p(i);
    shared_mat_count[i] = 0;
  }

  __syncthreads();

  // Main execution loop
  for (unsigned i = threadIdx.x; i < scifi_raw_event.number_of_raw_banks(); i += blockDim.x) {
    const unsigned current_raw_bank = SciFi::getRawBankIndexOrderedByX(i);

    auto rawbank = scifi_raw_event.raw_bank(current_raw_bank);
    const uint16_t* starting_it = rawbank.data + 2;
    uint16_t* last = rawbank.last;
    if (*(last - 1) == 0) --last; // Remove padding at the end

    if (starting_it >= last || starting_it >= rawbank.last) continue;

    const unsigned number_of_iterations = last - starting_it;
    for (unsigned it_number = 0; it_number < number_of_iterations; ++it_number) {
      auto it = starting_it + it_number;
      const uint16_t c = *it;
      const uint32_t ch = geom.bank_first_channel[rawbank.sourceID] + SciFi::channelInBank(c);
      const auto chid = SciFi::SciFiChannelID(ch);
      const uint32_t correctedMat = chid.correctedUniqueMat();

      const auto store_sorted_fn = [&](const int condition, const int delta) {
        store_sorted_cluster_reference(
          hit_count,
          correctedMat,
          ch,
          shared_mat_offsets,
          shared_mat_count,
          current_raw_bank,
          it_number,
          parameters.dev_cluster_references,
          condition,
          delta);
      };

      if constexpr (decoding_version == 4) {
        store_sorted_fn(0x01, 0x00);
      }
      else if constexpr (decoding_version == 6) {
        if (!SciFi::cSize(c)) {
          // Single cluster
          store_sorted_fn(0x01, 0x00);
        }
        else if (SciFi::fraction(c)) {
          if (it + 1 == last || SciFi::getLinkInBank(c) != SciFi::getLinkInBank(*(it + 1))) {
            // last cluster in bank or in sipm
            store_sorted_fn(0x02, 0x00);
          }
          else {
            const unsigned c2 = *(it + 1);
            assert(SciFi::cSize(c2) && !SciFi::fraction(c2));
            const unsigned int widthClus = (SciFi::cell(c2) - SciFi::cell(c) + 2);
            if (widthClus > 8) {
              uint16_t j = 0;
              for (; j < widthClus - 4; j += 4) {
                // big cluster(s)
                store_sorted_fn(0x03, j);
              }

              // add the last edge
              store_sorted_fn(0x04, j);
            }
            else {
              store_sorted_fn(0x05, 0x00);
            }
            ++it_number;
          }
        }
      }
    }
  }
}

void scifi_pre_decode::scifi_pre_decode_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_cluster_references_t>(
    arguments, first<host_accumulated_number_of_scifi_hits_t>(arguments) * SciFi::Hits::number_of_arrays);
}

void scifi_pre_decode::scifi_pre_decode_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  auto const bank_version = first<host_raw_bank_version_t>(arguments);

  // Ensure the bank version is supported
  if (bank_version != 4 && bank_version != 5 && bank_version != 6) {
    throw StrException("SciFi bank version not supported (" + std::to_string(bank_version) + ")");
  }

  // Mapping is:
  // * Version 4, version 5: Use v4 decoding
  // * Version 6: Use v6 decoding
  auto kernel_fn = (bank_version == 4 || bank_version == 5) ?
                     (runtime_options.mep_layout ? global_function(scifi_pre_decode_kernel<4, true>) :
                                                   global_function(scifi_pre_decode_kernel<4, false>)) :
                     (runtime_options.mep_layout ? global_function(scifi_pre_decode_kernel<6, true>) :
                                                   global_function(scifi_pre_decode_kernel<6, false>));

  kernel_fn(dim3(size<dev_event_list_t>(arguments)), dim3(SciFi::SciFiRawBankParams::NbBanks), context)(
    arguments, constants.dev_scifi_geometry);
}

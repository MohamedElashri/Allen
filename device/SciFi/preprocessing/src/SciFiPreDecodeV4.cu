/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "SciFiPreDecodeV4.cuh"
#include <MEPTools.h>
#include "assert.h"

// Original v4 code was modified to use v6 approach

INSTANTIATE_ALGORITHM(scifi_pre_decode_v4::scifi_pre_decode_v4_t)

__device__ void store_sorted_cluster_reference_v4(
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

template<bool mep_layout>
__global__ void scifi_pre_decode_v4_kernel(scifi_pre_decode_v4::Parameters parameters, const char* scifi_geometry)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  SciFi::SciFiGeometry geom(scifi_geometry);
  const auto scifi_raw_event =
    SciFi::RawEvent<mep_layout>(parameters.dev_scifi_raw_input, parameters.dev_scifi_raw_input_offsets, event_number);

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

      const auto store_sorted_v4_fn = [&](const int condition, const int delta) {
        store_sorted_cluster_reference_v4(
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

      store_sorted_v4_fn(0x01, 0x00);
    }
  }
}

void scifi_pre_decode_v4::scifi_pre_decode_v4_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_cluster_references_t>(
    arguments, first<host_accumulated_number_of_scifi_hits_t>(arguments) * SciFi::Hits::number_of_arrays);
}

void scifi_pre_decode_v4::scifi_pre_decode_v4_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  global_function(runtime_options.mep_layout ? scifi_pre_decode_v4_kernel<true> : scifi_pre_decode_v4_kernel<false>)(
    dim3(size<dev_event_list_t>(arguments)), dim3(SciFi::SciFiRawBankParams::NbBanks), context)(
    arguments, constants.dev_scifi_geometry);
}

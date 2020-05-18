#include "SciFiPreDecodeV6.cuh"
#include <MEPTools.h>
#include "assert.h"

void scifi_pre_decode_v6::scifi_pre_decode_v6_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_cluster_references_t>(
    arguments, first<host_accumulated_number_of_scifi_hits_t>(arguments) * SciFi::Hits::number_of_arrays);
}

void scifi_pre_decode_v6::scifi_pre_decode_v6_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  if (runtime_options.mep_layout) {
    global_function(scifi_pre_decode_v6_mep)(
      dim3(first<host_number_of_selected_events_t>(arguments)), dim3(SciFi::SciFiRawBankParams::NbBanks), cuda_stream)(
      arguments, constants.dev_scifi_geometry);
  }
  else {
    global_function(scifi_pre_decode_v6)(
      dim3(first<host_number_of_selected_events_t>(arguments)), dim3(SciFi::SciFiRawBankParams::NbBanks), cuda_stream)(
      arguments, constants.dev_scifi_geometry);
  }
}

using namespace SciFi;

__device__ void store_sorted_cluster_reference_v6(
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

__global__ void scifi_pre_decode_v6::scifi_pre_decode_v6(
  scifi_pre_decode_v6::Parameters parameters,
  const char* scifi_geometry)
{
  const uint event_number = blockIdx.x;
  const uint selected_event_number = parameters.dev_event_list[event_number];

  SciFiGeometry geom(scifi_geometry);
  const auto event =
    SciFiRawEvent(parameters.dev_scifi_raw_input + parameters.dev_scifi_raw_input_offsets[selected_event_number]);

  ConstHitCount hit_count {parameters.dev_scifi_hit_offsets, event_number};

  __shared__ uint32_t shared_mat_offsets[SciFi::Constants::n_mat_groups_and_mats];
  __shared__ uint32_t shared_mat_count[SciFi::Constants::n_mat_groups_and_mats];

  for (uint i = threadIdx.x; i < SciFi::Constants::n_mat_groups_and_mats; i += blockDim.x) {
    shared_mat_offsets[i] = *hit_count.mat_offsets_p(i);
    shared_mat_count[i] = 0;
  }

  __syncthreads();

  // Main execution loop
  for (uint i = threadIdx.x; i < event.number_of_raw_banks; i += blockDim.x) {
    const uint current_raw_bank = getRawBankIndexOrderedByX(i);

    auto rawbank = event.getSciFiRawBank(current_raw_bank);
    const uint16_t* starting_it = rawbank.data + 2;
    uint16_t* last = rawbank.last;
    if (*(last - 1) == 0) --last; // Remove padding at the end

    if (starting_it >= last) continue;

    const uint number_of_iterations = last - starting_it;
    for (uint it_number = 0; it_number < number_of_iterations; ++it_number) {
      auto it = starting_it + it_number;
      const uint16_t c = *it;
      const uint32_t ch = geom.bank_first_channel[rawbank.sourceID] + channelInBank(c);
      const auto chid = SciFiChannelID(ch);
      const uint32_t correctedMat = chid.correctedUniqueMat();

      const auto store_sorted_v6_fn = [&](const int condition, const int delta) {
        store_sorted_cluster_reference_v6(
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

      if (!cSize(c)) {
        // Single cluster
        store_sorted_v6_fn(0x01, 0x00);
      }
      else if (fraction(c)) {
        if (it + 1 == last || getLinkInBank(c) != getLinkInBank(*(it + 1))) {
          // last cluster in bank or in sipm
          store_sorted_v6_fn(0x02, 0x00);
        }
        else {
          const unsigned c2 = *(it + 1);
          assert(cSize(c2) && !fraction(c2));
          const unsigned int widthClus = (cell(c2) - cell(c) + 2);
          if (widthClus > 8) {
            uint16_t j = 0;
            for (; j < widthClus - 4; j += 4) {
              // big cluster(s)
              store_sorted_v6_fn(0x03, j);
            }

            // add the last edge
            store_sorted_v6_fn(0x04, j);
          }
          else {
            store_sorted_v6_fn(0x05, 0x00);
          }
          ++it_number;
        }
      }
    }
  }
}

__global__ void scifi_pre_decode_v6::scifi_pre_decode_v6_mep(
  scifi_pre_decode_v6::Parameters parameters,
  const char* scifi_geometry)
{
  const uint event_number = blockIdx.x;
  const uint selected_event_number = parameters.dev_event_list[event_number];

  SciFiGeometry geom(scifi_geometry);
  ConstHitCount hit_count {parameters.dev_scifi_hit_offsets, event_number};

  __shared__ uint32_t shared_mat_offsets[SciFi::Constants::n_mat_groups_and_mats];
  __shared__ uint32_t shared_mat_count[SciFi::Constants::n_mat_groups_and_mats];

  for (uint i = threadIdx.x; i < SciFi::Constants::n_mat_groups_and_mats; i += blockDim.x) {
    shared_mat_offsets[i] = *hit_count.mat_offsets_p(i);
    shared_mat_count[i] = 0;
  }

  __syncthreads();

  auto const n_scifi_banks = parameters.dev_scifi_raw_input_offsets[0];

  // Main execution loop
  for (uint i = threadIdx.x; i < n_scifi_banks; i += blockDim.x) {
    // Create SciFi raw bank from MEP layout
    auto const rawbank = MEP::raw_bank<SciFiRawBank>(
      parameters.dev_scifi_raw_input, parameters.dev_scifi_raw_input_offsets, selected_event_number, i);

    const uint16_t* starting_it = rawbank.data + 2;
    uint16_t* last = rawbank.last;
    if (*(last - 1) == 0) --last; // Remove padding at the end

    if (starting_it >= last) continue;

    const uint number_of_iterations = last - starting_it;
    for (uint it_number = 0; it_number < number_of_iterations; ++it_number) {
      auto it = starting_it + it_number;
      const uint16_t c = *it;
      const uint32_t ch = geom.bank_first_channel[rawbank.sourceID] + channelInBank(c);
      const auto chid = SciFiChannelID(ch);
      const uint32_t correctedMat = chid.correctedUniqueMat();

      const auto store_sorted_v6_fn = [&](const int condition, const int delta) {
        store_sorted_cluster_reference_v6(
          hit_count,
          correctedMat,
          ch,
          shared_mat_offsets,
          shared_mat_count,
          i,
          it_number,
          parameters.dev_cluster_references,
          condition,
          delta);
      };

      if (!cSize(c)) {
        // Single cluster
        store_sorted_v6_fn(0x01, 0x00);
      }
      else if (fraction(c)) {
        if (it + 1 == last || getLinkInBank(c) != getLinkInBank(*(it + 1))) {
          // last cluster in bank or in sipm
          store_sorted_v6_fn(0x02, 0x00);
        }
        else {
          const unsigned c2 = *(it + 1);
          assert(cSize(c2) && !fraction(c2));
          const unsigned int widthClus = (cell(c2) - cell(c) + 2);
          if (widthClus > 8) {
            uint16_t j = 0;
            for (; j < widthClus - 4; j += 4) {
              // big cluster(s)
              store_sorted_v6_fn(0x03, j);
            }

            // add the last edge
            store_sorted_v6_fn(0x04, j);
          }
          else {
            store_sorted_v6_fn(0x05, 0x00);
          }
          ++it_number;
        }
      }
    }
  }
}

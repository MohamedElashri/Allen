#include "SciFiPreDecodeV6.cuh"
#include "assert.h"

void scifi_pre_decode_v6_t::set_arguments_size(
  ArgumentRefManager<T> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  set_size<dev_scifi_hits_t>(arguments, host_buffers.scifi_hits_uints());
}

void scifi_pre_decode_v6_t::operator()(
  const ArgumentRefManager<T>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  function(dim3(value<host_number_of_selected_events_t>(arguments)), dim3(SciFi::SciFiRawBankParams::NbBanks), cuda_stream)(
    offset<dev_scifi_raw_input_t>(arguments),
    offset<dev_scifi_raw_input_offsets_t>(arguments),
    offset<dev_event_list_t>(arguments),
    offset<dev_scifi_hit_count_t>(arguments),
    offset<dev_scifi_hits_t>(arguments),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res);
}

using namespace SciFi;

__device__ void store_sorted_cluster_reference_v6(
  const SciFi::HitCount& hit_count,
  const uint32_t uniqueMat,
  const uint32_t chan,
  const uint32_t* shared_mat_offsets,
  uint32_t* shared_mat_count,
  const int raw_bank,
  const int it,
  SciFi::Hits& hits,
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

  hits.cluster_reference[hitIndex] =
    (raw_bank & 0xFF) << 24 | (it & 0xFF) << 16 | (condition & 0x07) << 13 | (delta & 0xFF);
}

__global__ void scifi_pre_decode_v6(
  char* scifi_events,
  uint* scifi_event_offsets,
  const uint* event_list,
  uint* scifi_hit_count,
  uint* scifi_hits,
  char* scifi_geometry,
  const float* dev_inv_clus_res)
{
  const int number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  const uint selected_event_number = event_list[event_number];

  SciFiGeometry geom(scifi_geometry);
  const auto event = SciFiRawEvent(scifi_events + scifi_event_offsets[selected_event_number]);

  Hits hits {
    scifi_hits, scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats], &geom, dev_inv_clus_res};
  HitCount hit_count {scifi_hit_count, event_number};

  __shared__ uint32_t shared_mat_offsets[SciFi::Constants::n_mat_groups_and_mats];
  __shared__ uint32_t shared_mat_count[SciFi::Constants::n_mat_groups_and_mats];

  for (uint i = threadIdx.x; i < SciFi::Constants::n_mat_groups_and_mats; i += blockDim.x) {
    shared_mat_offsets[i] = hit_count.mat_offsets[i];
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

    if (starting_it >= last) return;

    const uint number_of_iterations = last - starting_it;
    for (uint it_number = 0; it_number < number_of_iterations; ++it_number) {
      auto it = starting_it + it_number;
      const uint16_t c = *it;
      const uint32_t ch = geom.bank_first_channel[rawbank.sourceID] + channelInBank(c);
      const auto chid = SciFiChannelID(ch);
      const uint32_t correctedMat = chid.correctedUniqueMat();

// shortcut for better readability and less redundancy
#define STOREARGS hit_count, correctedMat, ch, shared_mat_offsets, shared_mat_count, current_raw_bank, it_number, hits

      if (!cSize(c)) {
        // Single cluster
        store_sorted_cluster_reference_v6(STOREARGS, 0x01, 0x00);
      }
      else if (fraction(c)) {
        if (it + 1 == last || getLinkInBank(c) != getLinkInBank(*(it + 1))) {
          // last cluster in bank or in sipm
          store_sorted_cluster_reference_v6(STOREARGS, 0x02, 0x00);
        }
        else {
          const unsigned c2 = *(it + 1);
          assert(cSize(c2) && !fraction(c2));
          const unsigned int widthClus = (cell(c2) - cell(c) + 2);
          if (widthClus > 8) {
            uint16_t j = 0;
            for (; j < widthClus - 4; j += 4) {
              // big cluster(s)
              store_sorted_cluster_reference_v6(STOREARGS, 0x03, j);
            }

            // add the last edge
            store_sorted_cluster_reference_v6(STOREARGS, 0x04, j);
          }
          else {
            store_sorted_cluster_reference_v6(STOREARGS, 0x05, 0x00);
          }
          ++it_number;
        }
      }
    }
  }
}

#include "MEPTools.h"
#include "SciFiPreDecodeV4.cuh"
#include <cassert>

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
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  if (runtime_options.mep_layout) {
    global_function(scifi_pre_decode_v4_mep)(
      dim3(first<host_number_of_selected_events_t>(arguments)), dim3(SciFi::SciFiRawBankParams::NbBanks), cuda_stream)(
      arguments, constants.dev_scifi_geometry);
  }
  else {
    global_function(scifi_pre_decode_v4)(
      dim3(first<host_number_of_selected_events_t>(arguments)), dim3(SciFi::SciFiRawBankParams::NbBanks), cuda_stream)(
      arguments, constants.dev_scifi_geometry);
  }
}

using namespace SciFi;

__device__ void store_sorted_cluster_reference_v4(
  SciFi::ConstHitCount& hit_count,
  const uint32_t uniqueMat,
  const uint32_t chan,
  const uint32_t& shared_mat_offsets,
  uint32_t& shared_mat_count,
  const int raw_bank,
  const int it,
  uint32_t* cluster_references)
{
  uint32_t hitIndex = shared_mat_count++;

  const SciFi::SciFiChannelID id {chan};
  if (id.reversedZone()) {
    hitIndex = hit_count.mat_number_of_hits(uniqueMat) - 1 - hitIndex;
  }

  assert(hitIndex < hit_count.mat_number_of_hits(uniqueMat));
  hitIndex += shared_mat_offsets;

  // Cluster reference:
  //   raw bank: 8 bits
  //   element (it): 8 bits
  cluster_references[hitIndex] = (raw_bank & 0xFF) << 8 | (it & 0xFF);
}

__device__ void pre_decode_raw_bank_v4(
  SciFi::ConstHitCount& hit_count,
  SciFiGeometry const& geom,
  SciFiRawBank const& rawbank,
  const unsigned bank_index,
  uint32_t const* shared_mat_offsets,
  uint32_t* shared_mat_count,
  uint32_t* cluster_references)
{
  const uint16_t* starting_it = rawbank.data + 2;
  uint16_t* last = rawbank.last;
  if (*(last - 1) == 0) --last; // Remove padding at the end

  if (starting_it < last) {
    const unsigned number_of_iterations = last - starting_it;
    for (unsigned it_number = 0; it_number < number_of_iterations; ++it_number) {
      auto it = starting_it + it_number;
      const uint16_t c = *it;
      const uint32_t ch = geom.bank_first_channel[rawbank.sourceID] + channelInBank(c);
      const auto chid = SciFiChannelID(ch);
      const uint32_t correctedMat = chid.correctedUniqueMat();

      store_sorted_cluster_reference_v4(
        hit_count,
        correctedMat,
        ch,
        shared_mat_offsets
          [correctedMat - SciFi::Constants::n_consecutive_raw_banks * SciFi::Constants::n_mats_per_consec_raw_bank],
        shared_mat_count
          [correctedMat - SciFi::Constants::n_consecutive_raw_banks * SciFi::Constants::n_mats_per_consec_raw_bank],
        bank_index,
        it_number,
        cluster_references);
    }
  }
}

__global__ void scifi_pre_decode_v4::scifi_pre_decode_v4(
  scifi_pre_decode_v4::Parameters parameters,
  const char* scifi_geometry)
{
  const unsigned event_number = blockIdx.x;
  const unsigned selected_event_number = parameters.dev_event_list[event_number];

  SciFiGeometry geom(scifi_geometry);
  const auto event =
    SciFiRawEvent(parameters.dev_scifi_raw_input + parameters.dev_scifi_raw_input_offsets[selected_event_number]);
  SciFi::ConstHitCount hit_count {parameters.dev_scifi_hit_count, event_number};

  __shared__ uint32_t shared_mat_offsets[SciFi::Constants::n_mats_without_group];
  __shared__ uint32_t shared_mat_count[SciFi::Constants::n_mats_without_group];
  for (unsigned i = threadIdx.x; i < SciFi::Constants::n_mats_without_group; i += blockDim.x) {
    shared_mat_offsets[i] = hit_count.mat_offsets(
      i + SciFi::Constants::n_consecutive_raw_banks * SciFi::Constants::n_mats_per_consec_raw_bank);
    shared_mat_count[i] = 0;
  }

  __syncthreads();

  // Main execution loop
  for (unsigned i = SciFi::Constants::n_consecutive_raw_banks + threadIdx.x; i < event.number_of_raw_banks;
       i += blockDim.x) {
    auto rawbank = event.getSciFiRawBank(i);
    pre_decode_raw_bank_v4(
      hit_count,
      geom,
      rawbank,
      i,
      (const uint32_t*) &shared_mat_offsets,
      (uint32_t*) &shared_mat_count,
      parameters.dev_cluster_references);
  }
}

__global__ void scifi_pre_decode_v4::scifi_pre_decode_v4_mep(
  scifi_pre_decode_v4::Parameters parameters,
  const char* scifi_geometry)
{
  const unsigned event_number = blockIdx.x;
  const unsigned selected_event_number = parameters.dev_event_list[event_number];

  SciFiGeometry geom(scifi_geometry);
  SciFi::ConstHitCount hit_count {parameters.dev_scifi_hit_count, event_number};

  __shared__ uint32_t shared_mat_offsets[SciFi::Constants::n_mats_without_group];
  __shared__ uint32_t shared_mat_count[SciFi::Constants::n_mats_without_group];
  for (unsigned i = threadIdx.x; i < SciFi::Constants::n_mats_without_group; i += blockDim.x) {
    shared_mat_offsets[i] = hit_count.mat_offsets(
      i + SciFi::Constants::n_consecutive_raw_banks * SciFi::Constants::n_mats_per_consec_raw_bank);
    shared_mat_count[i] = 0;
  }

  __syncthreads();

  auto const n_scifi_banks = parameters.dev_scifi_raw_input_offsets[0];

  // Main execution loop
  for (unsigned i = SciFi::Constants::n_consecutive_raw_banks + threadIdx.x; i < n_scifi_banks; i += blockDim.x) {

    // Create SciFi raw bank from MEP layout
    auto const raw_bank = MEP::raw_bank<SciFiRawBank>(
      parameters.dev_scifi_raw_input, parameters.dev_scifi_raw_input_offsets, selected_event_number, i);
    pre_decode_raw_bank_v4(
      hit_count,
      geom,
      raw_bank,
      i,
      (const uint32_t*) &shared_mat_offsets,
      (uint32_t*) &shared_mat_count,
      parameters.dev_cluster_references);
  }
}

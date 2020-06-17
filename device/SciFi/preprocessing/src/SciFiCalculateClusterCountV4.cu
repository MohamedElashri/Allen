#include <MEPTools.h>
#include <SciFiCalculateClusterCountV4.cuh>

void scifi_calculate_cluster_count_v4::scifi_calculate_cluster_count_v4_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_scifi_hit_count_t>(
    arguments, first<host_number_of_selected_events_t>(arguments) * SciFi::Constants::n_mat_groups_and_mats);
}

void scifi_calculate_cluster_count_v4::scifi_calculate_cluster_count_v4_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  initialize<dev_scifi_hit_count_t>(arguments, 0, cuda_stream);

  if (runtime_options.mep_layout) {
    global_function(scifi_calculate_cluster_count_v4_mep)(
      dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
      arguments, constants.dev_scifi_geometry);
  }
  else {
    global_function(scifi_calculate_cluster_count_v4)(
      dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
      arguments, constants.dev_scifi_geometry);
  }
}

using namespace SciFi;

/**
 * @brief This function calculates the amount of clusters in all mats.
 * @details More details about the SciFi format:
 *          https://cds.cern.ch/record/2630154/files/LHCb-INT-2018-024.pdf
 *
 * Kernel for decoding from MEP layout
 */
__global__ void scifi_calculate_cluster_count_v4::scifi_calculate_cluster_count_v4(
  scifi_calculate_cluster_count_v4::Parameters parameters,
  const char* scifi_geometry)
{
  const unsigned event_number = blockIdx.x;
  const unsigned selected_event_number = parameters.dev_event_list[event_number];

  const SciFiRawEvent event(
    parameters.dev_scifi_raw_input + parameters.dev_scifi_raw_input_offsets[selected_event_number]);
  const SciFiGeometry geom(scifi_geometry);
  SciFi::HitCount hit_count {parameters.dev_scifi_hit_count, event_number};

  for (unsigned i = threadIdx.x; i < SciFi::Constants::n_consecutive_raw_banks; i += blockDim.x) {
    const unsigned current_raw_bank = getRawBankIndexOrderedByX(i);
    const auto rawbank = event.getSciFiRawBank(current_raw_bank);
    uint16_t* it = rawbank.data + 2;
    uint16_t* last = rawbank.last;

    if (*(last - 1) == 0) --last; // Remove padding at the end
    const unsigned number_of_clusters = last - it;

    if (last > it) {
      hit_count.set_mat_offsets(i, number_of_clusters);
    }
  }

  const unsigned mats_difference = 3 * SciFi::Constants::n_consecutive_raw_banks;
  for (unsigned i = SciFi::Constants::n_consecutive_raw_banks + threadIdx.x; i < event.number_of_raw_banks;
       i += blockDim.x) {
    uint32_t* hits_mat;
    const auto rawbank = event.getSciFiRawBank(i);
    uint16_t* it = rawbank.data + 2;
    uint16_t* last = rawbank.last;

    // For details see RawBankDecoder
    if (*(last - 1) == 0) --last; // Remove padding at the end
    for (; it < last; ++it) {     // loop over the clusters
      uint16_t c = *it;
      uint32_t ch = geom.bank_first_channel[rawbank.sourceID] + channelInBank(c);
      hits_mat = hit_count.mat_offsets_p(SciFiChannelID(ch).correctedUniqueMat() - mats_difference);
      atomicAdd(hits_mat, 1);
    }
  }
}

/**
 * @brief This function calculates the amount of clusters in all mats.
 * @details More details about the SciFi format:
 *          https://cds.cern.ch/record/2630154/files/LHCb-INT-2018-024.pdf
 *
 * Kernel for decoding from MEP layout
 */
__global__ void scifi_calculate_cluster_count_v4::scifi_calculate_cluster_count_v4_mep(
  scifi_calculate_cluster_count_v4::Parameters parameters,
  const char* scifi_geometry)
{
  const unsigned event_number = blockIdx.x;
  const unsigned selected_event_number = parameters.dev_event_list[event_number];

  const SciFiGeometry geom(scifi_geometry);
  SciFi::HitCount hit_count {parameters.dev_scifi_hit_count, event_number};

  auto const n_scifi_banks = MEP::number_of_banks(parameters.dev_scifi_raw_input_offsets);

  for (unsigned i = threadIdx.x; i < SciFi::Constants::n_consecutive_raw_banks; i += blockDim.x) {
    const unsigned current_raw_bank = getRawBankIndexOrderedByX(i);

    // Create SciFi raw bank from MEP layout
    auto const raw_bank = MEP::raw_bank<SciFiRawBank>(
      parameters.dev_scifi_raw_input, parameters.dev_scifi_raw_input_offsets, selected_event_number, current_raw_bank);

    uint16_t* it = raw_bank.data + 2;
    uint16_t* last = raw_bank.last;

    if (*(last - 1) == 0) --last; // Remove padding at the end
    const unsigned number_of_clusters = last - it;

    if (last > it) {
      hit_count.set_mat_offsets(i, number_of_clusters);
    }
  }

  uint32_t* hits_mat = nullptr;

  const unsigned mats_difference = 3 * SciFi::Constants::n_consecutive_raw_banks;
  for (unsigned i = SciFi::Constants::n_consecutive_raw_banks + threadIdx.x; i < n_scifi_banks; i += blockDim.x) {

    // Create SciFi raw bank from MEP layout
    auto const raw_bank = MEP::raw_bank<SciFiRawBank>(
      parameters.dev_scifi_raw_input, parameters.dev_scifi_raw_input_offsets, selected_event_number, i);

    uint16_t* it = raw_bank.data + 2;
    uint16_t* last = raw_bank.last;

    // For details see RawBankDecoder
    if (*(last - 1) == 0) --last; // Remove phadding at the end
    for (; it < last; ++it) {     // loop over the clusters
      uint16_t c = *it;
      uint32_t ch = geom.bank_first_channel[raw_bank.sourceID] + channelInBank(c);
      hits_mat = hit_count.mat_offsets_p(SciFiChannelID(ch).correctedUniqueMat() - mats_difference);
      atomicAdd(hits_mat, 1);
    }
  }
}

#include <MEPTools.cuh>
#include <GlobalEventCut.cuh>

__global__ void global_event_cut(
  char* ut_raw_input,
  uint* ut_raw_input_offsets,
  char* scifi_raw_input,
  uint* scifi_raw_input_offsets,
  uint* number_of_selected_events,
  uint* event_list)
{
  const uint event_number = blockIdx.x;

  // Check SciFi clusters
  const SciFi::SciFiRawEvent scifi_event(scifi_raw_input + scifi_raw_input_offsets[event_number]);
  __shared__ uint n_SciFi_clusters;
  if (threadIdx.x == 0) n_SciFi_clusters = 0;
  __syncthreads();
  for (uint i = threadIdx.x; i < scifi_event.number_of_raw_banks; i += blockDim.x) {
    // get bank size in bytes, subtract four bytes for header word
    uint bank_size = scifi_event.raw_bank_offset[i + 1] - scifi_event.raw_bank_offset[i] - 4;
    atomicAdd(&n_SciFi_clusters, bank_size);
  }
  __syncthreads();
  // Bank size is given in bytes. There are 2 bytes per cluster.
  // 4 bytes are removed for the header.
  // Note that this overestimates slightly the number of clusters
  // due to bank padding in 32b. For v5, it further overestimates the
  // number of clusters due to the merging of clusters.
  if (threadIdx.x == 0) n_SciFi_clusters = n_SciFi_clusters / 2 - 2;
  __syncthreads();

  // if (n_SciFi_clusters >= max_scifi_ut_clusters || n_SciFi_clusters < min_scifi_ut_clusters) return;

  // Check UT clusters
  const uint32_t ut_event_offset = ut_raw_input_offsets[event_number];
  const UTRawEvent ut_event(ut_raw_input + ut_event_offset);
  __shared__ uint n_UT_clusters;
  if (threadIdx.x == 0) n_UT_clusters = 0;
  __syncthreads();
  for (uint i = threadIdx.x; i < ut_event.number_of_raw_banks; i += blockDim.x) {
    const UTRawBank ut_bank = ut_event.getUTRawBank(i);
    const int n_UT_clusters_before = atomicAdd(&n_UT_clusters, ut_bank.number_of_hits);
    // if (n_UT_clusters_before + ut_bank.number_of_hits >= max_scifi_ut_clusters) return;
  }
  __syncthreads();

  const auto num_combined_clusters = n_UT_clusters + n_SciFi_clusters;

  if (num_combined_clusters >= max_scifi_ut_clusters) return;
  // if (num_combined_clusters < min_scifi_ut_clusters) return;

  // passed cut
  if (threadIdx.x == 0) {
    const int selected_event = atomicAdd(number_of_selected_events, 1);
    event_list[selected_event] = event_number;
  }
}

__global__ void global_event_cut_mep(
  char* ut_raw_input,
  uint* ut_raw_input_offsets,
  char*,
  uint* scifi_raw_input_offsets,
  uint* number_of_selected_events,
  uint* event_list)
{
  const uint event_number = blockIdx.x;

  // Check SciFi clusters
  __shared__ uint n_SciFi_clusters;
  if (threadIdx.x == 0) n_SciFi_clusters = 0;
  __syncthreads();

  auto const number_of_scifi_raw_banks = scifi_raw_input_offsets[0];

  for (uint i = threadIdx.x; i < number_of_scifi_raw_banks; i += blockDim.x) {
    // get bank size in bytes, subtract four bytes for header word
    uint const offset_index = 2 + number_of_scifi_raw_banks * (1 + event_number);
    uint bank_size = scifi_raw_input_offsets[offset_index + i + 1] - scifi_raw_input_offsets[offset_index + i];
    atomicAdd(&n_SciFi_clusters, bank_size);
  }
  __syncthreads();
  // Bank size is given in bytes. There are 2 bytes per cluster.
  // 4 bytes are removed for the header.
  // Note that this overestimates slightly the number of clusters
  // due to bank padding in 32b. For v5, it further overestimates the
  // number of clusters due to the merging of clusters.
  if (threadIdx.x == 0) n_SciFi_clusters = n_SciFi_clusters / 2 - 2;
  __syncthreads();

  // if (n_SciFi_clusters >= max_scifi_ut_clusters || n_SciFi_clusters < min_scifi_ut_clusters) return;

  // Check UT clusters
  auto const number_of_ut_raw_banks = ut_raw_input_offsets[0];

  __shared__ uint n_UT_clusters;
  if (threadIdx.x == 0) n_UT_clusters = 0;
  __syncthreads();
  for (uint i = threadIdx.x; i < number_of_ut_raw_banks; i += blockDim.x) {
    // Build UT raw bank from MEP layout
    const auto ut_bank = MEP::raw_bank<UTRawBank>(ut_raw_input, ut_raw_input_offsets,
                                                  event_number, i);
    const int n_UT_clusters_before = atomicAdd(&n_UT_clusters, ut_bank.number_of_hits);
    // if (n_UT_clusters_before + ut_bank.number_of_hits >= max_scifi_ut_clusters) return;
  }
  __syncthreads();

  const auto num_combined_clusters = n_UT_clusters + n_SciFi_clusters;

  if (num_combined_clusters >= max_scifi_ut_clusters) return;
  // if (num_combined_clusters < min_scifi_ut_clusters) return;

  // passed cut
  if (threadIdx.x == 0) {
    const int selected_event = atomicAdd(number_of_selected_events, 1);
    event_list[selected_event] = event_number;
  }
}

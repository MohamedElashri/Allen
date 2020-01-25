#include <MEPTools.h>
#include <VeloCalculateNumberOfCandidates.cuh>

__global__ void velo_calculate_number_of_candidates::velo_calculate_number_of_candidates(
  velo_calculate_number_of_candidates::Parameters parameters,
  const uint number_of_events)
{
  for (auto event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    const auto selected_event_number = parameters.dev_event_list[event_number];
    const char* raw_input = parameters.dev_velo_raw_input + parameters.dev_velo_raw_input_offsets[selected_event_number];

    // Read raw event
    const auto raw_event = VeloRawEvent(raw_input);

    uint number_of_candidates = 0;
    for (uint raw_bank_number = 0; raw_bank_number < raw_event.number_of_raw_banks; ++raw_bank_number) {
      // Read raw bank
      const auto raw_bank = VeloRawBank(raw_event.payload + raw_event.raw_bank_offset[raw_bank_number]);
      number_of_candidates += raw_bank.sp_count;
    }

    // The maximum number of candidates is two times the number of SPs
    parameters.dev_number_of_candidates[event_number] = 2 * number_of_candidates;
  }
}

__global__ void velo_calculate_number_of_candidates::velo_calculate_number_of_candidates_mep(
  velo_calculate_number_of_candidates::Parameters parameters,
  const uint number_of_events)
{
  for (auto event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    const uint selected_event_number = parameters.dev_event_list[event_number];
    auto const number_of_raw_banks = parameters.dev_velo_raw_input_offsets[0];

    uint number_of_candidates = 0;
    for (uint raw_bank_number = 0; raw_bank_number < number_of_raw_banks; ++raw_bank_number) {
      // Create raw bank from MEP layout
      const auto raw_bank = MEP::raw_bank<VeloRawBank>(
        parameters.dev_velo_raw_input, parameters.dev_velo_raw_input_offsets, selected_event_number, raw_bank_number);
      number_of_candidates += raw_bank.sp_count;
    }

    parameters.dev_number_of_candidates[event_number] = 2 * number_of_candidates;
  }
}

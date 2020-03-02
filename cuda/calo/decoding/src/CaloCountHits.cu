#include <MEPTools.h>
#include <CaloCountHits.cuh>

__global__ void calo_count_hits::calo_count_hits(
  calo_count_hits::Parameters parameters,
  const uint number_of_events)
{
  for (auto event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    const auto selected_event_number = parameters.dev_event_list[event_number];
    const char* raw_input = parameters.dev_ecal_raw_input + parameters.dev_ecal_raw_input_offsets[selected_event_number];

    // Read raw event
    auto raw_event = CaloRawEvent(raw_input);

    auto raw_bank = CaloRawBank();
    for (uint raw_bank_number = 0; raw_bank_number < ECAL_BANKS; ++raw_bank_number) {
      // Read raw bank
      const auto raw_bank = CaloRawBank(raw_event.payload + raw_event.raw_bank_offset[raw_bank_number]);
      parameters.dev_ecal_number_of_hits[event_number * ECAL_BANKS + raw_bank.source_id] = raw_bank.adc_size;
    }

    raw_input = parameters.dev_hcal_raw_input + parameters.dev_hcal_raw_input_offsets[selected_event_number];

    // Read raw event
    raw_event = CaloRawEvent(raw_input);

    for (uint raw_bank_number = 0; raw_bank_number < raw_event.number_of_raw_banks; ++raw_bank_number) {
      // Read raw bank
      raw_bank = CaloRawBank(raw_event.payload + raw_event.raw_bank_offset[raw_bank_number]);
      parameters.dev_ecal_number_of_hits[event_number * HCAL_BANKS + raw_bank.source_id] = raw_bank.adc_size;
    }
  }
}

__global__ void calo_count_hits::calo_count_hits_mep(
  calo_count_hits::Parameters parameters,
  const uint number_of_events)
{
  printf("Hi I am event %d of %d\n", blockIdx.x * blockDim.x + threadIdx.x, number_of_events);
  // Ecal
  for (auto event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    const uint selected_event_number = parameters.dev_event_list[event_number];
    auto const number_of_ecal_raw_banks = parameters.dev_ecal_raw_input_offsets[0];

    auto raw_bank = CaloRawBank();
    for (uint raw_bank_number = 0; raw_bank_number < number_of_ecal_raw_banks; ++raw_bank_number) {
      // Create raw bank from MEP layout
      raw_bank = MEP::raw_bank<CaloRawBank>(parameters.dev_ecal_raw_input,
        parameters.dev_ecal_raw_input_offsets, selected_event_number, raw_bank_number);
      parameters.dev_ecal_number_of_hits[event_number * number_of_ecal_raw_banks
        + raw_bank.source_id] = raw_bank.adc_size;
    }

    // Hcal
    auto const number_of_hcal_raw_banks = parameters.dev_ecal_raw_input_offsets[0];

    for (uint raw_bank_number = 0; raw_bank_number < number_of_hcal_raw_banks; ++raw_bank_number) {
      // Create raw bank from MEP layout
      raw_bank = MEP::raw_bank<CaloRawBank>(parameters.dev_hcal_raw_input,
        parameters.dev_hcal_raw_input_offsets, selected_event_number, raw_bank_number);
      parameters.dev_hcal_number_of_hits[event_number * number_of_hcal_raw_banks
        + raw_bank.source_id] = raw_bank.adc_size;
    }

  }
}

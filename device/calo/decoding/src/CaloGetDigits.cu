#include <MEPTools.h>
#include <CaloGetDigits.cuh>

// TODO thinks about blocks/threads etc. 1 block per fragment might be best for coalesced memory acces.

__global__ void calo_get_digits::calo_get_digits(
  calo_get_digits::Parameters parameters,
  const uint number_of_events,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry)
{
  const uint16_t coding_numbers[6] = {0xF, 8, 4, // 4-bit coding values.
                                      0xFFF, 256, 12 // 12-bit coding values.
                                     };

  // Get proper geometry.
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  auto hcal_geometry = CaloGeometry(raw_hcal_geometry);

  for (auto event_number = blockIdx.x * blockDim.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {

    const auto selected_event_number = parameters.dev_event_list[event_number];

    // Ecal
    const char* raw_input = parameters.dev_ecal_raw_input + parameters.dev_ecal_raw_input_offsets[selected_event_number];
    // Read raw event
    auto raw_event = CaloRawEvent(raw_input);
    auto raw_bank = CaloRawBank();
    for (auto bank_number = threadIdx.x; bank_number < ECAL_BANKS; bank_number += blockDim.x) {
      raw_bank.data = (uint32_t*) (raw_event.payload + raw_event.raw_bank_offset[bank_number]);
      int length = 1; // To skip the source ID.
      int card = 0;
      // Loop over all cards in this raw bank.
      while ((char*) (raw_bank.data + length) != raw_event.payload + raw_event.raw_bank_offset[bank_number + 1]) {
        raw_bank.update(length);
        uint64_t cur_data = ((uint64_t) raw_bank.data[1] << 32) + raw_bank.data[0]; // Use 64 bit integers in case of 12 bits coding at border regions.
        int offset = 0;
        int item = 0; // Have to use an item count instead of pointer because of "misaligned address" bug.
        for (auto hit = 0; hit < CARD_CHANNELS; hit++) {
          if (offset > 31) {
            offset -= 32;
            item++;
            cur_data = ((uint64_t) raw_bank.data[item + 1] << 32) + raw_bank.data[item];
          }
          uint16_t adc = 0;
          int coding = (raw_bank.pattern >> hit) & 0x1;
          
          // Retrieve adc.
          adc = ((cur_data >> offset) & coding_numbers[coding * 3]) - coding_numbers[coding * 3 + 1]; // TODO ask if this - is necessary as it results in negative adc.
          offset += coding_numbers[coding * 3 + 2];
          
          // Store cellid and adc in result array.
          uint16_t cellid = ecal_geometry.channels[(raw_bank.code - ecal_geometry.code_offset) * CARD_CHANNELS + hit];

          // Some cell IDs have an area of 3 without any neighbors etc. ignore these.
          if ((cellid >> 12) <= 2) {
            parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + cellid].adc = adc;
            parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + cellid].clustered_at_iteration = UNCLUSTERED;
          }

          // Determine where the next card will start.
          length = (raw_bank.get_length() + 31) / 32;
          card++;
        }
      }
    }

    // Hcal
    raw_input = parameters.dev_hcal_raw_input + parameters.dev_hcal_raw_input_offsets[selected_event_number];
    // Read raw event
    raw_event = CaloRawEvent(raw_input);
    raw_bank = CaloRawBank();
    for (auto bank_number = threadIdx.x; bank_number < HCAL_BANKS; bank_number += blockDim.x) {
      raw_bank.data = (uint32_t*) (raw_event.payload + raw_event.raw_bank_offset[bank_number]);
      int length = 1; // To skip the source ID.
      int card = 0;
      // Loop over all cards in this raw bank.
      while ((char*) (raw_bank.data + length) != raw_event.payload + raw_event.raw_bank_offset[bank_number + 1]) {
        raw_bank.update(length);
        uint64_t cur_data = ((uint64_t) raw_bank.data[1] << 32) + raw_bank.data[0]; // Use 64 bit integers in case of 12 bits coding at border regions.
        int offset = 0;
        int item = 0; // Have to use an item count instead of pointer because of "misaligned address" bug.
        for (auto hit = 0; hit < CARD_CHANNELS; hit++) {
          if (offset > 31) {
            offset -= 32;
            item++;
            cur_data = ((uint64_t) raw_bank.data[item + 1] << 32) + raw_bank.data[item];
          }
          uint16_t adc = 0;
          int coding = (raw_bank.pattern >> hit) & 0x1;
          
          // Retrieve adc.
          adc = ((cur_data >> offset) & coding_numbers[coding * 3]) - coding_numbers[coding * 3 + 1]; // TODO ask if this - is necessary as it results in negative adc. 
          offset += coding_numbers[coding * 3 + 2];
          
          // Store cellid and adc in result array.
          uint16_t cellid = hcal_geometry.channels[(raw_bank.code - hcal_geometry.code_offset) * CARD_CHANNELS + hit];

          // Some cell IDs have an area of 3 without any neighbors etc. ignore these.
          if ((cellid >> 12) <= 1) {
            parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + cellid].adc = adc;
            parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + cellid].clustered_at_iteration = UNCLUSTERED;
          }

          // Determine where the next card will start.
          length = (raw_bank.get_length() + 31) / 32;
          card++;
        }
      }
    }
  }
}

__global__ void calo_get_digits::calo_get_digits_mep(
  calo_get_digits::Parameters parameters,
  const uint number_of_events,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry)
{
  const uint16_t coding_numbers[6] = {0xF, 8, 4, // 4-bit coding values.
                                      0xFFF, 256, 12 // 12-bit coding values.
                                     };

  // Get proper geometry.
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  auto hcal_geometry = CaloGeometry(raw_hcal_geometry);

  for (auto event_number = blockIdx.x * blockDim.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    
    const auto selected_event_number = parameters.dev_event_list[event_number];

    // Ecal
    auto raw_bank = CaloRawBank();
    for (auto bank_number = threadIdx.x; bank_number < ECAL_BANKS; bank_number += blockDim.x) {
      raw_bank.data = (uint32_t*) (parameters.dev_ecal_raw_input +
        parameters.dev_ecal_raw_input_offsets[MEP::offset_index(ECAL_BANKS, selected_event_number, bank_number)]);
      int length = 0;
      int card = 0;
      // Loop over all cards in this raw bank.
      while ((char*) (raw_bank.data + length) !=
             parameters.dev_ecal_raw_input + parameters.dev_ecal_raw_input_offsets[
             MEP::offset_index(ECAL_BANKS, selected_event_number + 1, bank_number)]) {
        raw_bank.update(length);
        uint64_t cur_data = ((uint64_t) raw_bank.data[1] << 32) + raw_bank.data[0]; // Use 64 bit integers in case of 12 bits coding at border regions.
        int offset = 0;
        int item = 0; // Have to use an item count instead of pointer because of "misaligned address" bug.
        for (auto hit = 0; hit < CARD_CHANNELS; hit++) {
          if (offset > 31) {
            offset -= 32;
            item++;
            cur_data = ((uint64_t) raw_bank.data[item + 1] << 32) + raw_bank.data[item];
          }
          uint16_t adc = 0;
          int coding = (raw_bank.pattern >> hit) & 0x1;
          
          // Retrieve adc.
          adc = ((cur_data >> offset) & coding_numbers[coding * 3]) - coding_numbers[coding * 3 + 1]; // TODO ask if this - is necessary as it results in negative adc. 
          offset += coding_numbers[coding * 3 + 2];
          
          // Store cellid and adc in result array.
          uint16_t cellid = ecal_geometry.channels[(raw_bank.code - ecal_geometry.code_offset) * CARD_CHANNELS + hit];

          // Some cell IDs have an area of 3 without any neighbors etc. ignore these.
          if ((cellid >> 12) <= 2) {
            parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + cellid].adc = adc;
            parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + cellid].clustered_at_iteration = UNCLUSTERED;
          }

          // Determine where the next card will start.
          length = (raw_bank.get_length() + 31) / 32;
          card++;
        }
      }
    }

    // Hcal
    // Read raw event
    raw_bank = CaloRawBank();
    for (auto bank_number = threadIdx.x; bank_number < HCAL_BANKS; bank_number += blockDim.x) {
      raw_bank.data = (uint32_t*) (parameters.dev_hcal_raw_input +
        parameters.dev_hcal_raw_input_offsets[MEP::offset_index(HCAL_BANKS, selected_event_number, bank_number)]);
      int length = 0;
      int card = 0;
      // Loop over all cards in this raw bank.
      while ((char*) (raw_bank.data + length) !=
             parameters.dev_hcal_raw_input + parameters.dev_hcal_raw_input_offsets[
             MEP::offset_index(HCAL_BANKS, selected_event_number + 1, bank_number)]) {
        raw_bank.update(length);
        uint64_t cur_data = ((uint64_t) raw_bank.data[1] << 32) + raw_bank.data[0]; // Use 64 bit integers in case of 12 bits coding at border regions.
        int offset = 0;
        int item = 0; // Have to use an item count instead of pointer because of "misaligned address" bug.
        for (auto hit = 0; hit < CARD_CHANNELS; hit++) {
          if (offset > 31) {
            offset -= 32;
            item++;
            cur_data = ((uint64_t) raw_bank.data[item + 1] << 32) + raw_bank.data[item];
          }
          uint16_t adc = 0;
          int coding = (raw_bank.pattern >> hit) & 0x1;

          // Retrieve adc.
          adc = ((cur_data >> offset) & coding_numbers[coding * 3]) - coding_numbers[coding * 3 + 1]; // TODO ask if this - is necessary as it results in negative adc. 
          offset += coding_numbers[coding * 3 + 2];

          // Store cellid and adc in result array.
          uint16_t cellid = hcal_geometry.channels[(raw_bank.code - hcal_geometry.code_offset) * CARD_CHANNELS + hit];

          // Some cell IDs have an area of 3 without any neighbors etc. ignore these.
          if ((cellid >> 12) <= 1) {
            parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + cellid].adc = adc;
            parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + cellid].clustered_at_iteration = UNCLUSTERED;
          }

          // Determine where the next card will start.
          length = (raw_bank.get_length() + 31) / 32;
          card++;
        }
      }
    }
  }
}

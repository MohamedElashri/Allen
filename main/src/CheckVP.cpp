/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <iostream>

#include "Tools.h"

bool check_velopix_events(const std::vector<char>& events, const std::vector<unsigned>& event_offsets, size_t n_events)
{
  int error_count = 0;
  for (size_t i_event = 0; i_event < n_events; ++i_event) {
    const char* raw_input = events.data() + event_offsets[i_event];

    const char* p = events.data() + event_offsets[i_event];
    uint32_t number_of_raw_banks = *((uint32_t*) p);
    p += sizeof(uint32_t);
    [[maybe_unused]] uint32_t* raw_bank_offset = (uint32_t*) p;
    p += number_of_raw_banks * sizeof(uint32_t);

    [[maybe_unused]] uint32_t sensor = *((uint32_t*) p);
    p += sizeof(uint32_t);
    [[maybe_unused]] uint32_t sp_count = *((uint32_t*) p);
    p += sizeof(uint32_t);

    const auto raw_event = Velo::VeloRawEvent(raw_input);
    for (unsigned i_raw_bank = 0; i_raw_bank < raw_event.number_of_raw_banks(); i_raw_bank++) {
      const auto raw_bank = raw_event.raw_bank(i_raw_bank);
      if (i_raw_bank != raw_bank.sensor_index) {
        error_cout << "at raw bank " << i_raw_bank << ", but index = " << raw_bank.sensor_index << std::endl;
        ++error_count;
      }
      if (raw_bank.count > 0) {
        uint32_t sp_word = raw_bank.word[0];
        uint8_t sp = sp_word & 0xFFU;
        if (0 == sp) {
          continue;
        };
        [[maybe_unused]] const uint32_t sp_addr = (sp_word & 0x007FFF00U) >> 8;
        [[maybe_unused]] const uint32_t sp_row = sp_addr & 0x3FU;
        [[maybe_unused]] const uint32_t sp_col = (sp_addr >> 6);
        [[maybe_unused]] const uint32_t no_sp_neighbours = sp_word & 0x80000000U;
      }
    }
  }

  if (error_count > 0) {
    error_cout << error_count << " errors detected." << std::endl;
    return false;
  }
  return true;
}

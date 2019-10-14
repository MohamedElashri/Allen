#pragma once

#include <Common.h>
#include <BankTypes.h>

void cpu_global_event_cut(
  char const* ut_raw_input,
  uint const* ut_raw_input_offsets,
  char const* scifi_raw_input,
  uint const* scifi_raw_input_offsets,
  uint* number_of_selected_events,
  uint* event_list,
  uint number_of_events);

void cpu_global_event_cut_mep(
  BanksAndOffsets const& ut_raw,
  BanksAndOffsets const& scifi_raw,
  uint* number_of_selected_events,
  uint* event_list,
  uint number_of_events);

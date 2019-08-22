#pragma once

#include "Common.h"
#include "Handler.cuh"
#include "SciFiRaw.cuh"
#include "UTRaw.cuh"
#include "ArgumentsCommon.cuh"
#include "GlobalEventCutConfiguration.cuh"

void cpu_global_event_cut(
  char const* ut_raw_input,
  uint const* ut_raw_input_offsets,
  char const* scifi_raw_input,
  uint const* scifi_raw_input_offsets,
  uint* number_of_selected_events,
  uint* event_list,
  uint number_of_events);

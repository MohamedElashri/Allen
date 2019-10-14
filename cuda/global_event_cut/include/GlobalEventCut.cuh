#pragma once

#include "Common.h"
#include "Handler.cuh"
#include "SciFiRaw.cuh"
#include "UTRaw.cuh"
#include "ArgumentsCommon.cuh"
#include "GlobalEventCutConfiguration.cuh"

__global__ void global_event_cut(
  char* dev_ut_raw_input,
  uint* dev_ut_raw_input_offsets,
  char* dev_scifi_raw_input,
  uint* dev_scifi_raw_input_offsets,
  uint* number_of_selected_events,
  uint* event_list);

ALGORITHM(
  global_event_cut,
  global_event_cut_allen_t,
  ARGUMENTS(
    dev_ut_raw_input,
    dev_ut_raw_input_offsets,
    dev_scifi_raw_input,
    dev_scifi_raw_input_offsets,
    dev_number_of_selected_events,
    dev_event_list))

__global__ void global_event_cut_mep(
  char* ut_raw_input,
  uint* ut_raw_input_offsets,
  char*,
  uint* scifi_raw_input_offsets,
  uint* number_of_selected_events,
  uint* event_list);

ALGORITHM(
  global_event_cut_mep,
  global_event_cut_mep_t,
  ARGUMENTS(
    dev_ut_raw_input,
    dev_ut_raw_input_offsets,
    dev_scifi_raw_input,
    dev_scifi_raw_input_offsets,
    dev_number_of_selected_events,
    dev_event_list))

XOR_ALGORITHM(global_event_cut_mep_t,
              global_event_cut_allen_t,
              global_event_cut_t)

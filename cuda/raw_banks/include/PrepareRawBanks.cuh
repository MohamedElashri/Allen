#pragma once

#include "HltDecReport.cuh"
#include "RawBanksDefinitions.cuh"

#include "Handler.cuh"
#include "ArgumentsSelections.cuh"
#include "ArgumentsVertex.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsKalmanFilter.cuh"
#include "ArgumentsRawBanks.cuh"

__global__ void prepare_raw_banks(
  const uint* dev_atomics_scifi,
  const uint* dev_sv_atomics,
  const bool* dev_sel_results,
  const uint* dev_sel_results_atomics,
  uint32_t* dev_dec_reports,
  uint* number_of_passing_events,
  uint* event_list);

ALGORITHM(
  prepare_raw_banks,
  prepare_raw_banks_t,
  ARGUMENTS(
    dev_atomics_scifi,
    dev_sv_atomics,
    dev_sel_results,
    dev_sel_results_atomics,
    dev_dec_reports,
    dev_number_of_passing_events,
    dev_passing_event_list))

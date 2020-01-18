#pragma once

#include "HltDecReport.cuh"
#include "RawBanksDefinitions.cuh"

#include "Handler.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsSelections.cuh"
#include "ArgumentsVertex.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsKalmanFilter.cuh"
#include "ArgumentsRawBanks.cuh"

__global__ void prepare_raw_banks(
  const uint* dev_input_event_list,
  const uint* dev_atomics_scifi,
  const uint* dev_sv_offsets,
  const bool* dev_one_track_results,
  const bool* dev_two_track_results,
  const bool* dev_single_muon_results,
  const bool* dev_disp_dimuon_results,
  const bool* dev_high_mass_dimuon_results,
  const bool* dev_dimuon_soft_results,
  uint32_t* dev_dec_reports,
  uint* number_of_passing_events,
  uint* passing_event_list);

ALGORITHM(
  prepare_raw_banks,
  prepare_raw_banks_t,
  ARGUMENTS(
    dev_event_list,
    dev_atomics_scifi,
    dev_sv_offsets,
    dev_one_track_results,
    dev_two_track_results,
    dev_single_muon_results,
    dev_disp_dimuon_results,
    dev_high_mass_dimuon_results,
    dev_dimuon_soft_results,
    dev_dec_reports,
    dev_number_of_passing_events,
    dev_passing_event_list))

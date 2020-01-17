#pragma once

#include "HltSelReport.cuh"
#include "ParKalmanDefinitions.cuh"
#include "RawBanksDefinitions.cuh"
#include "ArgumentsRawBanks.cuh"
#include "ArgumentsSciFi.cuh"
#include "Handler.cuh"

__global__ void package_sel_reports(
  const uint* dev_atomics_scifi,
  uint32_t* dev_sel_rb_hits,
  uint32_t* dev_sel_rb_stdinfo,
  uint32_t* dev_sel_rb_objtyp,
  uint32_t* dev_sel_rb_substr,
  uint32_t* dev_sel_rep_raw_banks,
  uint* dev_sel_rep_offsets,
  uint* event_list,
  uint number_of_total_events);

ALGORITHM(
  package_sel_reports,
  package_sel_reps_t,
  ARGUMENTS(
    dev_atomics_scifi,
    dev_sel_rb_hits,
    dev_sel_rb_stdinfo,
    dev_sel_rb_objtyp,
    dev_sel_rb_substr,
    dev_sel_rep_raw_banks,
    dev_sel_rep_offsets,
    dev_passing_event_list))
#pragma once

#include "Common.h"

void checkHlt1Rate(
  const bool* one_track_decisions,
  const bool* two_track_decisions,
  const bool* single_muon_decisions,
  const bool* disp_dimuon_decisions,
  const bool* high_mass_dimuon_decisions,
  const int* track_atomics,
  const uint* sv_atomics,
  const uint selected_events,
  const uint requested_events);

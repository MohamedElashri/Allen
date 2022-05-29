/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdio>
#include "BackendCommon.h"

/**
 * @brief  ECAL Scan
 * @detail Loops over several z positions along the ECAL to
 *         find which cells are traversed by the track
 */
template<std::size_t SIZE>
__device__ void ecal_scan(
  const unsigned& N_ecal_positions,
  const float* ecal_positions,
  const MiniState& state,
  const CaloGeometry& ecal_geometry,
  bool& inAcc,
  const CaloDigit* digits,
  unsigned& N_matched_digits,
  float& sum_cell_E,
  std::array<unsigned, SIZE>& digit_indices)
{
  for (unsigned j = 0; j < N_ecal_positions; ++j) {
    // Extrapolate the track in a straight line to the current z position
    const float dz_temp = ecal_positions[j] - state.z;
    float xV_temp = state.x + state.tx * dz_temp;
    float yV_temp = state.y + state.ty * dz_temp;

    // Convert (x,y) coordinates to cell ID
    unsigned matched_digit_id = ecal_geometry.getEcalID(xV_temp, yV_temp, ecal_positions[j]);

    // If outside the ECAL acceptance, ignore and continue
    if (matched_digit_id == 9999 || !digits[matched_digit_id].is_valid()) continue;

    // Check ECAL acceptance at showermax (z=12650)
    if (j == 1) {
      inAcc = true;
    }

    // Convert matched calo digit ADC to energy
    float matched_energy = ecal_geometry.getE(matched_digit_id, digits[matched_digit_id].adc);

    // If matched enegy is negative, assume it's just noise, ignore and continue
    if (matched_energy < 0) continue;

    // Sum the energy of all DIFFERENT calo digits
    if (N_matched_digits == 0) {
      sum_cell_E += matched_energy;
      digit_indices[N_matched_digits] = matched_digit_id;
      N_matched_digits += 1;
    }
    else {
      bool different = true;

      for (unsigned k(0); k < N_matched_digits; ++k) {
        if (matched_digit_id == digit_indices[k]) {
          different = false;
        }
      }

      if (different) {
        sum_cell_E += matched_energy;
        digit_indices[N_matched_digits] = matched_digit_id;
        N_matched_digits += 1;
      }
    }
  }
}

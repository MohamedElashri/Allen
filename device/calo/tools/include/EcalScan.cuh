/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <cstdio>
#include "BackendCommon.h"
#include "CaloConstants.cuh"
#include "States.cuh"
#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"

template<typename T>
__device__ bool is_local_max(const CaloDigit* digits, T digit_idx, const CaloGeometry& geometry, float min_adc)
{
  const auto digit = digits[digit_idx];
  if (digit.adc < min_adc || !digit.is_valid()) return false;
  uint16_t* neighbors = &(geometry.neighbors[digit_idx * Calo::Constants::max_neighbours]);
  bool is_max = true;
  for (unsigned n = 0; n < Calo::Constants::max_neighbours; n++) {
    auto const neighbor_id = neighbors[n];
    if (neighbor_id == USHRT_MAX) continue;

    auto const neighbor_digit = digits[neighbors[n]];

    is_max &= (digit.adc > neighbor_digit.adc || !neighbor_digit.is_valid());
  }
  return is_max;
}
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
    const float dz_temp = ecal_positions[j] - state.z();
    float xV_temp = state.x() + state.tx() * dz_temp;
    float yV_temp = state.y() + state.ty() * dz_temp;

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

template<std::size_t SIZE>
__device__ void ecal_scan_local_max(
  const unsigned& N_ecal_positions,
  const float* ecal_positions,
  const MiniState& state,
  const CaloGeometry& ecal_geometry,
  bool& inAcc,
  const CaloDigit* digits,
  unsigned& N_matched_digits,
  float& sum_cell_E,
  std::array<unsigned, SIZE>& digit_indices,
  bool& localmax)
{
  for (unsigned j = 0; j < N_ecal_positions; ++j) {
    // Extrapolate the track in a straight line to the current z position
    const float dz_temp = ecal_positions[j] - state.z();
    float xV_temp = state.x() + state.tx() * dz_temp;
    float yV_temp = state.y() + state.ty() * dz_temp;

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
      localmax |= is_local_max(digits, matched_digit_id, ecal_geometry, 0);
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
        localmax |= is_local_max(digits, matched_digit_id, ecal_geometry, 0);
      }
    }
  }
}

__device__ void inline cluster_shape_scan(
  const unsigned& N_ecal_positions,
  const float* ecal_positions,
  const MiniState& state,
  const CaloGeometry& ecal_geometry,
  bool& inAcc,
  const CaloDigit* digits,
  float& sum_cell_E,
  float& xbar,
  float& ybar,
  float& xdispersion,
  float& ydispersion,
  float& xydispersion,
  float& ecal_z,
  int& region)
{
  float max_energy = -9999.f;
  int max_idx = -1;
  for (unsigned j = 0; j < N_ecal_positions; ++j) {
    // Extrapolate the track in a straight line to the current z position
    const float dz_temp = ecal_positions[j] - state.z();
    float xV_temp = state.x() + state.tx() * dz_temp;
    float yV_temp = state.y() + state.ty() * dz_temp;

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
    if (matched_energy > max_energy || max_idx < 0) {
      max_energy = matched_energy;
      max_idx = matched_digit_id;
      ecal_z = ecal_positions[j];
    }
  }
  if (max_idx < 0) return;
  float matched_x = ecal_geometry.getX(max_idx);
  float matched_y = ecal_geometry.getY(max_idx);
  region = ecal_geometry.getECALArea(max_idx);
  sum_cell_E += max_energy;
  xbar += matched_x * max_energy;
  ybar += matched_y * max_energy;
  xdispersion += matched_x * matched_x * max_energy;
  ydispersion += matched_y * matched_y * max_energy;
  xydispersion += matched_x * matched_y * max_energy;
  uint16_t* neighbors = &(ecal_geometry.neighbors[max_idx * Calo::Constants::max_neighbours]);
  for (unsigned neighbor_i = 0; neighbor_i < Calo::Constants::max_neighbours; neighbor_i++) {
    auto neighbor_idx = neighbors[neighbor_i];
    if (neighbor_idx == USHRT_MAX || !digits[neighbor_idx].is_valid()) continue;
    float matched_energy = ecal_geometry.getE(neighbor_idx, digits[neighbor_idx].adc);
    if (matched_energy < 0) continue;
    float matched_x = ecal_geometry.getX(neighbor_idx);
    float matched_y = ecal_geometry.getY(neighbor_idx);
    sum_cell_E += matched_energy;
    xbar += matched_x * matched_energy;
    ybar += matched_y * matched_energy;
    xdispersion += matched_x * matched_x * matched_energy;
    ydispersion += matched_y * matched_y * matched_energy;
    xydispersion += matched_x * matched_y * matched_energy;
  }
  xbar /= sum_cell_E;
  ybar /= sum_cell_E;
  xdispersion = xdispersion / sum_cell_E - xbar * xbar;
  ydispersion = ydispersion / sum_cell_E - ybar * ybar;
  xydispersion = xydispersion / sum_cell_E - xbar * ybar;
}

/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <array>
#include <cstdint>
#include <algorithm>
#include <numeric>
#include <gsl/gsl>
#include <chrono>
#include "BackendCommon.h"
#include "Logger.h"

__device__ inline int sector_unique_id(
  const uint32_t& side,
  const uint32_t& layer,
  const uint32_t& stave,
  const uint32_t& face,
  const uint32_t& module,
  const uint32_t& sector)
{
  // Start of function to get unique sector ID
  const auto m = (module << 1) | (1 - face);
  uint32_t st = 7 + (layer >> 1) - stave;
  if (side == 1) {
    st = stave;
  }
  uint32_t num_sectors_half_layer_a = 124;
  uint32_t num_sectors_half_layer_b = 138;
  uint32_t half_layer_unique = (layer << 1) | (side);
  uint32_t offset_half_layer = 0;
  if (half_layer_unique < 4) {
    offset_half_layer = half_layer_unique * num_sectors_half_layer_a;
  }
  else {
    offset_half_layer = 4 * num_sectors_half_layer_a + (half_layer_unique % 4) * num_sectors_half_layer_b;
  }
  constexpr auto nb_sectors_in_a_stave = 14;
  constexpr auto nb_sectors_in_stave_0 = 22;
  constexpr auto nb_sectors_in_stave_1 = 18;
  uint32_t nb_staves_outer_region = 6;
  if (layer > 1) {
    nb_staves_outer_region = 7;
  }
  int sec = -1;
  if (stave >= 2) {
    sec = m - (module / 4) * 2 + (1 - side) * st * nb_sectors_in_a_stave +
          side * (nb_sectors_in_stave_0 + nb_sectors_in_stave_1 + (stave - 2) * nb_sectors_in_a_stave);
  }
  else if (stave == 1) {
    const auto offset = (1 - side) * (nb_staves_outer_region * nb_sectors_in_a_stave) + side * nb_sectors_in_stave_0;
    sec = offset;
    if (m < 5) {
      sec += m;
    }
    else if (m >= 5 && m < 9) { // module==3&&face==0 and module==4&&face==1 do not exist for stave 1
      const auto base_module = m - 5;
      sec += 5 + base_module * 2 + sector;
    }
    else if (m >= 9 && m < 11) {
      const auto base_module = m - 9;
      sec += 9 + base_module * 2 + (1 - sector);
    }
    else {
      sec += 13 + (m - 11);
    }
  }
  else if (stave == 0) {
    const auto offset = (1 - side) * (nb_staves_outer_region * nb_sectors_in_a_stave + nb_sectors_in_stave_1);
    sec = offset;
    if (m < 5) {
      sec += m;
    }
    else if (m >= 5 && m < 8) {
      const auto base_module = m - 5;
      sec += 5 + base_module * 2 + sector;
    }
    else if (m >= 8 && m < 11) {
      const auto base_module = m - 8;
      sec += 11 + base_module * 2 + (1 - sector);
    }
    else if (m >= 11) {
      sec += 17 + (m - 11);
    }
  }
  sec += offset_half_layer;
  return sec;
  // End of function to get unique sector ID
}
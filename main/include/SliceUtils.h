/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <vector>
#include <array>

#include "Common.h"
#include "Logger.h"
#include "SystemOfUnits.h"
#include "TransposeTypes.h"

/**
 * @brief      Reset a slice
 *
 * @param      slices
 * @param      slice_index
 * @param      event_ids
 */
void reset_slice(
  Allen::Slices& slices,
  int const slice_index,
  std::unordered_set<BankTypes> const& bank_types,
  EventIDs& event_ids,
  bool mep = false);

Allen::Slices allocate_slices(
  size_t n_slices,
  std::unordered_set<BankTypes> const& bank_types,
  std::function<std::tuple<size_t, size_t, size_t>(BankTypes)> size_fun);

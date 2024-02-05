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

void free_slices(Allen::Slices& slices);

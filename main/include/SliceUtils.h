/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <vector>
#include <array>

#include <Common.h>
#include <Logger.h>
#include <SystemOfUnits.h>

#include "TransposeTypes.h"

/**
 * @brief      Reset a slice
 *
 * @param      slices
 * @param      slice_index
 * @param      event_ids
 */
template<BankTypes... Banks>
void reset_slice(Slices& slices, int const slice_index, EventIDs& event_ids, bool mep = false)
{
  // "Reset" the slice
  for (auto bank_type : {Banks...}) {
    auto ib = to_integral<BankTypes>(bank_type);
    auto& [banks, data_size, offsets, offsets_size] = slices[ib][slice_index];
    std::fill(offsets.begin(), offsets.end(), 0);
    offsets_size = 1;
    if (mep) {
      banks.clear();
      data_size = 0;
    }
  }
  event_ids.clear();
}

template<BankTypes... Banks>
Slices allocate_slices(size_t n_slices, std::function<std::tuple<size_t, size_t>(BankTypes)> size_fun)
{
  Slices slices;
  for (auto bank_type : {Banks...}) {
    auto [n_bytes, n_offsets] = size_fun(bank_type);

    auto ib = to_integral<BankTypes>(bank_type);
    auto& bank_slices = slices[ib];
    bank_slices.reserve(n_slices);
    for (size_t i = 0; i < n_slices; ++i) {
      char* events_mem = nullptr;
      unsigned* offsets_mem = nullptr;

      if (n_bytes) Allen::malloc_host((void**) &events_mem, n_bytes);
      if (n_offsets) Allen::malloc_host((void**) &offsets_mem, (n_offsets + 1) * sizeof(unsigned));

      for (size_t i = 0; i < n_offsets + 1; ++i) {
        offsets_mem[i] = 0;
      }
      std::vector<gsl::span<char>> spans {};
      if (n_bytes) {
        spans.emplace_back(events_mem, n_bytes);
      }
      bank_slices.emplace_back(
        std::move(spans), n_bytes, offsets_span {offsets_mem, static_cast<offsets_size>(n_offsets + 1)}, 1);
    }
  }
  return slices;
}

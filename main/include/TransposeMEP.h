#pragma once

#include <thread>
#include <vector>
#include <array>
#include <deque>
#include <mutex>
#include <atomic>
#include <chrono>
#include <algorithm>
#include <numeric>
#include <condition_variable>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <Common.h>
#include <Logger.h>
#include <SystemOfUnits.h>
#include <mdf_header.hpp>
#include <read_mdf.hpp>
#include <Event/RawBank.h>
#include <eb_header.hpp>
#include "TransposeTypes.h"

#ifndef NO_CUDA
#include <CudaCommon.h>
#endif

namespace {
  using namespace Allen::Units;
} // namespace

namespace MEP {

  using SourceOffsets = std::vector<std::vector<uint32_t>>;
  using Blocks = std::vector<std::tuple<EB::BlockHeader, gsl::span<char const>>>;
  using Slice = std::tuple<EB::Header, gsl::span<char const>, Blocks, SourceOffsets, size_t>;
  using Slices = std::vector<MEP::Slice>;

  /**
   * @brief      Fill the array the contains the number of banks per type
   *
   * @details    detailed description
   *
   * @param      EB::Header for a MEP
   * @param      span of the block data in the MEP
   *
   * @return     (success, number of banks per bank type; 0 if the bank is not needed)
   */
  std::tuple<bool, std::array<unsigned int, LHCb::NBankTypes>> fill_counts(
    EB::Header const& header,
    gsl::span<char const> const& data);

  void find_blocks(EB::Header const& mep_header, gsl::span<char const> const& buffer_span, Blocks& blocks);

  void fragment_offsets(Blocks const& blocks, std::vector<std::vector<uint32_t>>& offsets);

  size_t allen_offsets(
    ::Slices& slices,
    int const slice_index,
    std::vector<int> const& bank_ids,
    std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
    Blocks const& blocks,
    std::tuple<size_t, size_t> const& interval);

  std::tuple<bool, bool, size_t> mep_offsets(
    ::Slices& slices,
    int const slice_index,
    std::vector<int> const& bank_ids,
    std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
    EventIDs& event_ids,
    EB::Header const& mep_header,
    MEP::Blocks const& blocks,
    std::tuple<size_t, size_t> const& interval);

  /**
   * @brief      Transpose events to Allen layout
   *
   * @param      slices to fill with transposed banks, slices are addressed by bank type
   * @param      index of bank slices
   * @param      number of banks per event
   * @param      event ids of banks in this slice
   * @param      start of bank data for this event
   *
   * @return     tuple of: (success, slice is full)
   */
  bool transpose_event(
    ::Slices& slices,
    int const slice_index,
    std::vector<int> const& bank_ids,
    std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
    EventIDs& event_ids,
    EB::Header const& mep_header,
    Blocks const& blocks,
    SourceOffsets const& input_offsets,
    std::tuple<size_t, size_t> const& interval);

  /**
   * @brief      Transpose MEP to Allen layout
   *
   * @param      slices to fill with transposed banks, slices are addressed by bank type
   * @param      index of bank slices
   * @param      number of banks per event
   * @param      event ids of banks in this slice
   * @param      start of bank data for this event
   *
   * @return     tuple of: (success, slice is full)
   */
  std::tuple<bool, bool, size_t> transpose_events(
    ::Slices& slices,
    int const slice_index,
    std::vector<int> const& bank_ids,
    std::array<unsigned int, LHCb::NBankTypes> const& banks_count,
    EventIDs& event_ids,
    EB::Header const& mep_header,
    Blocks const& blocks,
    SourceOffsets const& source_offsets,
    std::tuple<size_t, size_t> const& interval);

} // namespace MEP

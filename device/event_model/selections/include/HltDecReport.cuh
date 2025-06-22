/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "HltConstants.cuh"

namespace Hlt1 {
  // Hlt1 TCK.
  constexpr static unsigned int TCK = 0;

  // Task ID.
  constexpr static unsigned int taskID = 1;
} // namespace Hlt1

// Structure for handling the HltDecReport of a single line.
class HltDecReport final {

private:
  unsigned int m_report = 0;

public:
  enum Mask : unsigned {
    decision_mask = 0x1,              // 00000000000000000000000000000001
    error_mask = 0xe,                 // 00000000000000000000000000001110
    number_of_candidates_mask = 0xf0, // 00000000000000000000000011110000
    execution_stage_mask = 0xff00,    // 00000000000000001111111100000000
    decision_id_mask = 0xffff0000     // 11111111111111110000000000000000
  };

  // From Detector/FT/include/Detector/FT/FTChannelID.h
  template<Mask m>
  [[nodiscard]] static constexpr unsigned int extract(unsigned int i)
  {
    constexpr auto b =
      __builtin_ctz(static_cast<unsigned int>(m)); // FIXME: C++20 replace __builtin_ctz with std::countr_zero
    return (i & static_cast<unsigned int>(m)) >> b;
  }

  template<Mask m>
  [[nodiscard]] static constexpr unsigned int shift(unsigned int i)
  {
    constexpr auto b =
      __builtin_ctz(static_cast<unsigned int>(m)); // FIXME: C++20 replace __builtin_ctz with std::countr_zero
    auto v = (i << static_cast<unsigned int>(b));
    assert(extract<m>(v) == i);
    return v;
  }

  template<Mask m, typename T>
  [[nodiscard]] static constexpr unsigned int shift(T i)
  {
    return shift<m>(static_cast<unsigned>(i));
  }

  HltDecReport() = default;

  __device__ __host__ HltDecReport(
    bool decision,
    std::byte error,
    std::byte number_of_candidates,
    std::byte execution_stage,
    unsigned short decision_id) :
    m_report {shift<Mask::decision_mask>(decision) | shift<Mask::error_mask>(error) |
              shift<Mask::number_of_candidates_mask>(number_of_candidates) |
              shift<Mask::execution_stage_mask>(execution_stage) | shift<Mask::decision_id_mask>(decision_id)}
  {}

  __device__ __host__ HltDecReport(unsigned int report) : m_report {report} {}

  // get line decision.
  __device__ __host__ bool decision() const { return extract<Mask::decision_mask>(m_report); }

  // get line decision.
  __device__ __host__ unsigned int decision_id() const { return extract<Mask::decision_id_mask>(m_report); }

  // Get the DecReport data.
  __device__ __host__ unsigned int dec_report() const { return m_report; }

  // get line index
  __device__ __host__ unsigned int line_index() const
  {
    auto const id = decision_id();
    assert(id >= 1);
    return id - 1;
  }
};

template<bool ReadOnly = true>
class HltDecReports {
private:
  using data_type_t = std::conditional_t<ReadOnly, unsigned const, unsigned>;
  Allen::device::span<data_type_t> m_data;
  data_type_t m_number_of_lines = 0u;

  enum Offsets : unsigned { NLines = 0u, Key = 1u, TCK = 2u, TaskID = 3u, Reports = 4u };

public:
  template<bool RO = ReadOnly, typename std::enable_if_t<!RO>* = nullptr>
  __device__ __host__
  HltDecReports(Allen::device::span<data_type_t> data, unsigned event_number, unsigned number_of_lines) :
    m_data {data.subspan(size(number_of_lines) * event_number, size(number_of_lines))}
  {}

  template<bool RO = ReadOnly, typename std::enable_if_t<RO>* = nullptr>
  __device__ __host__ HltDecReports(Allen::device::span<data_type_t> data, unsigned event_number) :
    m_data {data.subspan(size(data[NLines]) * event_number, size(data[NLines]))}
  {}

  constexpr static unsigned size(unsigned number_of_lines) { return Reports + number_of_lines; }

  constexpr static unsigned version() { return 3u; }

  constexpr static unsigned source_id() { return Hlt1::Constants::sourceID; }

  __device__ __host__ Allen::device::span<char const> bank_data()
  {
    auto const bd = m_data.subspan(Key, Reports - Key + number_of_lines());
    return {reinterpret_cast<char const*>(bd.data()), bd.size_bytes()};
  }

  __device__ __host__ unsigned number_of_lines() const { return m_data[NLines]; }

  __device__ __host__ HltDecReport dec_report(unsigned line_index) const
  {
    assert(line_index < number_of_lines());
    return HltDecReport {m_data[Reports + line_index]};
  }

  template<bool RO = ReadOnly, typename std::enable_if_t<!RO>* = nullptr>
  __device__ __host__ void set_number_of_lines(unsigned n_lines)
  {
    m_data[NLines] = n_lines;
  }

  template<bool RO = ReadOnly, typename std::enable_if_t<!RO>* = nullptr>
  __device__ __host__ void set_key(unsigned key)
  {
    m_data[Key] = key;
  }

  template<bool RO = ReadOnly, typename std::enable_if_t<!RO>* = nullptr>
  __device__ __host__ void set_tck(unsigned tck)
  {
    m_data[TCK] = tck;
  }

  template<bool RO = ReadOnly, typename std::enable_if_t<!RO>* = nullptr>
  __device__ __host__ void set_task_id(unsigned task_id)
  {
    m_data[TaskID] = task_id;
  }

  template<bool RO = ReadOnly, typename std::enable_if_t<!RO>* = nullptr>
  __device__ __host__ void set_dec_report(unsigned line_index, HltDecReport report)
  {
    m_data[Reports + line_index] = report.dec_report();
  }

  // iterator class
  class const_iterator {
    data_type_t* m_ptr = nullptr;
    mutable HltDecReport m_current = HltDecReport {};

  public:
    using iterator_category = std::input_iterator_tag;
    using value_type = HltDecReport;
    using difference_type = std::ptrdiff_t;
    using pointer = HltDecReport const*;
    using reference = HltDecReport const&;

    __device__ __host__ explicit const_iterator(data_type_t* ptr) : m_ptr {ptr} {}

    __device__ __host__ inline HltDecReport const& operator*() const
    {
      m_current = HltDecReport {*m_ptr};
      return m_current;
    }

    __device__ __host__ inline const_iterator& operator++()
    {
      ++m_ptr;
      return *this;
    }

    __device__ __host__ inline bool operator==(const const_iterator& other) const { return m_ptr == other.m_ptr; }

    __device__ __host__ inline bool operator!=(const const_iterator& other) const { return !(*this == other); }
  };

  // Begin iterator
  __device__ __host__ const_iterator begin() const { return const_iterator(m_data.data() + Reports); }

  // End iterator
  __device__ __host__ const_iterator end() const { return const_iterator(m_data.data() + Reports + number_of_lines()); }
};

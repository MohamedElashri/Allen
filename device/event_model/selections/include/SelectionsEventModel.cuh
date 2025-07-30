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

#include <cstdint>
#include "BackendCommon.h"

namespace Selections {
  template<typename T>
  struct SelectionSpan {
    const T* m_data;
    const unsigned m_size;
    constexpr static unsigned store_size = sizeof(T) * 8;
    __host__ __device__ SelectionSpan(T* data, unsigned size) : m_data(data), m_size(size) {}
    __host__ __device__ bool operator[](unsigned index) const
    {
      return (m_data[index / store_size] >> (index % store_size)) & 1;
    }
    __host__ __device__ unsigned size() const { return m_size; }
    __host__ __device__ bool empty() const { return m_size == 0; }
  };

  template<typename T>
  struct Selections_t {
  protected:
    T* m_base_pointer;
    const unsigned* m_offsets;
    const unsigned m_number_of_events;

  public:
    using store_t = T;
    constexpr static unsigned store_size = sizeof(store_t) * 8;

    __host__ __device__ Selections_t(store_t* base_pointer, const unsigned* offsets, const unsigned number_of_events) :
      m_base_pointer(base_pointer), m_offsets(offsets), m_number_of_events(number_of_events)
    {}

    __host__ __device__ Selections_t(const Selections_t<store_t>& selections) :
      m_base_pointer(selections.m_base_pointer), m_offsets(selections.m_offsets),
      m_number_of_events(selections.m_number_of_events)
    {}

    __host__ __device__ unsigned get_bin_index(unsigned span_index) const
    {
      return m_offsets[span_index] / store_size + span_index; // assume 1 padding word per span_index
    }

    __host__ __device__ void fill_span(const unsigned line, const unsigned event, const bool value) const
    {
      assert(event < m_number_of_events);
      store_t fill_value = value ? -1 : 0;
      auto span_index = line * m_number_of_events + event;
      unsigned start = get_bin_index(span_index);
      unsigned end = get_bin_index(span_index + 1);
      for (unsigned i = start; i < end; i++) {
        m_base_pointer[i] = fill_value;
      }
    }

    __host__ __device__ bool is_span_empty(const unsigned line, const unsigned event) const
    {
      assert(event < m_number_of_events);
      auto span_index = line * m_number_of_events + event;
      unsigned start = get_bin_index(span_index);
      unsigned end = get_bin_index(span_index + 1);
      for (unsigned i = start; i < end; i++) {
        if (m_base_pointer[i]) return false;
      }
      return true;
    }

    __host__ __device__ unsigned count_span_population(const unsigned line, const unsigned event) const
    {
      assert(event < m_number_of_events);
      auto span_index = line * m_number_of_events + event;
      unsigned start = get_bin_index(span_index);
      unsigned end = get_bin_index(span_index + 1);
      int sum = 0;
      for (unsigned i = start; i < end; i++) {
        sum += __popc(m_base_pointer[i]);
      }
      return sum;
    }

    __host__ __device__ SelectionSpan<store_t> get_span(const unsigned line, const unsigned event) const
    {
      assert(event < m_number_of_events);
      auto span_index = line * m_number_of_events + event;
      auto offset = get_bin_index(span_index);
      return {m_base_pointer + offset,
              m_offsets[line * m_number_of_events + event + 1] - m_offsets[line * m_number_of_events + event]};
    }
  };

  using ConstSelections = const Selections_t<const uint32_t>;
  using Selections = Selections_t<uint32_t>;
} // namespace Selections

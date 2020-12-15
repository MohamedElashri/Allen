/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <cstdint>
#include "BackendCommon.h"

namespace Selections {
  template<typename T>
  struct Selections_t {
  protected:
    typename ForwardType<T, bool>::t* m_base_pointer;
    const unsigned* m_offsets;
    const unsigned m_number_of_events;

  public:
    constexpr static unsigned element_size = sizeof(bool);

    __host__ __device__ Selections_t(T* base_pointer, const unsigned* offsets, const unsigned number_of_events) :
      m_base_pointer(reinterpret_cast<typename ForwardType<T, bool>::t*>(base_pointer)), m_offsets(offsets),
      m_number_of_events(number_of_events)
    {}

    __host__ __device__ Selections_t(const Selections_t<T>& selections) :
      m_base_pointer(selections.m_base_pointer), m_offsets(selections.m_offsets),
      m_number_of_events(selections.m_number_of_events)
    {}

    __host__ __device__ bool selection(const unsigned line, const unsigned event, const unsigned index = 0) const
    {
      assert(event < m_number_of_events);
      return m_base_pointer[m_offsets[line * m_number_of_events + event] + index];
    }

    __host__ __device__ bool& selection(const unsigned line, const unsigned event, const unsigned index = 0)
    {
      assert(event < m_number_of_events);
      return m_base_pointer[m_offsets[line * m_number_of_events + event] + index];
    }

    __host__ __device__ gsl::span<typename ForwardType<T, bool>::t> get_span(const unsigned line, const unsigned event)
      const
    {
      assert(event < m_number_of_events);
      return {m_base_pointer + m_offsets[line * m_number_of_events + event],
              m_offsets[line * m_number_of_events + event + 1] - m_offsets[line * m_number_of_events + event]};
    }
  };

  using ConstSelections = const Selections_t<const bool>;
  using Selections = Selections_t<bool>;
} // namespace Selections

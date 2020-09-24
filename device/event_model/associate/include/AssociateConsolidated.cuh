/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

// A table of PV index inside an event for a track at global index and
// the values used when calculating the association.

#include <stdint.h>
#include <cassert>
#include <States.cuh>
#include <VeloEventModel.cuh>
#include <ConsolidatedTypes.cuh>

namespace Associate {
  namespace Consolidated {
    template<typename T>
    struct EventTable_t {
    private:
      typename ForwardType<T, unsigned>::t* m_base_pointer;
      const unsigned m_event_tracks_offset;
      const unsigned m_total_number;
      const unsigned m_size;

    public:
      __host__ __device__ EventTable_t(
        typename ForwardType<T, unsigned>::t* base_pointer,
        const unsigned event_tracks_offset,
        const unsigned total_number,
        const unsigned size) :
        m_base_pointer(base_pointer),
        m_event_tracks_offset(event_tracks_offset), m_total_number(total_number),
        m_size(size)
      {}

      __host__ __device__ unsigned total_number() { return m_total_number; }

      __host__ __device__ unsigned pv(const unsigned index) const { return *(m_base_pointer + 2 + m_event_tracks_offset + index); }

      __host__ __device__ unsigned& pv(const unsigned index) { return *(m_base_pointer + 2 + m_event_tracks_offset + index); }

      __host__ __device__ float value(const unsigned index) const
      {
        return *reinterpret_cast<typename ForwardType<T, float>::t*>(
          m_base_pointer + 2 + m_event_tracks_offset + m_total_number + index);
      }

      __host__ __device__ float& value(const unsigned index)
      {
        return *reinterpret_cast<typename ForwardType<T, float>::t*>(
          m_base_pointer + 2 + m_event_tracks_offset + m_total_number + index);
      }

      __host__ __device__ unsigned size() {
        return m_size;
      }
    };

    typedef const EventTable_t<const char> ConstEventTable;
    typedef EventTable_t<char> EventTable;

    template<typename T>
    struct Table_t {
    private:
      // SOA of associated indices and values
      typename ForwardType<T, unsigned>::t* m_base_pointer;
      const unsigned m_total_number;

    public:
      __host__ __device__ Table_t(typename ForwardType<T, char>::t* base_pointer, const unsigned total_number) :
        m_base_pointer(reinterpret_cast<typename ForwardType<T, unsigned>::t*>(base_pointer)), m_total_number(total_number)
      {}

      __host__ __device__ unsigned total_number() const { return m_total_number; }

      __host__ __device__ float cutoff() const
      {
        return *reinterpret_cast<typename ForwardType<T, float>::t*>(m_base_pointer + 1);
      }

      __host__ __device__ float& cutoff()
      {
        return *reinterpret_cast<typename ForwardType<T, float>::t*>(m_base_pointer + 1);
      }

      __host__ __device__ unsigned pv() const { return *(m_base_pointer + 2); }

      __host__ __device__ unsigned& pv() { return *(m_base_pointer + 2); }

      __host__ __device__ float value() const
      {
        return *reinterpret_cast<typename ForwardType<T, float>::t*>(m_base_pointer + 2 + m_total_number);
      }

      __host__ __device__ float& value()
      {
        return *reinterpret_cast<typename ForwardType<T, float>::t*>(m_base_pointer + 2 + m_total_number);
      }

      __host__ __device__ EventTable_t<typename ForwardType<T, char>::t>
      event_table(const ::Consolidated::TracksDescription& track_index, const unsigned event_number) const
      {
        const unsigned event_tracks_offset = track_index.tracks_offset(event_number);
        return {m_base_pointer, event_tracks_offset, m_total_number, track_index.number_of_tracks(event_number)};
      }
    };

    typedef const Table_t<const char> ConstTable;
    typedef Table_t<char> Table;

    __host__ __device__ inline unsigned table_size(unsigned const tn) { return sizeof(unsigned) * (tn + 1) + sizeof(float) * (tn + 1); }
  } // namespace Consolidated
} // namespace Associate

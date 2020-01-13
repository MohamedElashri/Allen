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
      typename ForwardType<T, uint>::t* m_base_pointer;
      const uint m_event_tracks_offset;
      const uint m_total_number;
      const uint m_size;

    public:
      __host__ __device__ EventTable_t(
        typename ForwardType<T, uint>::t* base_pointer,
        const uint event_tracks_offset,
        const uint total_number,
        const uint size) :
        m_base_pointer(base_pointer),
        m_event_tracks_offset(event_tracks_offset), m_total_number(total_number),
        m_size(size)
      {}

      __host__ __device__ uint total_number() { return m_total_number; }

      __host__ __device__ uint pv(const uint index) const { return *(m_base_pointer + 2 + m_event_tracks_offset + index); }

      __host__ __device__ uint& pv(const uint index) { return *(m_base_pointer + 2 + m_event_tracks_offset + index); }

      __host__ __device__ float value(const uint index) const
      {
        return *reinterpret_cast<typename ForwardType<T, float>::t*>(
          m_base_pointer + 2 + m_event_tracks_offset + m_total_number + index);
      }

      __host__ __device__ float& value(const uint index)
      {
        return *reinterpret_cast<typename ForwardType<T, float>::t*>(
          m_base_pointer + 2 + m_event_tracks_offset + m_total_number + index);
      }

      __host__ __device__ uint size() {
        return m_size;
      }
    };

    typedef const EventTable_t<const char> ConstEventTable;
    typedef EventTable_t<char> EventTable;

    template<typename T>
    struct Table_t {
    private:
      // SOA of associated indices and values
      typename ForwardType<T, uint>::t* m_base_pointer;
      const uint m_total_number;

    public:
      __host__ __device__ Table_t(typename ForwardType<T, char>::t* base_pointer, const uint total_number) :
        m_base_pointer(reinterpret_cast<typename ForwardType<T, uint>::t*>(base_pointer)), m_total_number(total_number)
      {}

      __host__ __device__ uint total_number() const { return m_total_number; }

      __host__ __device__ float cutoff() const
      {
        return *reinterpret_cast<typename ForwardType<T, float>::t*>(m_base_pointer + 1);
      }

      __host__ __device__ float& cutoff()
      {
        return *reinterpret_cast<typename ForwardType<T, float>::t*>(m_base_pointer + 1);
      }

      __host__ __device__ uint pv() const { return *(m_base_pointer + 2); }

      __host__ __device__ uint& pv() { return *(m_base_pointer + 2); }

      __host__ __device__ float value() const
      {
        return *reinterpret_cast<typename ForwardType<T, float>::t*>(m_base_pointer + 2 + m_total_number);
      }

      __host__ __device__ float& value()
      {
        return *reinterpret_cast<typename ForwardType<T, float>::t*>(m_base_pointer + 2 + m_total_number);
      }

      __host__ __device__ EventTable_t<typename ForwardType<T, char>::t>
      event_table(const ::Consolidated::TracksDescription& track_index, const uint event_number) const
      {
        const uint event_tracks_offset = track_index.tracks_offset(event_number);
        return {m_base_pointer, event_tracks_offset, m_total_number, track_index.number_of_tracks(event_number)};
      }
    };

    typedef const Table_t<const char> ConstTable;
    typedef Table_t<char> Table;

    __host__ __device__ uint table_size(uint const tn) { return sizeof(uint) * (tn + 1) + sizeof(float) * (tn + 1); }
  } // namespace Consolidated
} // namespace Associate

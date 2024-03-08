/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "ConsolidatedTypes.cuh"
#include "MuonEventModel.cuh"
#include "States.cuh"
#include "MultiEventContainer.cuh"
#include "BackendCommon.h"
#include "MuonTileID.cuh"

namespace Allen {
  namespace Views {
    namespace Muon {
      namespace Consolidated {

        struct Hit {
        private:
          const float* m_base_pointer = nullptr;
          unsigned m_index = 0;
          unsigned m_total_number_of_hits = 0;

        public:
          Hit() = default;

          __host__ __device__
          Hit(const float* base_pointer, const unsigned index, const unsigned total_number_of_hits) :
            m_base_pointer(base_pointer),
            m_index(index), m_total_number_of_hits(total_number_of_hits)
          {}

          __host__ __device__ float x() const { return m_base_pointer[m_index]; }
          __host__ __device__ float dx() const { return m_base_pointer[m_total_number_of_hits + m_index]; }
          __host__ __device__ float y() const { return m_base_pointer[2 * m_total_number_of_hits + m_index]; }
          __host__ __device__ float dy() const { return m_base_pointer[3 * m_total_number_of_hits + m_index]; }
          __host__ __device__ float z() const { return m_base_pointer[4 * m_total_number_of_hits + m_index]; }
          // We use a float basepointer and reinterpret the bits as the different types that we need to fulfill the API.
          __host__ __device__ unsigned time() const
          {
            return reinterpret_cast<const unsigned*>(m_base_pointer)[5 * m_total_number_of_hits + m_index];
          }
          __host__ __device__ float tile() const
          {
            return reinterpret_cast<const int*>(m_base_pointer)[6 * m_total_number_of_hits + m_index];
          }
          __host__ __device__ int uncrossed() const
          {
            return reinterpret_cast<const int*>(m_base_pointer)[7 * m_total_number_of_hits + m_index];
          }
          __host__ __device__ int delta_time() const
          {
            return reinterpret_cast<const int*>(m_base_pointer)[8 * m_total_number_of_hits + m_index];
          }
          __host__ __device__ int region() const
          {
            return reinterpret_cast<const int*>(m_base_pointer)[9 * m_total_number_of_hits + m_index];
          }
          __host__ __device__ unsigned id() const
          {
            const auto muon_tile = ::Muon::MuonTileID(tile());
            return muon_tile.lhcbID();
          }
        };

        struct Hits {
        private:
          const float* m_base_pointer = nullptr;
          unsigned m_offset = 0;
          unsigned m_size = 0;
          unsigned m_total_number_of_hits = 0;

        public:
          Hits() = default;

          __host__ __device__ Hits(
            const char* base_pointer,
            const unsigned* offset_tracks,
            const unsigned* offset_track_hit_number,
            const unsigned event_number,
            const unsigned number_of_events) :
            m_base_pointer(reinterpret_cast<const float*>(base_pointer)),
            m_offset(offset_track_hit_number[offset_tracks[event_number]]),
            m_size(
              offset_track_hit_number[offset_tracks[event_number + 1]] -
              offset_track_hit_number[offset_tracks[event_number]]),
            m_total_number_of_hits(offset_track_hit_number[offset_tracks[number_of_events]])
          {}

          __host__ __device__ unsigned size() const { return m_size; }

          __host__ __device__ Hit hit(const unsigned index) const
          {
            assert(index < m_size);
            return Hit {m_base_pointer, m_offset + index, m_total_number_of_hits};
          }

          __host__ __device__ unsigned offset() const { return m_offset; }
        };

        struct Track : Allen::ILHCbIDSequence<Track> {
          friend Allen::ILHCbIDSequence<Track>;

        private:
          const Hits* m_hits = nullptr;
          unsigned m_track_index = 0;
          unsigned m_track_container_offset = 0;
          unsigned m_offset = 0;
          unsigned m_number_of_hits = 0;

          __host__ __device__ unsigned number_of_ids_impl() const { return m_number_of_hits; }
          __host__ __device__ unsigned id_impl(const unsigned index) const { return hit(index).id(); }

        public:
          Track() = default;

          __host__ __device__ Track(
            const Hits* hits,
            const unsigned* offset_tracks,
            const unsigned* offset_track_hit_number,
            const unsigned track_index,
            const unsigned event_number) :
            m_hits(hits + event_number),
            m_track_index(track_index)
          {
            m_track_container_offset = offset_tracks[event_number];
            const auto offset_event = offset_track_hit_number + m_track_container_offset;
            m_offset = offset_event[track_index] - offset_event[0];
            m_number_of_hits = offset_event[track_index + 1] - offset_event[track_index];
          }

          __host__ __device__ unsigned track_index() const { return m_track_index; }

          __host__ __device__ unsigned track_container_offset() const { return m_track_container_offset; }

          __host__ __device__ unsigned number_of_hits() const { return m_number_of_hits; }

          __host__ __device__ Hit hit(const unsigned index) const
          {
            assert(m_hits != nullptr);
            assert(index < m_number_of_hits);
            return m_hits->hit(m_offset + index);
          }

          __host__ __device__ Physics::KalmanState state(const Allen::Views::Physics::KalmanStates& states_view)
          {
            return states_view.state(m_track_index);
          }
        };

        struct Tracks : Allen::ILHCbIDContainer<Tracks> {
          friend Allen::ILHCbIDContainer<Tracks>;
          constexpr static auto TypeID = Allen::TypeIDs::MuonTracks;

        private:
          const Track* m_track;
          unsigned m_size = 0;
          unsigned m_offset = 0;

          __host__ __device__ unsigned number_of_id_sequences_impl() const { return m_size; }

          __host__ __device__ const Track& id_sequence_impl(const unsigned index) const
          {
            assert(index < number_of_id_sequences_impl());
            return m_track[index];
          }

        public:
          Tracks() = default;

          __host__ __device__ Tracks(const Track* track, const unsigned* offset_tracks, const unsigned event_number) :
            m_track(track + offset_tracks[event_number]),
            m_size(offset_tracks[event_number + 1] - offset_tracks[event_number]), m_offset(offset_tracks[event_number])
          {}

          __host__ __device__ unsigned size() const { return m_size; }

          __host__ __device__ const Track& track(const unsigned index) const
          {
            assert(index < size());
            return m_track[index];
          }

          __host__ __device__ unsigned offset() const { return m_offset; }
        };

        using MultiEventTracks = Allen::MultiEventContainer<Tracks>;

      } // namespace Consolidated
    }   // namespace Muon
  }     // namespace Views
} // namespace Allen

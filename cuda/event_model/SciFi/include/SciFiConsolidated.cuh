#pragma once

#include "ConsolidatedTypes.cuh"
#include "SciFiEventModel.cuh"
#include <stdint.h>

namespace SciFi {
  namespace Consolidated {

    // Consolidated hits SoA.
    struct Hits : BaseHits {
      __device__ __host__ Hits(
        char* base_pointer,
        const uint track_offset,
        const uint total_number_of_hits,
        const SciFiGeometry* param_geom,
        const float* param_dev_inv_clus_res)
      {
        x0 = reinterpret_cast<float*>(base_pointer);
        z0 = reinterpret_cast<float*>(base_pointer + sizeof(float) * total_number_of_hits);
        m_endPointY = reinterpret_cast<float*>(base_pointer + sizeof(float) * 2 * total_number_of_hits);
        channel = reinterpret_cast<uint32_t*>(base_pointer + sizeof(float) * 3 * total_number_of_hits);
        assembled_datatype = reinterpret_cast<uint32_t*>(base_pointer + sizeof(float) * 4 * total_number_of_hits);

        x0 += track_offset;
        z0 += track_offset;
        m_endPointY += track_offset;
        channel += track_offset;
        assembled_datatype += track_offset;

        geom = param_geom;
        dev_inv_clus_res = param_dev_inv_clus_res;
      }

      __device__ __host__ SciFi::Hit get(const uint hit_number) const
      {
        return SciFi::Hit {
          x0[hit_number], z0[hit_number], m_endPointY[hit_number], channel[hit_number], assembled_datatype[hit_number]};
      }

      __device__ __host__ uint32_t LHCbID(uint32_t index) const { return (10u << 28) + channel[index]; };
    };

    //---------------------------------------------------------
    // Struct for holding consolidated SciFi track information.
    //---------------------------------------------------------
    struct Tracks : public ::Consolidated::Tracks {
    private:
      // Indices of associated UT tracks.
      const uint* m_ut_track;
      const float* m_qop;
      const MiniState* m_states;

    public:
      __device__ __host__ Tracks(
        const uint* atomics_base_pointer,
        const uint* track_hit_number_base_pointer,
        const float* qop_base_pointer,
        const MiniState* states_base_pointer,
        const uint* ut_track_base_pointer,
        const uint current_event_number,
        const uint number_of_events) :
        ::Consolidated::Tracks(
          atomics_base_pointer,
          track_hit_number_base_pointer,
          current_event_number,
          number_of_events),
        m_ut_track(ut_track_base_pointer + tracks_offset(current_event_number)),
        m_qop (qop_base_pointer + tracks_offset(current_event_number)),
        m_states(states_base_pointer + tracks_offset(current_event_number))
      {}

      uint ut_track(const uint index) {
        return m_ut_track[index];
      }

      float qop(const uint index) {
        return m_qop[index];
      }

      MiniState states(const uint index) {
        return m_states[index];
      }

      __device__ __host__ Hits get_hits(
        char* hits_base_pointer,
        const uint track_number,
        const SciFiGeometry* scifi_geometry,
        const float* dev_inv_clus_res) const
      {
        return Hits {
          hits_base_pointer, track_offset(track_number), m_total_number_of_hits, scifi_geometry, dev_inv_clus_res};
      }
    }; // namespace Consolidated

  } // namespace Consolidated
} // end namespace SciFi

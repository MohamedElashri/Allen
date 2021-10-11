#pragma once

#include <cassert>
#include "BackendCommon.h"
#include "Common.h"
#include "ConsolidatedTypes.cuh"
#include "States.cuh"

#include "PV_Definitions.cuh"

namespace Allen {
  namespace Views {
    namespace Physics {

      // TODO: Should really put this in AssociateConsolidated.cuh, but this was
      // just easier.
      struct PVTable {
      private:
        const unsigned* m_base_pointer = nullptr;
        unsigned m_offset = 0;
        unsigned m_total_number = 0;
        unsigned m_size = 0;

      public:
        __host__ __device__ PVTable (
          const char* base_pointer,
          const unsigned offset,
          const unsigned total_number,
          const unsigned size) :
          m_base_pointer(reinterpret_cast<const unsigned*>(base_pointer)),
          m_offset(offset),
          m_total_number(total_number),
          m_size(size)
        {}

        __host__ __device__ unsigned total_number() const { return m_total_number; }

        __host__ __device__ unsigned pv(const unsigned index) const
        {
          return *(m_base_pointer + 2 + m_offset + index);
        }

        __host__ __device__ float value(const unsigned index) const
        {
          return *reinterpret_cast<const float*>(m_base_pointer + 2 + m_offset + m_total_number + index);
        }

        __host__ __device__ unsigned size() { return m_size; }
      };

      struct KalmanState {
      private:
        // 6 elements to define the state: x, y, z, tx, ty, qop
        constexpr static unsigned nb_elements_state = 6;
        // Assume (x, tx) and (y, ty) are uncorrelated for 6 elements + chi2 and ndf
        constexpr static unsigned nb_elements_cov = 8;

        const float* m_base_pointer = nullptr;
        unsigned m_index = 0;
        unsigned m_total_number_of_tracks = 0;

      public:
        __host__ __device__ 
        KalmanState(const char* base_pointer, const unsigned index, const unsigned total_number_of_tracks) :
          m_base_pointer(reinterpret_cast<const float*>(base_pointer)),
          m_index(index),
          m_total_number_of_tracks(total_number_of_tracks)
        {}

        __host__ __device__ float x() const { return m_base_pointer[nb_elements_state * m_index]; }

        __host__ __device__ float y() const { return m_base_pointer[nb_elements_state * m_index + 1]; }

        __host__ __device__ float z() const { return m_base_pointer[nb_elements_state * m_index + 2]; }

        __host__ __device__ float tx() const { return m_base_pointer[nb_elements_state * m_index + 3]; }

        __host__ __device__ float ty() const { return m_base_pointer[nb_elements_state * m_index + 4]; }

        __host__ __device__ float qop() const { return m_base_pointer[nb_elements_state * m_index + 5]; }

        __host__ __device__ float c00() const 
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index];
        }

        __host__ __device__ float c20() const 
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 1];
        }

        __host__ __device__ float c22() const 
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 2];
        }

        __host__ __device__ float c11() const 
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 3];
        }

        __host__ __device__ float c31() const 
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 4];
        }

        __host__ __device__ float c33() const 
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 5];
        }

        __host__ __device__ float chi2() const 
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 6];
        }

        __host__ __device__ unsigned ndof() const 
        {
          return reinterpret_cast<const unsigned*>(m_base_pointer)[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 7];
        }

        __host__ __device__ float px() const 
        {
          return (tx() / fabsf(qop())) / sqrtf(1.0f + tx() * tx() + ty() * ty());
        }

        __host__ __device__ float py() const 
        { 
          return (ty() / fabsf(qop())) / sqrtf(1.0f + tx() * tx() + ty() * ty()); 
        }

        __host__ __device__ float pz() const 
        {
          return (1.0f / fabsf(qop())) / sqrtf(1.0f + tx() * tx() + ty() * ty());
        }

        __host__ __device__ float pt() const 
        { 
          const float sumt2 = tx() * tx() + ty() * ty();
          return (sqrtf(sumt2) / fabsf(qop())) / sqrtf(1.0f + sumt2);
        }
        
        __host__ __device__ float p() const 
        {
          return 1.0f / fabsf(qop());
        }

        __host__ __device__ float e(const float mass) const 
        { 
          return sqrtf(p() * p() + mass * mass);
        }

        __host__ __device__ float eta() const { return atanhf(pz() / p()); }

        __host__ __device__ operator MiniState() const { return MiniState {x(), y(), z(), tx(), ty()}; }

        __host__ __device__ operator KalmanVeloState() const
        {
          return KalmanVeloState {x(), y(), z(), tx(), ty(), c00(), c20(), c22(), c11(), c31(), c33()};
        }

      };

      struct KalmanStates {
      private:
        const char* m_base_pointer = nullptr;
        unsigned m_offset = 0;
        unsigned m_size = 0;
        unsigned m_total_number_of_tracks = 0;

      public:
        __host__ __device__ KalmanStates(
          const char* base_pointer,
          const unsigned* offset_tracks,
          const unsigned event_number,
          const unsigned number_of_events) :
          m_base_pointer(base_pointer),
          m_offset(offset_tracks[event_number]),
          m_size(offset_tracks[event_number + 1] - offset_tracks[event_number]),
          m_total_number_of_tracks(offset_tracks[number_of_events])
        {}

        __host__ __device__ unsigned size() const { return m_size; }

        __host__ __device__ unsigned offset() const { return m_offset; }

        __host__ __device__ KalmanState state(const unsigned track_index) const
        {
          assert(track_index < m_size);
          return KalmanState {m_base_pointer, m_offset + track_index, m_total_number_of_tracks};
        }
      };

      struct SecondaryVertex {
        // 3 elements for position + 3 elements for momentum
        constexpr static unsigned nb_elements_vrt = 6;
        // Just the 3x3 position covariance + chi2 + ndof?
        constexpr static unsigned nb_elements_cov = 8;

      private:
        const float* m_base_pointer = nullptr;
        unsigned m_index = 0;
        unsigned m_total_number_of_vrts = 0;

      public:
        __host__ __device__
        SecondaryVertex(const char* base_pointer, const unsigned index, const unsigned total_number_of_vrts) :
          m_base_pointer(reinterpret_cast<const float*>(base_pointer)),
          m_index(index),
          m_total_number_of_vrts(total_number_of_vrts)
        {}

        __host__ __device__ float x() const { return m_base_pointer[nb_elements_vrt * m_index]; }

        __host__ __device__ float y() const { return m_base_pointer[nb_elements_vrt * m_index + 1]; }

        __host__ __device__ float z() const { return m_base_pointer[nb_elements_vrt * m_index + 2]; }

        __host__ __device__ float px() const { return m_base_pointer[nb_elements_vrt * m_index + 3]; }

        __host__ __device__ float py() const { return m_base_pointer[nb_elements_vrt * m_index + 4]; }

        __host__ __device__ float pz() const { return m_base_pointer[nb_elements_vrt * m_index + 5]; }
        
        __host__ __device__ float c00() const 
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index];
        }

        __host__ __device__ float c11() const 
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 1];
        }

        __host__ __device__ float c10() const 
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 2];
        }

        __host__ __device__ float c22() const 
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 3];
        }

        __host__ __device__ float c21() const 
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 4];
        }

        __host__ __device__ float c20() const 
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 5];
        }
        
        __host__ __device__ float chi2() const
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 6];
        }

        __host__ __device__ unsigned ndof() const
        {
          return reinterpret_cast<const unsigned*>(m_base_pointer)[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 7];
        }

      };

      struct SecondaryVertices {
      private:
        const char* m_base_pointer = nullptr;
        unsigned m_offset = 0;
        unsigned m_size = 0;
        unsigned m_total_number_of_vrts = 0;

      public:
        __host__ __device__ SecondaryVertices(
          const char* base_pointer,
          const unsigned* offset_svs,
          const unsigned event_number,
          const unsigned number_of_events) :
          m_base_pointer(base_pointer),
          m_offset(offset_svs[event_number]),
          m_size(offset_svs[event_number + 1] - offset_svs[event_number]),
          m_total_number_of_vrts(offset_svs[number_of_events])
        {}

        __host__ __device__ unsigned size() const { return m_size; }

        __host__ __device__ unsigned offset() const { return m_offset; }

        __host__ __device__ const SecondaryVertex vertex(const unsigned sv_index) const
        {
          assert(sv_index < m_size);
          return SecondaryVertex {m_base_pointer, m_offset + sv_index, m_total_number_of_vrts};
        }
      };

      // Is it necessary for BasicParticle to inherit from an ILHCbIDStructure to
      // work with aggregates in the SelReport writer?
      struct BasicParticle : ILHCbIDSequence {
      private:
        const ILHCbIDSequence* m_track = nullptr;
        const KalmanStates* m_states = nullptr;
        const PV::Vertex* m_pv = nullptr; // PV event model should be rebuilt too.
        // Could store muon and calo PID in a single array, but they're created by
        // different algorithms and might not always exist.
        const bool* m_muon_id = nullptr;
        unsigned m_index = 0;


      public:
        __host__ __device__ BasicParticle(
          const ILHCbIDSequence* track,
          const KalmanStates* states,
          const PV::Vertex* pv,
          const bool* muon_id,
          const unsigned index) :
          m_track(track), m_states(states), m_pv(pv), 
          m_muon_id(muon_id), m_index(index)
        {
          // Make sure this isn't a composite ID structure.
          // TODO: Is this sensible at all?
          assert(m_track->number_of_substructures()==1);
        }

        __host__ __device__ unsigned number_of_ids() const override
        {
          return m_track->number_of_ids();
        }

        __host__ __device__ unsigned id(const unsigned index) const override
        {
          return m_track->id(index);
        }

        __host__ __device__ KalmanState state() const
        {
          return m_states->state(m_index);
        }

        __host__ __device__ const PV::Vertex* pv() const { return m_pv; }

        __host__ __device__ float px() const 
        { 
          assert(m_state != nullptr);
          return state().px(); 
        }

        __host__ __device__ float py() const 
        { 
          assert(m_state != nullptr);
          return state().py(); 
        }

        __host__ __device__ float pz() const 
        { 
          assert(m_state != nullptr);
          return state().pz(); 
        }

        __host__ __device__ float p() const 
        { 
          assert(m_state != nullptr);
          return state().p(); 
        }

        __host__ __device__ float e(const float mass) const 
        {
          assert(m_state != nullptr);
          return state().e(mass); 
        }

        __host__ __device__ float pt() const 
        { 
          assert(m_state != nullptr);
          return state().pt(); 
        }

        __host__ __device__ float eta() const 
        { 
          assert(m_state != nullptr);
          return state().eta(); 
        }

        __host__ __device__ bool is_muon() const {
          assert(m_muon_id != nullptr);
          return m_muon_id[m_index]; 
        }

        __host__ __device__ float chi2() const { return state().chi2(); }

        __host__ __device__ unsigned ndof() const { return state().ndof(); }

        __host__ __device__ float ip_chi2() const 
        {
          assert(m_pv != nullptr);
          assert(m_state != nullptr);

          // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
          const float tx = state().tx();
          const float ty = state().ty();
          const float dz = m_pv->position.z - state().z();
          const float dx = state().x() + dz * tx - m_pv->position.x;
          const float dy = state().y() + dz * ty - m_pv->position.y;

          // compute the covariance matrix. first only the trivial parts:
          float cov00 = m_pv->cov00 + state().c00();
          float cov10 = m_pv->cov10; // state c10 is 0.f
          float cov11 = m_pv->cov11 + state().c11();

          // add the contribution from the extrapolation
          cov00 += dz * dz * state().c22() + 2 * dz * state().c20();
          // cov10 is unchanged: state c32 = c30 = c21 = 0.f
          cov11 += dz * dz * state().c33() + 2 * dz * state().c31();

          // add the contribution from pv z
          cov00 += tx * tx * m_pv->cov22 - 2 * tx * m_pv->cov20;
          cov10 += tx * ty * m_pv->cov22 - ty * m_pv->cov20 - tx * m_pv->cov21;
          cov11 += ty * ty * m_pv->cov22 - 2 * ty * m_pv->cov21;

          // invert the covariance matrix
          float invdet = 1.0f / (cov00 * cov11 - cov10 * cov10);
          float invcov00 = cov11 * invdet;
          float invcov10 = -cov10 * invdet;
          float invcov11 = cov00 * invdet;

          return dx * dx * invcov00 + 2 * dx * dy * invcov10 + dy * dy * invcov11;
        }

        // Note this is not the minimum IP, but the IP relative to the "best" PV,
        // which is determined with IP chi2.
        __host__ __device__ float ip() const
        {
          assert(m_pv != nullptr);
          const float tx = state().tx();
          const float ty = state().ty();
          const float dz = m_pv->position.z - state().z();
          const float dx = state().x() + dz * tx - m_pv->position.x;
          const float dy = state().y() + dz * ty - m_pv->position.y;
          return sqrtf((dx * dx + dy * dy)/(1.0f + tx * tx + ty * ty));
        }
      };

      struct BasicParticles : ILHCbIDContainer {
      private:
        const ILHCbIDContainer* m_track_container = nullptr;
        const KalmanStates* m_states = nullptr;
        const PV::Vertex* m_pvs = nullptr;
        const PVTable* m_pv_table = nullptr;
        const bool* m_muon_id = nullptr;
        unsigned m_offset = 0;
        unsigned m_size = 0;

      public:
        __host__ __device__ BasicParticles(
          const ILHCbIDContainer* track_container, 
          const KalmanStates* states,
          const PV::Vertex* pvs,
          const PVTable* pv_table,
          const bool* muon_id,
          const unsigned* track_offsets, 
          const unsigned pv_offset,
          const unsigned event_number) :
          m_track_container(track_container),
          m_states(states),
          // Need PVs and the association table. This doesn't make any sense without them.
          m_pvs(pvs + pv_offset),
          m_pv_table(pv_table + event_number),
          m_muon_id(muon_id + track_offsets[event_number]),
          m_offset(track_offsets[event_number]),
          m_size(track_offsets[event_number + 1] - track_offsets[event_number])
        {}

        __host__ __device__ unsigned number_of_id_structures() const override
        {
          return m_track_container->number_of_id_structures();
        }

        __host__ __device__ const ILHCbIDStructure& id_structure(const unsigned index) const override
        {
          return m_track_container->id_structure(index);
        }

        __host__ __device__ unsigned size() const { return m_size; }

        __host__ __device__ const BasicParticle particle(const unsigned index) const
        {
          return BasicParticle {
            dynamic_cast<const ILHCbIDSequence*>(&m_track_container->id_structure(index)),
            m_states,
            m_pvs + m_pv_table->pv(index),
            m_muon_id,
            index};
        }

        __host__ __device__ unsigned offset() const { return m_offset; }

      };
    }
  }
}
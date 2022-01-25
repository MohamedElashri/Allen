/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
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

        __host__ __device__ int pv(const unsigned index) const
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

        __host__ __device__ float pt2() const { return px() * px() + py() * py(); }

        __host__ __device__ float pt() const { return sqrtf(pt2()); }

        __host__ __device__ float p2() const { return pt2() + pz() * pz(); }

        __host__ __device__ float p() const { return sqrtf(p2()); }

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

        // Accessors to allow copying. Is there a better way to handle this?
        __host__ __device__ const ILHCbIDSequence* get_track() const { return m_track; }
        __host__ __device__ const KalmanStates* get_states() const { return m_states; }
        __host__ __device__ const PV::Vertex* get_pv() const { return m_pv; }
        __host__ __device__ const bool* get_muon_id() const { return m_muon_id; }
        __host__ __device__ unsigned get_index() const { return m_index; }

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

        __host__ __device__ const PV::Vertex pv() const { return *m_pv; }

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
        const BasicParticle* m_track = nullptr;
        unsigned m_offset = 0;
        unsigned m_size = 0;

      public:
        __host__ __device__ BasicParticles(
          const BasicParticle* track,
          const unsigned* track_offsets,
          const unsigned event_number) :
          m_track(track + track_offsets[event_number]),
          m_offset(track_offsets[event_number]),
          m_size(track_offsets[event_number + 1] - track_offsets[event_number])
        {}

        __host__ __device__ unsigned number_of_id_structures() const override
        {
          return m_size;
        }

        __host__ __device__ const ILHCbIDStructure& id_structure(const unsigned index) const override
        {
          return m_track[index];
        }

        __host__ __device__ unsigned size() const { return m_size; }

        __host__ __device__ const BasicParticle& particle(const unsigned index) const
        {
          return m_track[index];
        }

        __host__ __device__ const BasicParticle* particle_pointer(const unsigned index) const
        {
          return m_track + index;
        }

        __host__ __device__ unsigned offset() const { return m_offset; }

      };

      struct CompositeParticle : ILHCbIDComposite {
        // TODO: Get these masses from somewhere else.
        static constexpr float mPi = 139.57f;
        static constexpr float mMu = 105.66f;

      private:
        const SecondaryVertices* m_vertices = nullptr;
        const PV::Vertex* m_pv = nullptr;

      public:
        __host__ __device__ CompositeParticle(
          const ILHCbIDStructure** children,
          const SecondaryVertices* vertices,
          const PV::Vertex* pv,
          unsigned number_of_children,
          unsigned total_number_of_composites,
          unsigned index) :
          ILHCbIDComposite {children,
                            number_of_children,
                            index,
                            total_number_of_composites},
          m_vertices(vertices),
          m_pv(pv)
        {}

        __host__ __device__ const PV::Vertex* get_pv() const { return m_pv; }
        __host__ __device__ const SecondaryVertices* get_vertices() const { return m_vertices; }

        __host__ __device__ SecondaryVertex vertex() const 
        {
          return m_vertices->vertex(m_index);
        }

        __host__ __device__ PV::Vertex pv() const
        {
          return *m_pv;
        }

        __host__ __device__ float x() const { return vertex().x(); }

        __host__ __device__ float y() const { return vertex().y(); }

        __host__ __device__ float z() const { return vertex().z(); }

        __host__ __device__ float px() const { return vertex().px(); }

        __host__ __device__ float py() const { return vertex().py(); }

        __host__ __device__ float pz() const { return vertex().pz(); }

        __host__ __device__ float pt() const { return vertex().pt(); }

        __host__ __device__ float p() const { return vertex().p(); }

        // TODO: Some of these quantities are expensive to calculate, so it
        // might be a good idea to store them in an "extra info" array. Need to
        // see how the timing shakes out.
        __host__ __device__ float e() const
        {
          float energy = 0.f;
          for (unsigned i = 0; i < number_of_substructures(); i++) {
            const auto substr = substructure(i);
            if (substr->number_of_substructures() == 1) {
              energy += dynamic_cast<const BasicParticle*>(substr)->e(mPi);
            } else {
              energy += dynamic_cast<const CompositeParticle*>(substr)->e();
            }
          }
          return energy;
        }

        __host__ __device__ float sumpt() const
        {
          float sum = 0.f;
          for (unsigned i = 0; i < number_of_substructures(); i++) {
            const auto substr = substructure(i);
            if (substr->number_of_substructures() == 1) {
              sum += dynamic_cast<const BasicParticle*>(substr)->pt();
            } else {
              sum += dynamic_cast<const CompositeParticle*>(substr)->pt();
            }
          }
          return sum;
        }

        __host__ __device__ float m() const
        { 
          const float energy = e();
          return sqrtf(energy * energy - vertex().p2());
        }

        __host__ __device__ float m12(const float m1, const float m2) const
        {
          float energy = 0.f;
          const auto substr1 = substructure(0);
          const auto substr2 = substructure(1);
          if (substr1->number_of_substructures() == 1) {
            energy += dynamic_cast<const BasicParticle*>(substr1)->e(m1);
          } else {
            energy += dynamic_cast<const CompositeParticle*>(substr1)->e();
          }
          if (substr2->number_of_substructures() == 1) {
            energy += dynamic_cast<const BasicParticle*>(substr2)->e(m2);
          } else {
            energy += dynamic_cast<const CompositeParticle*>(substr2)->e();
          }
          return sqrtf(energy * energy - vertex().p2());
        }

        __host__ __device__ float m12() const { return m12(mPi, mPi); }

        __host__ __device__ float mdimu() const { return m12(mMu, mMu); }

        __host__ __device__ float fdchi2() const 
        { 
          if (m_pv == nullptr) return 0.f;
          const auto primary = pv();
          const auto vrt = vertex();
          const float dx = vrt.x() - primary.position.x;
          const float dy = vrt.y() - primary.position.y;
          const float dz = vrt.z() - primary.position.z;
          const float c00 = vrt.c00() + primary.cov00;
          const float c10 = vrt.c10() + primary.cov10;
          const float c11 = vrt.c11() + primary.cov11;
          const float c20 = vrt.c20() + primary.cov20;
          const float c21 = vrt.c21() + primary.cov21;
          const float c22 = vrt.c22() + primary.cov22;
          const float invdet = 1.f / (2.f * c10 * c20 * c21 - c11 * c20 * c20 - c00 * c21 * c21 +
                                      c00 * c11 * c22 - c22 * c10 * c10);
          const float invc00 = (c11 * c22 - c21 * c21) * invdet;
          const float invc10 = (c20 * c21 - c10 * c22) * invdet;
          const float invc11 = (c00 * c22 - c20 * c20) * invdet;
          const float invc20 = (c10 * c21 - c11 * c20) * invdet;
          const float invc21 = (c10 * c20 - c00 * c21) * invdet;
          const float invc22 = (c00 * c11 - c10 * c10) * invdet;
          return invc00 * dx * dx + invc11 * dy * dy + invc22 * dz * dz +
            2.f * invc20 * dx * dz + 2.f * invc21 * dy * dz + 2.f * invc10 * dx * dy;
        }

        __host__ __device__ float fd() const
        {
          if (m_pv == nullptr) return 0.f;
          const auto primary = pv();
          const auto vrt = vertex();
          const float dx = vrt.x() - primary.position.x;
          const float dy = vrt.y() - primary.position.y;
          const float dz = vrt.z() - primary.position.z;
          return sqrtf(dx * dx + dy * dy + dz * dz);
        }

        __host__ __device__ float dz() const {
          if (m_pv == nullptr) return 0.f;
          return vertex().z() - pv().position.z; 
        }

        __host__ __device__ float eta() const {
          if (m_pv == nullptr) return 0.f;
          return atanhf(dz() / fd()); 
        }

        __host__ __device__ float mcor() const 
        { 
          if (m_pv == nullptr) return 0.f;
          const float mvis = m();
          const auto primary = pv();
          const auto vrt = vertex();
          const float dx = vrt.x() - primary.position.x;
          const float dy = vrt.y() - primary.position.y;
          const float dz = vrt.z() - primary.position.z;
          const float loc_fd = sqrtf(dx * dx + dy * dy + dz * dz);
          const float pperp2 = ((vrt.py() * dz - dy * vrt.pz()) * (vrt.py() * dz - dy * vrt.pz()) +
                                (vrt.pz() * dx - dz * vrt.px()) * (vrt.pz() * dx - dz * vrt.px()) +
                                (vrt.px() * dy - dx * vrt.py()) * (vrt.px() * dy - dx * vrt.py()))
                                / (loc_fd * loc_fd);
          return sqrtf(mvis * mvis + pperp2) + sqrtf(pperp2);
        }

        __host__ __device__ float minipchi2() const 
        { 
          float val = -1;
          for (unsigned i = 0; i < number_of_substructures(); i++) {
            float tmp = -1;
            const auto substr = substructure(i);
            if (substr->number_of_substructures() == 1) {
              tmp = dynamic_cast<const BasicParticle*>(substr)->ip_chi2();
            } else {
              tmp = dynamic_cast<const CompositeParticle*>(substr)->minipchi2();
            }
            if (tmp < val || val < 0) val = tmp;
          }
          return val;
        }

        __host__ __device__ float minip() const 
        { 
          float val = -1;
          for (unsigned i = 0; i < number_of_substructures(); i++) {
            float tmp = -1;
            const auto substr = substructure(i);
            if (substr->number_of_substructures() == 1) {
              tmp = dynamic_cast<const BasicParticle*>(substr)->ip();
            } else {
              tmp = dynamic_cast<const CompositeParticle*>(substr)->minip();
            }
            if (tmp < val || val < 0) val = tmp;
          }
          return val;
        }

        __host__ __device__ float minp() const 
        { 
          float val = -1;
          for (unsigned i = 0; i < number_of_substructures(); i++) {
            float tmp = -1;
            const auto substr = substructure(i);
            if (substr->number_of_substructures() == 1) {
              tmp = dynamic_cast<const BasicParticle*>(substr)->p();
            } else {
              tmp = dynamic_cast<const CompositeParticle*>(substr)->p();
            }
            if (tmp < val && val > 0) val = tmp;
          }
          return val;        
        }

        __host__ __device__ float minpt() const 
        { 
          float val = -1;
          for (unsigned i = 0; i < number_of_substructures(); i++) {
            float tmp = -1;
            const auto substr = substructure(i);
            if (substr->number_of_substructures() == 1) {
              tmp = dynamic_cast<const BasicParticle*>(substr)->pt();
            } else {
              tmp = dynamic_cast<const CompositeParticle*>(substr)->pt();
            }
            if (tmp < val || val < 0) val = tmp;
          }
          return val;        
        }


        __host__ __device__ float dira() const 
        { 
          if (m_pv == nullptr) return 0.f;
          const auto primary = pv();
          const auto vrt = vertex();
          const float dx = vrt.x() - primary.position.x;
          const float dy = vrt.y() - primary.position.y;
          const float dz = vrt.z() - primary.position.z;
          const float loc_fd = sqrtf(dx * dx + dy * dy + dz * dz);
          return (dx * vrt.px() + dy * vrt.py() + dz * vrt.pz()) / (vrt.p() * loc_fd);
        }

        __host__ __device__ float doca(const unsigned index1, const unsigned index2) const
        {
          float xA;
          float yA; 
          float zA;
          float txA;
          float tyA;
          const auto substr1 = substructure(index1);
          if (substr1->number_of_substructures() == 1) {
            const auto track = dynamic_cast<const BasicParticle*>(substr1);
            const auto state = track->state();
            xA = state.x();
            yA = state.y();
            zA = state.z();
            txA = state.tx();
            tyA = state.ty();
          } else {
            const auto sv1 = dynamic_cast<const CompositeParticle*>(substr1);
            xA = sv1->x();
            yA = sv1->y();
            zA = sv1->z();
            txA = sv1->px() / sv1->pz();
            tyA = sv1->py() / sv1->pz();
          }

          float xB;
          float yB;
          float zB;
          float txB;
          float tyB;
          const auto substr2 = substructure(index2);
          if (substr1->number_of_substructures() == 1) {
            const auto track = dynamic_cast<const BasicParticle*>(substr2);
            const auto state = track->state();
            xB = state.x();
            yB = state.y();
            zB = state.z();
            txB = state.tx();
            tyB = state.ty();
          } else {
            const auto sv2 = dynamic_cast<const CompositeParticle*>(substr2);
            xB = sv2->x();
            yB = sv2->y();
            zB = sv2->z();
            txB = sv2->px() / sv2->pz();
            tyB = sv2->py() / sv2->pz();
          }
          
          float secondAA = txA * txA + tyA * tyA + 1.0f;
          float secondBB = txB * txB + tyB * tyB + 1.0f;
          float secondAB = -txA * txB - tyA * tyB - 1.0f;
          float det = secondAA * secondBB - secondAB * secondAB;
          float ret = -1;
          if (fabsf(det) > 0) {
            float secondinvAA = secondBB / det;
            float secondinvBB = secondAA / det;
            float secondinvAB = -secondAB / det;
            float firstA = txA * (xA -xB) + tyA * (yA - yB) + (zA - zB);
            float firstB = -txB * (xA - xB) - tyB * (yA - yB) - (zA - zB);
            float muA = -(secondinvAA * firstA + secondinvAB * firstB);
            float muB = -(secondinvBB * firstB + secondinvAB * firstA);
            float dx = (xA + muA * txA) - (xB + muB * txB);
            float dy = (yA + muA * tyA) - (yB + muB * tyB);
            float dz = (zA + muA) - (zB + muB);
            ret = sqrtf(dx * dx + dy * dy + dz * dz);
          }
          return ret;
        }

        __host__ __device__ float docamax() const 
        { 
          float val = -1.f;
          for (unsigned i = 0; i < number_of_substructures(); i++) {
            for (unsigned j = i + 1; j < number_of_substructures(); j++) {
              float loc_doca = doca(i, j);
              if (loc_doca > val) val = loc_doca;
            }
          }
          return val;
        }

        __host__ __device__ float doca12() const { return doca(0, 1); }

        __host__ __device__ float ip() const 
        { 
          if (m_pv == nullptr) return 0.f;
          const auto vrt = vertex();
          const auto primary = pv();
          float tx = vrt.px() / vrt.pz();
          float ty = vrt.py() / vrt.pz();
          float dz = primary.position.z - vrt.z();
          float dx = vrt.x() + dz * tx - primary.position.x;
          float dy = vrt.y() + dz * ty - primary.position.y;
          return sqrtf((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty)); 
        }

        __host__ __device__ bool is_dimuon() const
        {
          const auto substr1 = substructure(0);
          const auto substr2 = substructure(1);
          if (substr1->number_of_substructures() != 1 || substr2->number_of_substructures() != 1)
            return false;
          return dynamic_cast<const BasicParticle*>(substr1)->is_muon() &&
            dynamic_cast<const BasicParticle*>(substr2)->is_muon();
        }

        __host__ __device__ float clone_sin2() const 
        { 
          if (!is_dimuon()) return -1.f;
          const auto substr1 = substructure(0);
          const auto substr2 = substructure(1);
          const auto state1 = dynamic_cast<const BasicParticle*>(substr1)->state();
          const auto state2 = dynamic_cast<const BasicParticle*>(substr2)->state();
          const float txA = state1.tx();
          const float tyA = state1.ty();
          const float txB = state2.tx();
          const float tyB = state2.ty();
          const float vx = tyA - tyB;
          const float vy = -txA + txB;
          const float vz = txA * tyB - txB * tyA;
          return (vx * vx + vy * vy + vz * vz) / ((txA * txA + tyA * tyA + 1.f) * (txB * txB + tyB * tyB + 1.f));
        }
      };

      struct CompositeParticles {
      private:
        const CompositeParticle* m_composite = nullptr;
        unsigned m_offset = 0;
        unsigned m_size = 0;
        
      public:
        __host__ __device__ CompositeParticles (
          const CompositeParticle* composite,
          const unsigned* offsets,
          unsigned event_number) :
          m_composite(composite + offsets[event_number]),
          m_offset(offsets[event_number]),
          m_size(offsets[event_number + 1] - offsets[event_number])
        {}

        __host__ __device__ const CompositeParticle& particle(unsigned particle_index) const
        {
          return m_composite[particle_index];
        }

        __host__ __device__ unsigned size() const { return m_size; }

        __host__ __device__ unsigned offset() const { return m_offset; }
      };
    }
  }
}
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
//#include "ConsolidatedTypes.cuh"
#include "States.cuh"
#include "VeloEventModel.cuh"
#include "SciFiEventModel.cuh"
#include "UTEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiConsolidated.cuh"

#include "PV_Definitions.cuh"

namespace Allen {
  namespace Views {
    namespace Physics {

      // TODO: Should really put this in AssociateConsolidated.cuh, but this was
      // just easier.
      struct PVTable {
      private:
        const int* m_base_pointer = nullptr;
        unsigned m_offset = 0;
        unsigned m_total_number = 0;
        unsigned m_size = 0;

      public:
        __host__ __device__
        PVTable(const char* base_pointer, const unsigned offset, const unsigned total_number, const unsigned size) :
          m_base_pointer(reinterpret_cast<const int*>(base_pointer)),
          m_offset(offset), m_total_number(total_number), m_size(size)
        {}

        __host__ __device__ unsigned total_number() const { return m_total_number; }

        __host__ __device__ int pv(const unsigned index) const { return *(m_base_pointer + 2 + m_offset + index); }

        __host__ __device__ float value(const unsigned index) const
        {
          return *reinterpret_cast<const float*>(m_base_pointer + 2 + m_offset + m_total_number + index);
        }

        __host__ __device__ unsigned size() { return m_size; }
      };

      struct Track {
      private:
        const Allen::Views::Velo::Consolidated::Track* m_velo_segment = nullptr;
        const Allen::Views::UT::Consolidated::Track* m_ut_segment = nullptr;
        const Allen::Views::SciFi::Consolidated::Track* m_scifi_segment = nullptr;

      public:
        __host__ __device__ Track(
          const Allen::Views::Velo::Consolidated::Track* velo_segment,
          const Allen::Views::UT::Consolidated::Track* ut_segment,
          const Allen::Views::SciFi::Consolidated::Track* scifi_segment) :
          m_velo_segment(velo_segment),
          m_ut_segment(ut_segment), m_scifi_segment(scifi_segment)
        {}

        __host__ __device__ bool has_velo() const { return m_velo_segment != nullptr; }

        __host__ __device__ bool has_ut() const { return m_ut_segment != nullptr; }

        __host__ __device__ bool has_scifi() const { return m_scifi_segment != nullptr; }

        __host__ __device__ unsigned number_of_scifi_hits() const
        {
          if (m_scifi_segment == nullptr) {
            return 0;
          }
          else {
            return m_scifi_segment->number_of_scifi_hits();
          }
        }

        __host__ __device__ unsigned number_of_ut_hits() const
        {
          if (m_ut_segment == nullptr) {
            return 0;
          }
          else {
            return m_ut_segment->number_of_ut_hits();
          }
        }

        __host__ __device__ unsigned number_of_velo_hits() const
        {
          if (m_velo_segment == nullptr) {
            return 0;
          }
          else {
            return m_velo_segment->number_of_hits();
          }
        }

        __host__ __device__ unsigned number_of_hits() const
        {
          return number_of_velo_hits() + number_of_ut_hits() + number_of_scifi_hits();
        }

        __host__ __device__ unsigned id(const unsigned index) const
        {
          assert(index < number_of_hits());
          if (index < number_of_velo_hits()) {
            return m_velo_segment->id(index);
          }
          else if (index < number_of_ut_hits() + number_of_velo_hits()) {
            return m_ut_segment->id(index - number_of_velo_hits());
          }
          else {
            return m_scifi_segment->id(index - number_of_velo_hits() - number_of_ut_hits());
          }
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
          m_offset(offset_svs[event_number]), m_size(offset_svs[event_number + 1] - offset_svs[event_number]),
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

      struct Particle {
        unsigned m_number_of_substructures = 0;

        __host__ __device__ Particle(const unsigned size) : m_number_of_substructures(size) {}

        __host__ __device__ unsigned number_of_substructures() const { return m_number_of_substructures; }

        virtual __host__ __device__ ~Particle() {}
      };

      struct ParticleContainer {
      protected:
        const Particle* m_particle = nullptr;
        unsigned m_size = 0;

      public:
        __host__ __device__ ParticleContainer(const Particle* particle, const unsigned size) :
          m_particle(particle), m_size(size)
        {}

        virtual __host__ __device__ unsigned size() const { return m_size; }

        virtual __host__ __device__ ~ParticleContainer() {}
      };

      // Is it necessary for BasicParticle to inherit from an ILHCbIDStructure to
      // work with aggregates in the SelReport writer?
      struct BasicParticle : Particle {
      private:
        const Track* m_track = nullptr;
        const KalmanStates* m_states = nullptr;
        const PV::Vertex* m_pv = nullptr; // PV event model should be rebuilt too.
        // Could store muon and calo PID in a single array, but they're created by
        // different algorithms and might not always exist.
        const bool* m_muon_id = nullptr;
        unsigned m_index = 0;

      public:
        __host__ __device__ BasicParticle(
          const Track* track,
          const KalmanStates* states,
          const PV::Vertex* pv,
          const bool* muon_id,
          const unsigned index) :
          Particle {1},
          m_track(track), m_states(states), m_pv(pv), m_muon_id(muon_id), m_index(index)
        {
          // Make sure this isn't a composite ID structure.
          // TODO: Is this sensible at all?
          assert(m_track->number_of_substructures() == 1);
        }

        // Accessors to allow copying. Is there a better way to handle this?
        __host__ __device__ const Track* get_track() const { return m_track; }

        __host__ __device__ const KalmanStates* get_states() const { return m_states; }

        __host__ __device__ const PV::Vertex* get_pv() const { return m_pv; }

        __host__ __device__ const bool* get_muon_id() const { return m_muon_id; }

        __host__ __device__ unsigned get_index() const { return m_index; }

        __host__ __device__ unsigned number_of_ids() const { return m_track->number_of_hits(); }

        __host__ __device__ unsigned id(const unsigned index) const { return m_track->id(index); }

        __host__ __device__ KalmanState state() const { return m_states->state(m_index); }

        __host__ __device__ const PV::Vertex pv() const { return *m_pv; }

        __host__ __device__ float px() const
        {
          assert(m_states != nullptr);
          return state().px();
        }

        __host__ __device__ float py() const
        {
          assert(m_states != nullptr);
          return state().py();
        }

        __host__ __device__ float pz() const
        {
          assert(m_states != nullptr);
          return state().pz();
        }

        __host__ __device__ float p() const
        {
          assert(m_states != nullptr);
          return state().p();
        }

        __host__ __device__ float e(const float mass) const
        {
          assert(m_states != nullptr);
          return state().e(mass);
        }

        __host__ __device__ float pt() const
        {
          assert(m_states != nullptr);
          return state().pt();
        }

        __host__ __device__ float eta() const
        {
          assert(m_states != nullptr);
          return state().eta();
        }

        __host__ __device__ bool is_muon() const
        {
          assert(m_muon_id != nullptr);
          return m_muon_id[m_index];
        }

        __host__ __device__ float chi2() const { return state().chi2(); }

        __host__ __device__ unsigned ndof() const { return state().ndof(); }

        __host__ __device__ float ip_chi2() const
        {
          assert(m_pv != nullptr);
          assert(m_states != nullptr);

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
          return sqrtf((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
        }
      };

      struct BasicParticles : ParticleContainer {
      private:
        unsigned m_offset = 0;

      public:
        __host__ __device__
        BasicParticles(const BasicParticle* track, const unsigned* track_offsets, const unsigned event_number) :
          ParticleContainer {track + track_offsets[event_number],
                             track_offsets[event_number + 1] - track_offsets[event_number]},
          m_offset(track_offsets[event_number])
        {}

        __host__ __device__ unsigned size() const { return m_size; }

        __host__ __device__ const BasicParticle& particle(const unsigned index) const
        {
          return static_cast<const BasicParticle*>(m_particle)[index];
        }

        __host__ __device__ const BasicParticle* particle_pointer(const unsigned index) const
        {
          return static_cast<const BasicParticle*>(m_particle) + index;
        }

        __host__ __device__ unsigned offset() const { return m_offset; }
      };

      struct CompositeParticle : Particle {
        // TODO: Get these masses from somewhere else.
        static constexpr float mPi = 139.57f;
        static constexpr float mMu = 105.66f;

      private:
        const Particle** m_substructures = nullptr;
        const SecondaryVertices* m_vertices = nullptr;
        const PV::Vertex* m_pv = nullptr;
        unsigned m_total_number_of_composites = 0;
        unsigned m_index = 0;

      public:
        __host__ __device__ CompositeParticle(
          const Particle** children,
          const SecondaryVertices* vertices,
          const PV::Vertex* pv,
          unsigned number_of_children,
          unsigned total_number_of_composites,
          unsigned index) :
          Particle {number_of_children},
          m_substructures(children), m_vertices(vertices), m_pv(pv),
          m_total_number_of_composites(total_number_of_composites), m_index(index)
        {}

        __host__ __device__ const Particle* substructure(const unsigned substructure_index) const
        {
          assert(substructure_index < m_number_of_substructures);
          return m_substructures[m_total_number_of_composites * substructure_index + m_index];
        }

        __host__ __device__ const PV::Vertex* get_pv() const { return m_pv; }

        __host__ __device__ const SecondaryVertices* get_vertices() const { return m_vertices; }

        __host__ __device__ SecondaryVertex vertex() const { return m_vertices->vertex(m_index); }

        __host__ __device__ PV::Vertex pv() const { return *m_pv; }

        __host__ __device__ float x() const { return vertex().x(); }

        __host__ __device__ float y() const { return vertex().y(); }

        __host__ __device__ float z() const { return vertex().z(); }

        __host__ __device__ float px() const { return vertex().px(); }

        __host__ __device__ float py() const { return vertex().py(); }

        __host__ __device__ float pz() const { return vertex().pz(); }

        __host__ __device__ float pt() const { return vertex().pt(); }

        __host__ __device__ float p() const { return vertex().p(); }

        //__host__ __device__ unsigned number_of_substructures() const override { return m_number_of_substructures; }

        // TODO: Some of these quantities are expensive to calculate, so it
        // might be a good idea to store them in an "extra info" array. Need to
        // see how the timing shakes out.
        __host__ __device__ float e() const
        {
          float energy = 0.f;
          for (unsigned i = 0; i < number_of_substructures(); i++) {
            const auto substr = substructure(i);
            if (substr->number_of_substructures() == 1) {
              energy += static_cast<const BasicParticle*>(substr)->e(mPi);
            }
            // Assume at most one level of recursion. Needed for the HIP build.
            else {
              for (unsigned j = 0; j < substr->number_of_substructures()) {
                const auto subsubstr = static_cast<const CompositeParticle*>(substr)->substructure(j);
                energy += static_cast<const BasicParticle*>(subsubstr)->e();
              }
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
              sum += static_cast<const BasicParticle*>(substr)->pt();
            }
            else {
              for (unsigned j = 0; j < substr->number_of_substructures()) {
                const auto subsubstr = static_cast<const CompositeParticle*>(substr)->substructure(j);
                sum += static_cast<const BasicParticle*>(subsubstr)->pt();
              }
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
          if (substr1->number_of_substructures() != 1 || substr2->number_of_substructures() != 1) {
            return 0.f;
          }
          energy += static_cast<const BasicParticle*>(substr1)->e(m1);
          energy += static_cast<const BasicParticle*>(substr2)->e(m2);
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
          const float invdet =
            1.f / (2.f * c10 * c20 * c21 - c11 * c20 * c20 - c00 * c21 * c21 + c00 * c11 * c22 - c22 * c10 * c10);
          const float invc00 = (c11 * c22 - c21 * c21) * invdet;
          const float invc10 = (c20 * c21 - c10 * c22) * invdet;
          const float invc11 = (c00 * c22 - c20 * c20) * invdet;
          const float invc20 = (c10 * c21 - c11 * c20) * invdet;
          const float invc21 = (c10 * c20 - c00 * c21) * invdet;
          const float invc22 = (c00 * c11 - c10 * c10) * invdet;
          return invc00 * dx * dx + invc11 * dy * dy + invc22 * dz * dz + 2.f * invc20 * dx * dz +
                 2.f * invc21 * dy * dz + 2.f * invc10 * dx * dy;
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

        __host__ __device__ float dz() const
        {
          if (m_pv == nullptr) return 0.f;
          return vertex().z() - pv().position.z;
        }

        __host__ __device__ float eta() const
        {
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
                                (vrt.px() * dy - dx * vrt.py()) * (vrt.px() * dy - dx * vrt.py())) /
                               (loc_fd * loc_fd);
          return sqrtf(mvis * mvis + pperp2) + sqrtf(pperp2);
        }

        __host__ __device__ float minipchi2() const
        {
          float val = -1;
          for (unsigned i = 0; i < number_of_substructures(); i++) {
            float tmp = -1;
            const auto substr = substructure(i);
            if (substr->m_number_of_substructures == 1) {
              tmp = static_cast<const BasicParticle*>(substr)->ip_chi2();
            }
            else {
              for (unsigned j = 0; j < substr->number_of_substructures()) {
                const auto subsubstr = static_cast<const CompositeParticle*>(substr)->substructure(j);
                const auto tmptmp = static_cast<const BasicParticle*>(subsubstr)->ip_chi2();
                if (tmptmp < tmp || tmp < 0) tmp = tmptmp;
              }
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
              tmp = static_cast<const BasicParticle*>(substr)->ip();
            }
            else {
              for (unsigned j = 0; j < substr->number_of_substructures()) {
                const auto subsubstr = static_cast<const CompositeParticle*>(substr)->substructure(j);
                const auto tmptmp = static_cast<const BasicParticle*>(subsubstr)->ip();
                if (tmptmp < tmp || tmp < 0) tmp = tmptmp;
              }
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
              tmp = static_cast<const BasicParticle*>(substr)->p();
            }
            else {
              tmp = static_cast<const CompositeParticle*>(substr)->p();
            }
            if (tmp < val || val < 0) val = tmp;
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
              tmp = static_cast<const BasicParticle*>(substr)->pt();
            }
            else {
              tmp = static_cast<const CompositeParticle*>(substr)->pt();
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
            const auto track1 = static_cast<const BasicParticle*>(substr1);
            const auto state1 = track1->state();
            xA = state1.x();
            yA = state1.y();
            zA = state1.z();
            txA = state1.tx();
            tyA = state1.ty();
          }
          else {
            const auto sv1 = static_cast<const CompositeParticle*>(substr1);
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
          if (substr2->number_of_substructures() == 1) {
            const auto track2 = static_cast<const BasicParticle*>(substr2);
            const auto state2 = track2->state();
            xB = state2.x();
            yB = state2.y();
            zB = state2.z();
            txB = state2.tx();
            tyB = state2.ty();
          }
          else {
            const auto sv2 = static_cast<const CompositeParticle*>(substr2);
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
            float firstA = txA * (xA - xB) + tyA * (yA - yB) + (zA - zB);
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
          if (substr1->number_of_substructures() != 1 || substr2->number_of_substructures() != 1) return false;
          return static_cast<const BasicParticle*>(substr1)->is_muon() &&
                 static_cast<const BasicParticle*>(substr2)->is_muon();
        }

        __host__ __device__ float clone_sin2() const
        {
          if (!is_dimuon()) return -1.f;
          const auto substr1 = substructure(0);
          const auto substr2 = substructure(1);
          const auto state1 = static_cast<const BasicParticle*>(substr1)->state();
          const auto state2 = static_cast<const BasicParticle*>(substr2)->state();
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

      struct CompositeParticles : ParticleContainer {
      private:
        // const CompositeParticle* m_composite = nullptr;
        unsigned m_offset = 0;

      public:
        __host__ __device__
        CompositeParticles(const CompositeParticle* composite, const unsigned* offsets, unsigned event_number) :
          ParticleContainer {composite + offsets[event_number], offsets[event_number + 1] - offsets[event_number]},
          m_offset(offsets[event_number])
        {}

        __host__ __device__ const CompositeParticle& particle(unsigned particle_index) const
        {
          return static_cast<const CompositeParticle*>(m_particle)[particle_index];
        }

        // __host__ __device__ unsigned size() const { return m_size; }

        __host__ __device__ unsigned offset() const { return m_offset; }
      };
    } // namespace Physics
  }   // namespace Views
} // namespace Allen
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
      protected:
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

        __host__ __device__ unsigned get_id(const unsigned index) const
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

        __host__ __device__ const Allen::Views::Velo::Consolidated::Track& velo_track() const {
          assert(has_velo());
          return *m_velo_segment;
        }

        __host__ __device__ const Allen::Views::UT::Consolidated::Track& ut_track() const {
          assert(has_ut());
          return *m_ut_segment;
        }

        __host__ __device__ const Allen::Views::SciFi::Consolidated::Track& scifi_track() const {
          assert(has_scifi());
          return *m_scifi_segment;
        }
        
      };

      struct LongTrack : ILHCbIDSequence<LongTrack>, Track {
        friend ILHCbIDSequence<LongTrack>;

      private:
        __host__ __device__ unsigned number_of_ids_impl() const {
          return number_of_hits();
        }

        __host__ __device__ unsigned id_impl(const unsigned index) const {
          return get_id(index);
        }

      public:
        __host__ __device__ LongTrack(
          const Allen::Views::Velo::Consolidated::Track* velo_segment,
          const Allen::Views::UT::Consolidated::Track* ut_segment,
          const Allen::Views::SciFi::Consolidated::Track* scifi_segment) :
          Track {velo_segment, ut_segment, scifi_segment}
        {}

        __host__ __device__ float qop() const {
          return m_scifi_segment->qop();
        }
      };

      struct LongTracks : ILHCbIDContainer<LongTracks> {
        friend Allen::ILHCbIDContainer<LongTracks>;
        constexpr static auto TypeID = Allen::TypeIDs::LongTracks;

      private:
        const LongTrack* m_track;
        unsigned m_size = 0;
        unsigned m_offset = 0;

        __host__ __device__ unsigned number_of_id_sequences_impl() const {
          return m_size;
        }

        __host__ __device__ const LongTrack& id_sequence_impl(const unsigned index) const {
          assert(index < number_of_id_sequences_impl());
          return m_track[index];
        }

      public:
        __host__ __device__ LongTracks(const LongTrack* track, const unsigned* offset_tracks, const unsigned event_number) :
          m_track(track + offset_tracks[event_number]),
          m_size(offset_tracks[event_number + 1] - offset_tracks[event_number]),
          m_offset(offset_tracks[event_number])
        {}

        __host__ __device__ unsigned size() const { return m_size; }

        __host__ __device__ const LongTrack& track(const unsigned index) const {
          return id_sequence_impl(index);
        }

        __host__ __device__ unsigned offset() const { return m_offset; }
      };


      using MultiEventLongTracks = Allen::MultiEventContainer<LongTracks>;

      struct TrackContainer {
      private:
        const Track* m_track = nullptr;
        unsigned m_size = 0;

      public:
        __host__ __device__ TrackContainer(const Track* track, const unsigned size) :
          m_track(track), m_size(size)
        {}

        __host__ __device__ unsigned size() const { return m_size; }

        

        virtual __host__ __device__ ~TrackContainer() {}
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
        virtual __host__ __device__ Allen::TypeIDs type_id() const = 0;
        virtual __host__ __device__ ~Particle() {}
      };

      template<typename T>
      struct IParticle : Particle {
        __host__ __device__ unsigned number_of_children() const {
          return static_cast<const T*>(this)->number_of_children_impl();
        }

        __host__ __device__ const Particle* child(const unsigned i) const {
          return static_cast<const T*>(this)->child_impl(i);
        }

        __host__ __device__ Allen::TypeIDs type_id() const override { return Allen::identify<T>(); }
      };

      template<typename T>
      struct IParticleContainer {
        __host__ __device__ unsigned size() const { 
          return static_cast<const T*>(this)->size_impl();
        }
        __host__ __device__ const auto& particle(const unsigned i) const {
          return static_cast<const T*>(this)->particle_impl(i);
        }
      };

      // template<typename T>
      // struct MultiEventParticleContainer : MultiEventContainer<T>, IMultiEventParticleContainer {
      //   using MultiEventContainer<T>::MultiEventContainer;
      //   __host__ __device__ unsigned number_of_containers() const override
      //   {
      //     return MultiEventContainer<T>::number_of_events();
      //   }
      //   __host__ __device__ const ParticleContainer& particle_container(const unsigned event_number) const override
      //   {
      //     return MultiEventContainer<T>::container(event_number);
      //   }
      // };

      // Is it necessary for BasicParticle to inherit from an ILHCbIDStructure to
      // work with aggregates in the SelReport writer?
      struct BasicParticle : IParticle<BasicParticle> {
        friend IParticle<BasicParticle>;
        constexpr static auto TypeID = Allen::TypeIDs::BasicParticle;

      private:
        const Track* m_track = nullptr;
        const KalmanStates* m_states = nullptr;
        const PV::Vertex* m_pv = nullptr; // PV event model should be rebuilt too.
        // Could store muon and calo PID in a single array, but they're created by
        // different algorithms and might not always exist.
        const uint8_t* m_lepton_id = nullptr;
        unsigned m_index = 0;

        __host__ __device__ unsigned number_of_children_impl() const {
          return 1;
        }

        __host__ __device__ const Particle* child_impl(const unsigned) const {
          return this;
        }

      public:
        __host__ __device__ BasicParticle(
          const Track* track,
          const KalmanStates* states,
          const PV::Vertex* pv,
          const uint8_t* lepton_id,
          const unsigned index) :
          m_track(track), m_states(states), m_pv(pv), m_lepton_id(lepton_id), m_index(index)
        {}

        // Accessors to allow copying. Is there a better way to handle this?
        __host__ __device__ const Track* get_track() const { return m_track; }

        __host__ __device__ const KalmanStates* get_states() const { return m_states; }

        __host__ __device__ const PV::Vertex* get_pv() const { return m_pv; }

        //__host__ __device__ const bool* get_muon_id() const { return m_muon_id; }
        __host__ __device__ const uint8_t* get_lepton_id() const { return m_lepton_id; }

        __host__ __device__ unsigned get_index() const { return m_index; }

        __host__ __device__ unsigned number_of_ids() const { return m_track->number_of_hits(); }

        __host__ __device__ unsigned id(const unsigned index) const { return m_track->get_id(index); }

        __host__ __device__ KalmanState state() const { return m_states->state(m_index); }

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
          if (m_lepton_id == nullptr) return false;
          return (m_lepton_id[m_index] & 1);
        }

        __host__ __device__ bool is_electron() const
        {
          if (m_lepton_id == nullptr) return false;
          return ((m_lepton_id[m_index] & (1 << 1)) >> 1);
        }

        __host__ __device__ bool is_lepton() const
        {
          if (m_lepton_id == nullptr) return false;
          return m_lepton_id[m_index];
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
          return (dx * dx * cov11 - 2 * dx * dy * cov10 + dy * dy * cov00) / (cov00 * cov11 - cov10 * cov10);
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

      struct BasicParticles : IParticleContainer<BasicParticles> {
        friend IParticleContainer<BasicParticles>;
        constexpr static auto TypeID = Allen::TypeIDs::BasicParticles;

      private:
        const BasicParticle* m_particle;
        unsigned m_size = 0;
        unsigned m_offset = 0;

        __host__ __device__ unsigned size_impl() const {
          return m_size;
        }

        __host__ __device__ const BasicParticle& particle_impl(const unsigned i) const {
          assert(i < m_size);
          return m_particle[i];
        }

      public:
        __host__ __device__
        BasicParticles(const BasicParticle* track, const unsigned* track_offsets, const unsigned event_number) :
          m_particle(track + track_offsets[event_number]),
          m_size(track_offsets[event_number + 1] - track_offsets[event_number]),
          m_offset(track_offsets[event_number])
        {}

        __host__ __device__ const BasicParticle* particle_pointer(const unsigned index) const
        {
          return static_cast<const BasicParticle*>(m_particle) + index;
        }

        __host__ __device__ unsigned offset() const { return m_offset; }
      };

      struct CompositeParticle : IParticle<CompositeParticle> {
        // TODO: Get these masses from somewhere else.
        static constexpr float mPi = 139.57f;
        static constexpr float mMu = 105.66f;
        friend IParticle<CompositeParticle>;
        constexpr static auto TypeID = Allen::TypeIDs::CompositeParticle;

      private:
        const Particle** m_children = nullptr;
        const SecondaryVertices* m_vertices = nullptr;
        const PV::Vertex* m_pv = nullptr;
        unsigned m_number_of_children = 0;
        unsigned m_total_number_of_composites = 0;
        unsigned m_index = 0;

        __host__ __device__ unsigned number_of_children_impl() const {
          return m_number_of_children;
        }

        __host__ __device__ const Particle* child_impl(const unsigned i) const {
          assert(i < number_of_children());
          return m_children[i];
        }

      public:
        __host__ __device__ CompositeParticle(
          const Particle** children,
          const SecondaryVertices* vertices,
          const PV::Vertex* pv,
          unsigned number_of_children,
          unsigned total_number_of_composites,
          unsigned index) :
          m_children(children),
          m_vertices(vertices), m_pv(pv),
          m_number_of_children(number_of_children),
          m_total_number_of_composites(total_number_of_composites), m_index(index)
        {}

        __host__ __device__ const PV::Vertex* get_pv() const { return m_pv; }

        __host__ __device__ const SecondaryVertices* get_vertices() const { return m_vertices; }

        __host__ __device__ SecondaryVertex vertex() const { return m_vertices->vertex(m_index); }

        __host__ __device__ float x() const { return vertex().x(); }

        __host__ __device__ float y() const { return vertex().y(); }

        __host__ __device__ float z() const { return vertex().z(); }

        __host__ __device__ float px() const { return vertex().px(); }

        __host__ __device__ float py() const { return vertex().py(); }

        __host__ __device__ float pz() const { return vertex().pz(); }

        __host__ __device__ float pt() const { return vertex().pt(); }

        __host__ __device__ float p() const { return vertex().p(); }

        __host__ __device__ float transform_reduce(
          float (*transformer)(const BasicParticle*),
          float (*reducer)(float, float),
          float initial_value) const
        {
          float value = initial_value;
          for (unsigned i = 0; i < number_of_children(); i++) {
            const auto substr = child(i);
            if (substr->type_id() == Allen::TypeIDs::BasicParticle) {
              float tmp = transformer(static_cast<const BasicParticle*>(substr));
              value = reducer(value, tmp);
            }
            else {
              const auto composite_substr = static_cast<const CompositeParticle*>(substr);
              for (unsigned j = 0; j < composite_substr->number_of_children(); j++) {
                const auto subsubstr = composite_substr->child(j);
                float tmp = transformer(static_cast<const BasicParticle*>(subsubstr));
                value = reducer(value, tmp);
              }
            }
          }
          return value;
        }

        // TODO: Some of these quantities are expensive to calculate, so it
        // might be a good idea to store them in an "extra info" array. Need to
        // see how the timing shakes out.
        __host__ __device__ float e() const
        {
          float energy = transform_reduce(
            [](const BasicParticle* p) { return p->e(mPi); }, [](float f1, float f2) { return f1 + f2; }, 0.f);
          return energy;
        }

        __host__ __device__ float sumpt() const
        {
          float sum = transform_reduce(
            [](const BasicParticle* p) { return p->pt(); }, [](float f1, float f2) { return f1 + f2; }, 0.f);
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
          const auto substr1 = child(0);
          const auto substr2 = child(1);
          if (substr1->type_id() != Allen::TypeIDs::BasicParticle || 
              substr2->type_id() != Allen::TypeIDs::BasicParticle) {
            return 0.f;
          }
          energy += static_cast<const BasicParticle*>(substr1)->e(m1);
          energy += static_cast<const BasicParticle*>(substr2)->e(m2);
          return sqrtf(energy * energy - vertex().p2());
        }

        __host__ __device__ float mdipi() const { return m12(mPi, mPi); }

        __host__ __device__ float mdimu() const { return m12(mMu, mMu); }

        __host__ __device__ float fdchi2() const
        {
          if (m_pv == nullptr) return -1.f;
          const auto primary = get_pv();
          const auto vrt = vertex();
          const float dx = vrt.x() - primary->position.x;
          const float dy = vrt.y() - primary->position.y;
          const float dz = vrt.z() - primary->position.z;
          const float c00 = vrt.c00() + primary->cov00;
          const float c10 = vrt.c10() + primary->cov10;
          const float c11 = vrt.c11() + primary->cov11;
          const float c20 = vrt.c20() + primary->cov20;
          const float c21 = vrt.c21() + primary->cov21;
          const float c22 = vrt.c22() + primary->cov22;
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
          if (m_pv == nullptr) return -1.f;
          const auto primary = get_pv();
          const auto vrt = vertex();
          const float dx = vrt.x() - primary->position.x;
          const float dy = vrt.y() - primary->position.y;
          const float dz = vrt.z() - primary->position.z;
          return sqrtf(dx * dx + dy * dy + dz * dz);
        }

        __host__ __device__ float dz() const
        {
          if (m_pv == nullptr) return 0.f;
          return vertex().z() - get_pv()->position.z;
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
          const auto primary = get_pv();
          const auto vrt = vertex();
          const float dx = vrt.x() - primary->position.x;
          const float dy = vrt.y() - primary->position.y;
          const float dz = vrt.z() - primary->position.z;
          const float loc_fd = sqrtf(dx * dx + dy * dy + dz * dz);
          const float pperp2 = ((vrt.py() * dz - dy * vrt.pz()) * (vrt.py() * dz - dy * vrt.pz()) +
                                (vrt.pz() * dx - dz * vrt.px()) * (vrt.pz() * dx - dz * vrt.px()) +
                                (vrt.px() * dy - dx * vrt.py()) * (vrt.px() * dy - dx * vrt.py())) /
                               (loc_fd * loc_fd);
          return sqrtf(mvis * mvis + pperp2) + sqrtf(pperp2);
        }

        __host__ __device__ float minipchi2() const
        {
          float val = transform_reduce(
            [](const BasicParticle* p) { return p->ip_chi2(); },
            [](float f1, float f2) { return (f2 < f1 || f1 < 0) ? f2 : f1; },
            -1.f);
          return val;
        }

        __host__ __device__ float minip() const
        {
          float val = transform_reduce(
            [](const BasicParticle* p) { return p->ip(); },
            [](float f1, float f2) { return (f2 < f1 || f1 < 0) ? f2 : f1; },
            -1.f);
          return val;
        }

        __host__ __device__ float minp() const
        {
          float val = transform_reduce(
            [](const BasicParticle* p) { return p->p(); },
            [](float f1, float f2) { return (f2 < f1 || f1 < 0) ? f2 : f1; },
            -1.f);
          return val;
        }

        __host__ __device__ float minpt() const
        {
          float val = transform_reduce(
            [](const BasicParticle* p) { return p->pt(); },
            [](float f1, float f2) { return (f2 < f1 || f1 < 0) ? f2 : f1; },
            -1.f);
          return val;
        }

        __host__ __device__ float dira() const
        {
          if (m_pv == nullptr) return 0.f;
          const auto primary = get_pv();
          const auto vrt = vertex();
          const float dx = vrt.x() - primary->position.x;
          const float dy = vrt.y() - primary->position.y;
          const float dz = vrt.z() - primary->position.z;
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
          const auto substr1 = child(index1);
          if (substr1->type_id() == Allen::TypeIDs::BasicParticle) {
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
          const auto substr2 = child(index2);
          if (substr2->type_id() == Allen::TypeIDs::BasicParticle) {
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
          for (unsigned i = 0; i < number_of_children(); i++) {
            for (unsigned j = i + 1; j < number_of_children(); j++) {
              float loc_doca = doca(i, j);
              if (loc_doca > val) val = loc_doca;
            }
          }
          return val;
        }

        __host__ __device__ float doca12() const { return doca(0, 1); }

        __host__ __device__ float ip() const
        {
          if (m_pv == nullptr) return -1.f;
          const auto vrt = vertex();
          const auto primary = get_pv();
          float tx = vrt.px() / vrt.pz();
          float ty = vrt.py() / vrt.pz();
          float dz = primary->position.z - vrt.z();
          float dx = vrt.x() + dz * tx - primary->position.x;
          float dy = vrt.y() + dz * ty - primary->position.y;
          return sqrtf((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
        }

        __host__ __device__ bool is_dimuon() const
        {
          const auto substr1 = child(0);
          const auto substr2 = child(1);
          if (substr1->type_id() != Allen::TypeIDs::BasicParticle || 
              substr2->type_id() != Allen::TypeIDs::BasicParticle) return false;
          return static_cast<const BasicParticle*>(substr1)->is_muon() &&
                 static_cast<const BasicParticle*>(substr2)->is_muon();
        }

        __host__ __device__ bool is_dielectron() const
        {
          const auto substr1 = child(0);
          const auto substr2 = child(1);
          if (substr1->type_id() != Allen::TypeIDs::BasicParticle || 
              substr2->type_id() != Allen::TypeIDs::BasicParticle) return false;
          return static_cast<const BasicParticle*>(substr1)->is_electron() &&
                 static_cast<const BasicParticle*>(substr2)->is_electron();
        }

        __host__ __device__ bool is_dilepton() const
        {
          const auto substr1 = child(0);
          const auto substr2 = child(1);
          if (substr1->type_id() != Allen::TypeIDs::BasicParticle || 
              substr2->type_id() != Allen::TypeIDs::BasicParticle) return false;
          return static_cast<const BasicParticle*>(substr1)->is_lepton() &&
                 static_cast<const BasicParticle*>(substr2)->is_lepton();
        }

        __host__ __device__ float clone_sin2() const
        {
          const auto substr1 = child(0);
          const auto substr2 = child(1);
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

      struct CompositeParticles : IParticleContainer<CompositeParticles> {
        friend IParticleContainer<CompositeParticles>;
        static constexpr auto TypeID = Allen::TypeIDs::CompositeParticles;

      private:
        const CompositeParticle* m_particle;
        unsigned m_size = 0;
        unsigned m_offset = 0;

        __host__ __device__ unsigned size_impl() const {
          return m_size;
        }

        __host__ __device__ const CompositeParticle& particle_impl(const unsigned i) {
          assert(i < m_size);
          return m_particle[i];
        }

      public:
        __host__ __device__
        CompositeParticles(const CompositeParticle* composite, const unsigned* offsets, unsigned event_number) :
          m_particle(composite + offsets[event_number]), 
          m_size(offsets[event_number + 1] - offsets[event_number]),
          m_offset(offsets[event_number])
        {}

        __host__ __device__ const CompositeParticle& particle(unsigned particle_index) const
        {
          return static_cast<const CompositeParticle*>(m_particle)[particle_index];
        }

        __host__ __device__ unsigned offset() const { return m_offset; }
      };

      // struct IMultiEventParticleContainer {
      // private:
      //   unsigned m_number_of_events = 0;

      // public:
      //   __host__ __device__ IMultiEventParticleContainer(const unsigned number_of_events) :
      //     m_number_of_events(number_of_events)
      //   {}

      //   __host__ __device__ unsigned number_of_containers() const { return m_number_of_events; }
      //   virtual __host__ __device__ ~IMultiEventParticleContainer() {}
      // };

      // struct MultiEventBasicParticles : IMultiEventParticleContainer {
      // private:
      //   const BasicParticles* m_container = nullptr;

      // public:
      //   __host__ __device__ MultiEventBasicParticles(const BasicParticles* container, const unsigned number_of_events) :
      //     IMultiEventParticleContainer {number_of_events}, m_container(container)
      //   {}

      //   __host__ __device__ const BasicParticles& particle_container(const unsigned event_number) const
      //   {
      //     assert(event_number < number_of_containers());
      //     return m_container[event_number];
      //   }
      // };

      // struct MultiEventCompositeParticles : IMultiEventParticleContainer {
      // private:
      //   const CompositeParticles* m_container = nullptr;

      // public:
      //   __host__ __device__
      //   MultiEventCompositeParticles(const CompositeParticles* container, const unsigned number_of_events) :
      //     IMultiEventParticleContainer {number_of_events},
      //     m_container(container)
      //   {}

      //   __host__ __device__ const CompositeParticles& particle_container(const unsigned event_number) const
      //   {
      //     assert(event_number < number_of_containers());
      //     return m_container[event_number];
      //   }
      // };

      using MultiEventBasicParticles = Allen::MultiEventContainer<BasicParticles>;
      using MultiEventCompositeParticles = Allen::MultiEventContainer<CompositeParticles>;

    } // namespace Physics
  }   // namespace Views
} // namespace Allen
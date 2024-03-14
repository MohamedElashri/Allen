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
#include "MuonConsolidated.cuh"
#include "PV_Definitions.cuh"
#include "MassDefinitions.h"
#include "CaloCluster.cuh"

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
        PVTable() = default;

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
        const Allen::Views::Muon::Consolidated::Track* m_muon_segment = nullptr;
        const float* m_qop = nullptr;
        const float* m_ghost_probability = nullptr;

      public:
        Track() = default;

        __host__ __device__ Track(
          const Allen::Views::Velo::Consolidated::Track* velo_segment,
          const Allen::Views::UT::Consolidated::Track* ut_segment,
          const Allen::Views::SciFi::Consolidated::Track* scifi_segment,
          const Allen::Views::Muon::Consolidated::Track* muon_segment,
          const float* qop,
          const float* ghost_probability = nullptr) :
          m_velo_segment(velo_segment),
          m_ut_segment(ut_segment), m_scifi_segment(scifi_segment), m_muon_segment(muon_segment), m_qop(qop),
          m_ghost_probability(ghost_probability)
        {}
        __host__ __device__ float qop() const { return *m_qop; }
        __host__ __device__ float ghost_probability() const { return *m_ghost_probability; }

        enum struct segment { velo, ut, scifi, muon };

        template<segment t>
        __host__ __device__ bool has() const
        {
          if constexpr (t == segment::velo) {
            return m_velo_segment != nullptr;
          }
          else if constexpr (t == segment::ut) {
            return m_ut_segment != nullptr;
          }
          else if constexpr (t == segment::scifi) {
            return m_scifi_segment != nullptr;
          }
          else {
            return m_muon_segment != nullptr;
          }
        }

        template<segment t>
        __host__ __device__ auto track_segment() const
        {
          assert(has<t>());
          if constexpr (t == segment::velo) {
            return *m_velo_segment;
          }
          else if constexpr (t == segment::ut) {
            return *m_ut_segment;
          }
          else if constexpr (t == segment::scifi) {
            return *m_scifi_segment;
          }
          else {
            return *m_muon_segment;
          }
        }

        // Expose the pointers so the long track can be copied. Useful for
        // adding segments later.
        __host__ __device__ const float* qop_ptr() const { return m_qop; }
        __host__ __device__ const float* ghost_probability_ptr() const { return m_ghost_probability; }

        template<segment t>
        __host__ __device__ auto track_segment_ptr() const
        {
          if constexpr (t == segment::velo) {
            return m_velo_segment;
          }
          else if constexpr (t == segment::ut) {
            return m_ut_segment;
          }
          else if constexpr (t == segment::scifi) {
            return m_scifi_segment;
          }
          else {
            return m_muon_segment;
          }
        }

        template<segment t>
        __host__ __device__ unsigned number_of_segment_hits() const
        {
          if (!has<t>()) return 0;
          if constexpr (t == segment::velo) {
            return m_velo_segment->number_of_hits();
          }
          else if constexpr (t == segment::ut) {
            return m_ut_segment->number_of_ut_hits();
          }
          else if constexpr (t == segment::scifi) {
            return m_scifi_segment->number_of_scifi_hits();
          }
          else {
            return m_muon_segment->number_of_hits();
          }
        }

        __host__ __device__ unsigned number_of_hits() const
        {
          return number_of_segment_hits<segment::velo>() + number_of_segment_hits<segment::ut>() +
                 number_of_segment_hits<segment::scifi>() + number_of_segment_hits<segment::muon>();
        }

        __host__ __device__ unsigned get_id(const unsigned index) const
        {
          assert(index < number_of_hits());
          if (index < number_of_segment_hits<segment::velo>()) {
            return m_velo_segment->id(index);
          }
          else if (index < number_of_segment_hits<segment::velo>() + number_of_segment_hits<segment::ut>()) {
            return m_ut_segment->id(index - number_of_segment_hits<segment::velo>());
          }
          else if (
            index < number_of_segment_hits<segment::velo>() + number_of_segment_hits<segment::ut>() +
                      number_of_segment_hits<segment::scifi>()) {
            return m_scifi_segment->id(
              index - number_of_segment_hits<segment::velo>() - number_of_segment_hits<segment::ut>());
          }
          else {
            return m_muon_segment->id(
              index - number_of_segment_hits<segment::velo>() - number_of_segment_hits<segment::ut>() -
              number_of_segment_hits<segment::scifi>());
          }
        }
      };

      struct DownstreamTrack : ILHCbIDSequence<DownstreamTrack>, Track {
        friend ILHCbIDSequence<DownstreamTrack>;

      private:
        __host__ __device__ unsigned number_of_ids_impl() const { return number_of_hits(); }

        __host__ __device__ unsigned id_impl(const unsigned index) const { return get_id(index); }

      public:
        DownstreamTrack() = default;

        __host__ __device__ DownstreamTrack(
          const Allen::Views::UT::Consolidated::Track* ut_segment,
          const Allen::Views::SciFi::Consolidated::Track* scifi_segment,
          const float* qop) :
          Track {nullptr, ut_segment, scifi_segment, nullptr, qop}
        {}
      };

      struct DownstreamTracks : ILHCbIDContainer<DownstreamTracks> {
        friend Allen::ILHCbIDContainer<DownstreamTracks>;
        constexpr static auto TypeID = TypeIDs::DownstreamTracks;

      private:
        const DownstreamTrack* m_track;
        unsigned m_size = 0;
        unsigned m_offset = 0;

        __host__ __device__ unsigned number_of_id_sequences_impl() const { return m_size; }

        __host__ __device__ const DownstreamTrack& id_sequence_impl(const unsigned index) const
        {
          assert(index < number_of_id_sequences_impl());
          return m_track[index];
        }

      public:
        DownstreamTracks() = default;

        __host__ __device__
        DownstreamTracks(const DownstreamTrack* track, const unsigned* offset_tracks, const unsigned event_number) :
          m_track(track + offset_tracks[event_number]),
          m_size(offset_tracks[event_number + 1] - offset_tracks[event_number]), m_offset(offset_tracks[event_number])
        {}

        __host__ __device__ unsigned size() const { return m_size; }

        __host__ __device__ float qop(const unsigned index) const { return m_track[index].qop(); }

        __host__ __device__ const DownstreamTrack& track(const unsigned index) const { return id_sequence_impl(index); }

        __host__ __device__ unsigned offset() const { return m_offset; }
      };
      using MultiEventDownstreamTracks = Allen::MultiEventContainer<DownstreamTracks>;

      struct LongTrack : ILHCbIDSequence<LongTrack>, Track {
        friend ILHCbIDSequence<LongTrack>;

      private:
        __host__ __device__ unsigned number_of_ids_impl() const { return number_of_hits(); }

        __host__ __device__ unsigned id_impl(const unsigned index) const { return get_id(index); }

      public:
        LongTrack() = default;

        __host__ __device__ LongTrack(
          const Allen::Views::Velo::Consolidated::Track* velo_segment,
          const Allen::Views::UT::Consolidated::Track* ut_segment,
          const Allen::Views::SciFi::Consolidated::Track* scifi_segment,
          const Allen::Views::Muon::Consolidated::Track* muon_segment,
          const float* qop,
          const float* ghost_probability = nullptr) :
          Track {velo_segment, ut_segment, scifi_segment, muon_segment, qop, ghost_probability}
        {}
      };

      struct LongTracks : ILHCbIDContainer<LongTracks> {
        friend Allen::ILHCbIDContainer<LongTracks>;
        constexpr static auto TypeID = TypeIDs::LongTracks;

      private:
        const LongTrack* m_track;
        unsigned m_size = 0;
        unsigned m_offset = 0;

        __host__ __device__ unsigned number_of_id_sequences_impl() const { return m_size; }

        __host__ __device__ const LongTrack& id_sequence_impl(const unsigned index) const
        {
          assert(index < number_of_id_sequences_impl());
          return m_track[index];
        }

      public:
        LongTracks() = default;

        __host__ __device__
        LongTracks(const LongTrack* track, const unsigned* offset_tracks, const unsigned event_number) :
          m_track(track + offset_tracks[event_number]),
          m_size(offset_tracks[event_number + 1] - offset_tracks[event_number]), m_offset(offset_tracks[event_number])
        {}

        __host__ __device__ unsigned size() const { return m_size; }

        __host__ __device__ float qop(const unsigned index) const { return m_track[index].qop(); }

        __host__ __device__ const LongTrack& track(const unsigned index) const { return id_sequence_impl(index); }

        __host__ __device__ unsigned offset() const { return m_offset; }
      };

      using MultiEventLongTracks = Allen::MultiEventContainer<LongTracks>;

      struct IParticle : Identifiable {
        using Identifiable::Identifiable;
      };

      template<typename T>
      struct IParticleContainer {
        __host__ __device__ unsigned size() const { return static_cast<const T*>(this)->size_impl(); }
        __host__ __device__ const auto& particle(const unsigned i) const
        {
          return static_cast<const T*>(this)->particle_impl(i);
        }
      };

      struct BasicParticle : ILHCbIDSequence<BasicParticle>, IParticle {
        friend ILHCbIDSequence<BasicParticle>;
        constexpr static auto TypeID = Allen::TypeIDs::BasicParticle;

      private:
        const Track* m_track = nullptr;
        const KalmanStates* m_states = nullptr;
        const PV::Vertex* m_pv = nullptr; // PV event model should be rebuilt too.
        // Could store muon and calo PID in a single array, but they're created by
        // different algorithms and might not always exist.
        unsigned m_index = 0;
        uint8_t m_lepton_id = 0;

        __host__ __device__ unsigned number_of_ids_impl() const { return m_track->number_of_hits(); }

        __host__ __device__ unsigned id_impl(const unsigned index) const { return m_track->get_id(index); }

      public:
        BasicParticle() = default;

        __host__ __device__ BasicParticle(
          const Track* track,
          const KalmanStates* states,
          const PV::Vertex* pv,
          unsigned index,
          uint8_t lepton_id) :
          IParticle(TypeID),
          m_track(track), m_states(states), m_pv(pv), m_index(index), m_lepton_id(lepton_id)
        {
          assert(m_states != nullptr);
        }

        __host__ __device__ bool has_pv() const { return m_pv != nullptr; }

        __host__ __device__ const Track& track() const { return *m_track; }

        __host__ __device__ const PV::Vertex& pv() const
        {
          assert(has_pv());
          return *m_pv;
        }

        __host__ __device__ KalmanState state() const { return m_states->state(m_index); }

        // TODO: For now, we need to access the particle index for electron
        // lines that use bremsstrahlung-corrected momentum. In the longer term,
        // this should be accessed with some view equivalent to the CPU-side
        // CaloHypo.
        __host__ __device__ unsigned get_index() const { return m_index; }

        __host__ __device__ bool is_muon() const { return m_lepton_id & 1; }

        __host__ __device__ bool is_electron() const { return (m_lepton_id & 2) != 0; }

        __host__ __device__ bool is_lepton() const { return m_lepton_id; }

        __host__ __device__ float chi2() const { return state().chi2(); }

        __host__ __device__ unsigned ndof() const { return state().ndof(); }

        __host__ __device__ float ip_chi2() const
        {
          if (!has_pv()) {
            return -999.f;
          }

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
          if (!has_pv()) {
            return -999.f;
          }

          const float tx = state().tx();
          const float ty = state().ty();
          const float dz = m_pv->position.z - state().z();
          const float dx = state().x() + dz * tx - m_pv->position.x;
          const float dy = state().y() + dz * ty - m_pv->position.y;
          return sqrtf((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
        }

        __host__ __device__ float ip_x() const
        {
          if (!has_pv()) {
            return -999.f;
          }

          const float tx = state().tx();
          const float dz = m_pv->position.z - state().z();
          return state().x() + dz * tx - m_pv->position.x;
        }

        __host__ __device__ float ip_y() const
        {
          if (!has_pv()) {
            return -999.f;
          }

          const float ty = state().ty();
          const float dz = m_pv->position.z - state().z();
          return state().y() + dz * ty - m_pv->position.y;
        }
      };

      struct BasicParticles : IParticleContainer<BasicParticles> {
        friend IParticleContainer<BasicParticles>;
        constexpr static auto TypeID = Allen::TypeIDs::BasicParticles;

      private:
        const BasicParticle* m_particle;
        unsigned m_size = 0;
        unsigned m_offset = 0;

        __host__ __device__ unsigned size_impl() const { return m_size; }

        __host__ __device__ const BasicParticle& particle_impl(const unsigned i) const
        {
          assert(i < m_size);
          return m_particle[i];
        }

      public:
        BasicParticles() = default;

        __host__ __device__
        BasicParticles(const BasicParticle* track, const unsigned* track_offsets, const unsigned event_number) :
          m_particle(track + track_offsets[event_number]),
          m_size(track_offsets[event_number + 1] - track_offsets[event_number]), m_offset(track_offsets[event_number])
        {}

        __host__ __device__ const BasicParticle* particle_pointer(const unsigned index) const
        {
          return static_cast<const BasicParticle*>(m_particle) + index;
        }

        __host__ __device__ unsigned offset() const { return m_offset; }
      };

      struct NeutralBasicParticle : IParticle {
        constexpr static auto TypeID = Allen::TypeIDs::NeutralBasicParticle;

      private:
        const CaloCluster* m_calo_cluster;

      public:
        NeutralBasicParticle() = default;

        __host__ __device__ NeutralBasicParticle(const CaloCluster* calo_cluster) :
          IParticle(TypeID), m_calo_cluster(calo_cluster)
        {
          assert(m_calo_cluster != nullptr);
        }

        __host__ __device__ const CaloCluster& cluster() const { return *m_calo_cluster; }

        __host__ __device__ float et() const
        {
          const auto c = cluster();
          const float r2 = c.x * c.x + c.y * c.y;
          const float z = Calo::Constants::z;
          const float sint = sqrtf(r2 / (r2 + z * z));
          return c.e * sint;
        }
      };

      struct NeutralBasicParticles : IParticleContainer<NeutralBasicParticles> {
        friend IParticleContainer<NeutralBasicParticles>;
        constexpr static auto TypeID = Allen::TypeIDs::NeutralBasicParticles;

      private:
        const NeutralBasicParticle* m_particle;
        unsigned m_size = 0;
        unsigned m_offset = 0;

        __host__ __device__ unsigned size_impl() const { return m_size; }

        __host__ __device__ const NeutralBasicParticle& particle_impl(const unsigned i) const { return m_particle[i]; }

      public:
        NeutralBasicParticles() = default;

        __host__ __device__ NeutralBasicParticles(
          const NeutralBasicParticle* particle,
          const unsigned* offsets,
          const unsigned event_number) :
          m_particle(particle + offsets[event_number]),
          m_size(offsets[event_number + 1] - offsets[event_number]), m_offset(offsets[event_number])
        {}

        __host__ __device__ unsigned offset() const { return m_offset; }

        __host__ __device__ const NeutralBasicParticle* particle_pointer(const unsigned index) const
        {
          return static_cast<const NeutralBasicParticle*>(m_particle) + index;
        }
      };

      struct CompositeParticle : IParticle {
        // TODO: Get these masses from somewhere else.
        static constexpr float mPi = 139.57f;
        static constexpr float mMu = 105.66f;
        constexpr static auto TypeID = Allen::TypeIDs::CompositeParticle;

      private:
        std::array<const IParticle*, 4> m_children = {nullptr, nullptr, nullptr, nullptr};
        const SecondaryVertices* m_vertices = nullptr;
        const PV::Vertex* m_pv = nullptr;
        unsigned m_size = 0;
        unsigned m_index = 0;

        template<typename T>
        __host__ __device__ bool is_di(const T& fn) const
        {
          const auto a = dyn_cast<const BasicParticle*>(child(0));
          const auto b = dyn_cast<const BasicParticle*>(child(1));
          if (!a || !b) {
            return false;
          }
          return fn(a) && fn(b);
        }

        template<typename T, typename U, typename R>
        __host__ __device__ T transform_reduce(const U& transformer, const R& reducer, const T initial_value) const
        {
          T value = initial_value;
          for (unsigned i = 0; i < number_of_children(); ++i) {
            const auto c = child(i);
            const auto basic_particle = dyn_cast<const BasicParticle*>(c);
            if (basic_particle) {
              value = reducer(value, transformer(basic_particle));
            }
            else {
              const auto composite_particle = static_cast<const CompositeParticle*>(c);
              for (unsigned j = 0; j < composite_particle->number_of_children(); j++) {
                const auto cc = composite_particle->child(j);
                value = reducer(value, transformer(static_cast<const BasicParticle*>(cc)));
              }
            }
          }
          return value;
        }

      public:
        CompositeParticle() = default;

        __host__ __device__ CompositeParticle(
          const std::array<const IParticle*, 4>& children,
          const SecondaryVertices* vertices,
          const PV::Vertex* pv,
          unsigned size,
          unsigned index) :
          IParticle(TypeID),
          m_children(children), m_vertices(vertices), m_pv(pv), m_size(size), m_index(index)
        {
          for (unsigned i = 0; i < m_children.size(); i++) {
            if (i < m_size)
              assert(m_children[i] != nullptr);
            else
              assert(m_children[i] == nullptr);
          }
        }

        __host__ __device__ bool has_pv() const { return m_pv != nullptr; }

        __host__ __device__ const PV::Vertex& pv() const
        {
          assert(has_pv());
          return *m_pv;
        }

        __host__ __device__ unsigned number_of_children() const { return m_size; }

        __host__ __device__ const IParticle* child(const unsigned i) const
        {
          assert(i < number_of_children());
          return m_children[i];
        }

        __host__ __device__ bool has_vertex() const { return m_vertices != nullptr; }

        __host__ __device__ SecondaryVertex vertex() const
        {
          assert(has_vertex());
          return m_vertices->vertex(m_index);
        }

        // TODO: Some of these quantities are expensive to calculate, so it
        // might be a good idea to store them in an "extra info" array. Need to
        // see how the timing shakes out.
        __host__ __device__ float e() const
        {
          return transform_reduce(
            [](const BasicParticle* p) { return p->state().e(mPi); }, [](float f1, float f2) { return f1 + f2; }, 0.f);
        }

        __host__ __device__ float sumpt() const
        {
          return transform_reduce(
            [](const BasicParticle* p) { return p->state().pt(); }, [](float f1, float f2) { return f1 + f2; }, 0.f);
        }

        __host__ __device__ int charge() const
        {
          return transform_reduce(
            [](const BasicParticle* p) { return p->state().charge(); }, [](int f1, int f2) { return f1 + f2; }, 0);
        }

        __host__ __device__ float m() const
        {
          const float energy = e();
          return sqrtf(energy * energy - vertex().p2());
        }

        __host__ __device__ float m12(const float m1, const float m2) const
        {

          auto get_p2 = [](auto particle) -> float {
            auto basicp = dyn_cast<const BasicParticle*>(particle);
            if (basicp) {
              const auto mom = basicp->state().p();
              return mom * mom;
            }
            else {
              auto compp = static_cast<const CompositeParticle*>(particle);
              return compp->vertex().p2();
            }
          };

          const auto energy = sqrtf(get_p2(child(0)) + m1 * m1) + sqrtf(get_p2(child(1)) + m2 * m2);
          return sqrtf(energy * energy - vertex().p2());
        }

        __host__ __device__ float mdipi() const { return m12(Allen::mPi, Allen::mPi); }

        __host__ __device__ float mdimu() const { return m12(Allen::mMu, Allen::mMu); }

        __host__ __device__ float fdchi2() const
        {
          if (!has_pv()) return -1.f;
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
          if (!has_pv()) return -1.f;
          const auto primary = pv();
          const auto vrt = vertex();
          const float dx = vrt.x() - primary.position.x;
          const float dy = vrt.y() - primary.position.y;
          const float dz = vrt.z() - primary.position.z;
          return sqrtf(dx * dx + dy * dy + dz * dz);
        }

        __host__ __device__ float ctau() const
        {
          if (!has_pv()) return -1.f;
          return m() * fd() / vertex().p();
        }

        __host__ __device__ float ctau(const float mass) const
        {
          if (!has_pv()) return -1.f;
          return mass * fd() / vertex().p();
        }

        __host__ __device__ float dz() const
        {
          if (!has_pv()) return 0.f;
          return vertex().z() - pv().position.z;
        }

        __host__ __device__ float drho() const
        {
          if (!has_pv()) return -1.f;
          const auto primary = pv();
          const auto vrt = vertex();
          const float dx = vrt.x() - primary.position.x;
          const float dy = vrt.y() - primary.position.y;
          return sqrtf(dx * dx + dy * dy);
        }

        __host__ __device__ float eta() const
        {
          if (!has_pv()) return 0.f;
          return atanhf(dz() / fd());
        }

        __host__ __device__ float mcor() const
        {
          if (!has_pv()) return 0.f;
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
          return transform_reduce(
            [](const BasicParticle* p) { return p->ip_chi2(); },
            [](float f1, float f2) { return (f2 < f1 || f1 < 0) ? f2 : f1; },
            -1.f);
        }

        __host__ __device__ float minip() const
        {
          return transform_reduce(
            [](const BasicParticle* p) { return p->ip(); },
            [](float f1, float f2) { return (f2 < f1 || f1 < 0) ? f2 : f1; },
            -1.f);
        }

        __host__ __device__ float minp() const
        {
          return transform_reduce(
            [](const BasicParticle* p) { return p->state().p(); },
            [](float f1, float f2) { return (f2 < f1 || f1 < 0) ? f2 : f1; },
            -1.f);
        }

        __host__ __device__ float minpt() const
        {
          return transform_reduce(
            [](const BasicParticle* p) { return p->state().pt(); },
            [](float f1, float f2) { return (f2 < f1 || f1 < 0) ? f2 : f1; },
            -1.f);
        }

        __host__ __device__ float maxp() const
        {
          return transform_reduce(
            [](const BasicParticle* p) { return p->state().p(); },
            [](float f1, float f2) { return f2 > f1 ? f2 : f1; },
            -1.f);
        }

        __host__ __device__ float maxpt() const
        {
          return transform_reduce(
            [](const BasicParticle* p) { return p->state().pt(); },
            [](float f1, float f2) { return f2 > f1 ? f2 : f1; },
            -1.f);
        }

        __host__ __device__ float dira() const
        {
          if (!has_pv()) return 0.f;
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
          auto get_state = [](auto particle) -> MiniState {
            auto basicp = dyn_cast<const BasicParticle*>(particle);
            if (basicp) {
              const auto s = basicp->state();
              return {s.x(), s.y(), s.z(), s.tx(), s.ty()};
            }
            else {
              auto compp = static_cast<const CompositeParticle*>(particle);
              const auto s = compp->vertex();
              return {s.x(), s.y(), s.z(), s.px() / s.pz(), s.py() / s.pz()};
            }
          };

          const auto sA = get_state(child(index1));
          const auto sB = get_state(child(index2));

          return state_doca(sA, sB);
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
          if (!has_pv()) return -1.f;
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
          return is_di([](const BasicParticle* a) { return a->is_muon(); });
        }

        __host__ __device__ bool is_dielectron() const
        {
          return is_di([](const BasicParticle* a) { return a->is_electron(); });
        }

        __host__ __device__ bool is_dilepton() const
        {
          return is_di([](const BasicParticle* a) { return a->is_lepton(); });
        }

        __host__ __device__ bool is_dicluster() const
        {
          const auto a = dyn_cast<const NeutralBasicParticle*>(child(0));
          const auto b = dyn_cast<const NeutralBasicParticle*>(child(1));
          if (!a || !b) return false;
          return true;
        }

        __host__ __device__ inline float3 cluster_momentum(const unsigned index) const
        {
          const auto particle = dyn_cast<const NeutralBasicParticle*>(child(index));
          if (!particle) return float3 {0.f, 0.f, 0.f};
          const auto cluster = particle->cluster();
          const float z = Calo::Constants::z;
          const float r2 = cluster.x * cluster.x + cluster.y * cluster.y;
          const float sin_theta = sqrtf(r2 / (r2 + z * z));
          const float cos_phi = cluster.x / sqrtf(r2);
          const float sin_phi = cluster.y / sqrtf(r2);
          const float ex = cluster.e * sin_theta * cos_phi;
          const float ey = cluster.e * sin_theta * sin_phi;
          const float ez = cluster.e * z / sqrtf(r2 + z * z);
          return float3 {ex, ey, ez};
        }

        __host__ __device__ float diphoton_mass() const
        {
          if (!is_dicluster()) return -1.f;
          const auto a = static_cast<const NeutralBasicParticle*>(child(0));
          const auto b = static_cast<const NeutralBasicParticle*>(child(1));
          const auto ca = a->cluster();
          const auto cb = b->cluster();

          // Cluster A.
          const auto ea = cluster_momentum(0);

          // Cluster B.
          const auto eb = cluster_momentum(1);

          const float p2 =
            (ea.x + eb.x) * (ea.x + eb.x) + (ea.y + eb.y) * (ea.y + eb.y) + (ea.z + eb.z) * (ea.z + eb.z);
          const float e2 = (ca.e + cb.e) * (ca.e + cb.e);
          return sqrtf(e2 - p2);
        }

        __host__ __device__ float diphoton_pt() const
        {
          if (!is_dicluster()) return -1.f;

          // Cluster A.
          const auto ea = cluster_momentum(0);

          // Cluster B.
          const auto eb = cluster_momentum(1);

          const float pt2 = (ea.x + eb.x) * (ea.x + eb.x) + (ea.y + eb.y) * (ea.y + eb.y);
          return sqrtf(pt2);
        }

        __host__ __device__ float diphoton_eta() const
        {
          if (!is_dicluster()) return -1.f;

          // Cluster A.
          const auto ea = cluster_momentum(0);

          // Cluster B.
          const auto eb = cluster_momentum(1);

          const float p2 =
            (ea.x + eb.x) * (ea.x + eb.x) + (ea.y + eb.y) * (ea.y + eb.y) + (ea.z + eb.z) * (ea.z + eb.z);
          return atanhf((ea.z + eb.z) / sqrtf(p2));
        }

        __host__ __device__ float diphoton_distance() const
        {
          if (!is_dicluster()) return -1.f;
          const auto a = static_cast<const NeutralBasicParticle*>(child(0));
          const auto b = static_cast<const NeutralBasicParticle*>(child(1));
          const auto ca = a->cluster();
          const auto cb = b->cluster();
          return sqrtf((ca.x - cb.x) * (ca.x - cb.x) + (ca.y - cb.y) * (ca.y - cb.y));
        }

        __host__ __device__ float clone_sin2() const
        {
          const auto state1 = static_cast<const BasicParticle*>(child(0))->state();
          const auto state2 = static_cast<const BasicParticle*>(child(1))->state();
          const float txA = state1.tx();
          const float tyA = state1.ty();
          const float txB = state2.tx();
          const float tyB = state2.ty();
          const float vx = tyA - tyB;
          const float vy = -txA + txB;
          const float vz = txA * tyB - txB * tyA;
          return (vx * vx + vy * vy + vz * vz) / ((txA * txA + tyA * tyA + 1.f) * (txB * txB + tyB * tyB + 1.f));
        }

        __host__ __device__ MiniState get_state() const
        {
          const auto v = vertex();
          return MiniState(v.x(), v.y(), v.z(), v.px() / v.pz(), v.py() / v.pz());
        }
      };

      struct CompositeParticles : IParticleContainer<CompositeParticles> {
        friend IParticleContainer<CompositeParticles>;
        static constexpr auto TypeID = Allen::TypeIDs::CompositeParticles;

      private:
        const CompositeParticle* m_particle;
        unsigned m_size = 0;
        unsigned m_offset = 0;

        __host__ __device__ unsigned size_impl() const { return m_size; }

        __host__ __device__ const CompositeParticle& particle_impl(const unsigned i)
        {
          assert(i < m_size);
          return m_particle[i];
        }

      public:
        CompositeParticles() = default;

        __host__ __device__
        CompositeParticles(const CompositeParticle* composite, const unsigned* offsets, unsigned event_number) :
          m_particle(composite + offsets[event_number]),
          m_size(offsets[event_number + 1] - offsets[event_number]), m_offset(offsets[event_number])
        {}

        __host__ __device__ const CompositeParticle& particle(unsigned particle_index) const
        {
          return m_particle[particle_index];
        }

        __host__ __device__ const CompositeParticle* particle_pointer(const unsigned particle_index) const
        {
          return static_cast<const CompositeParticle*>(m_particle) + particle_index;
        }

        __host__ __device__ unsigned offset() const { return m_offset; }
      };

      using MultiEventBasicParticles = Allen::MultiEventContainer<BasicParticles>;
      using MultiEventNeutralBasicParticles = Allen::MultiEventContainer<NeutralBasicParticles>;
      using MultiEventCompositeParticles = Allen::MultiEventContainer<CompositeParticles>;
    } // namespace Physics
  }   // namespace Views
} // namespace Allen

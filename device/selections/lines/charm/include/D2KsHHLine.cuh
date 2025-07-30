/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"
#include "VertexDefinitions.cuh"
#include "ROOTService.h"
#include "MassDefinitions.h"
#include "ParticleTypes.cuh"

#include "AllenMonitoring.h"

namespace d2kshh_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;

    // Line-specific inputs
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    // Monitoring
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
    DEVICE_OUTPUT(sv_masses_t, float) sv_masses;       // the mass of the combination
    DEVICE_OUTPUT(p_t, float) p;                       // the momentum of the combination
    DEVICE_OUTPUT(pt_t, float) pt;                     // the transverse momentum of the combination
    DEVICE_OUTPUT(doca_t, float) doca;                 // the DOCA of the combination
    DEVICE_OUTPUT(ctau_t, float) ctau;                 // the proper time of the combination
    DEVICE_OUTPUT(v1_m_t, float) v1_m;                 // the invariant mass of the V1 (KS)
    DEVICE_OUTPUT(v2_m_t, float) v2_m;                 // the invariant mass of the V2 (hh)
    DEVICE_OUTPUT(v1_minipchi2_t, float) v1_minipchi2; // the minimum ipchi2 of the V1 (KS)
    DEVICE_OUTPUT(v2_minipchi2_t, float) v2_minipchi2; // the minimum ipchi2 of the V2 (hh)
    DEVICE_OUTPUT(v1_minip_t, float) v1_minip;         // the minimum ip of the V1 (KS)
    DEVICE_OUTPUT(v2_minip_t, float) v2_minip;         // the minimum ip of the V2 (hh)
    DEVICE_OUTPUT(msqp_t, float) msqp;                 // the squared invariant mass of the KSpip
    DEVICE_OUTPUT(msqm_t, float) msqm;                 // the squared invariant mass of the KSpim
  };

  // Monitoring Histograms
  struct d2kshh_line_t : public SelectionAlgorithm, Parameters, CompositeParticleLine<d2kshh_line_t, Parameters> {
    struct DeviceProperties {
      float maxVertexChi2;
      float maxDOCA;
      float minTrackPt_Ks;
      float minTrackP_Ks;
      float minTrackIP_Ks;
      float minComboPt_Ks;
      float minEta_Ks;
      float maxEta_Ks;
      float minM_Ks;
      float maxM_Ks;
      float maxDOCA_hh;
      float minEta_hh;
      float maxEta_hh;
      float minTrackPt_hh;
      float minTrackP_hh;
      float minTrackIP_hh;
      float minComboPt_D0;
      float minCTau_D0;
      float massWindow;
      Allen::Monitoring::Histogram<>::DeviceType histogram_d02kshh_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_d02kshh_pt;
      Allen::Monitoring::Histogram<>::DeviceType histogram_d02kshh_ctau;
      Allen::Monitoring::Histogram<>::DeviceType histogram_d02kshh_mKS;
      Allen::Monitoring::Histogram<>::DeviceType histogram_d02kshh_mhh;
      DeviceProperties(const d2kshh_line_t& algo, const Allen::Context& ctx) :
        maxVertexChi2(algo.m_maxVertexChi2), maxDOCA(algo.m_maxDOCA), minTrackPt_Ks(algo.m_minTrackPt_piKs),
        minTrackP_Ks(algo.m_minTrackP_piKs), minTrackIP_Ks(algo.m_minTrackIP_Ks), minComboPt_Ks(algo.m_minComboPt_Ks),
        minEta_Ks(algo.m_minEta_Ks), maxEta_Ks(algo.m_maxEta_Ks), minM_Ks(algo.m_minM_Ks), maxM_Ks(algo.m_maxM_Ks),
        maxDOCA_hh(algo.m_maxDOCA_hh), minEta_hh(algo.m_minEta_hh), maxEta_hh(algo.m_maxEta_hh),
        minTrackPt_hh(algo.m_minTrackPt_hh), minTrackP_hh(algo.m_minTrackP_hh), minTrackIP_hh(algo.m_minTrackIP_hh),
        minComboPt_D0(algo.m_minComboPt_D0), minCTau_D0(algo.m_minCTau_D0), massWindow(algo.m_massWindow),
        histogram_d02kshh_mass(algo.m_histogram_d02kshh_mass.data(ctx)),
        histogram_d02kshh_pt(algo.m_histogram_d02kshh_pt.data(ctx)),
        histogram_d02kshh_ctau(algo.m_histogram_d02kshh_ctau.data(ctx)),
        histogram_d02kshh_mKS(algo.m_histogram_d02kshh_mKS.data(ctx)),
        histogram_d02kshh_mhh(algo.m_histogram_d02kshh_mhh.data(ctx))
      {}
    };

    // Get the invariant mass of a pair of vertices
    __device__ static float m(
      const Allen::Views::Physics::CompositeParticle* vertex1,
      const Allen::Views::Physics::CompositeParticle* vertex2,
      const float m1,
      const float m2);

    // Get the absolute momentum of a pair of vertices
    __device__ static float p(
      const Allen::Views::Physics::CompositeParticle* vertex1,
      const Allen::Views::Physics::CompositeParticle* vertex2);

    // Get the pt of a pair of vertices
    __device__ static float pt(
      const Allen::Views::Physics::CompositeParticle* vertex1,
      const Allen::Views::Physics::CompositeParticle* vertex2);

    // Get the proper time of a pair of vertices
    __device__ static float ctau(
      const Allen::Views::Physics::CompositeParticle* vertex1,
      const Allen::Views::Physics::CompositeParticle* vertex2);

    // Invariant mass of a vertex candidate and a basic particle
    __device__ static float mSq(
      const Allen::Views::Physics::CompositeParticle* vertex,
      const Allen::Views::Physics::BasicParticle* particle,
      const float m1,
      const float m2);

    // Selection function
    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    // // Monitoring functions
    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle>,
      unsigned,
      bool);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle>,
      unsigned,
      bool);

    using monitoring_types = std::tuple<
      sv_masses_t,
      p_t,
      pt_t,
      doca_t,
      ctau_t,
      v1_m_t,
      v2_m_t,
      v1_minipchi2_t,
      v2_minipchi2_t,
      v1_minip_t,
      v2_minip_t,
      msqp_t,
      msqm_t,
      evtNo_t,
      runNo_t>;

  private:
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 20.f, "max VertexChi2 of the two vertices"};
    Allen::Property<float> m_maxDOCA {this, "maxDOCA", 0.5f * Allen::Units::mm, "max DOCA of the two vertices"};
    Allen::Property<float> m_minTrackPt_piKs {this,
                                              "minTrackPt_Ks",
                                              200.f * Allen::Units::MeV,
                                              "min Pt of KS vertex tracks"};
    Allen::Property<float> m_minTrackP_piKs {this,
                                             "minTrackP_Ks",
                                             1500.f * Allen::Units::MeV,
                                             "min P of KS vertex tracks"};
    Allen::Property<float> m_minTrackIP_Ks {this,
                                            "minTrackIP_Ks",
                                            0.2f * Allen::Units::mm,
                                            "min IP of KS vertex tracks"};
    Allen::Property<float> m_minComboPt_Ks {this, "minComboPt_Ks", 200.f * Allen::Units::MeV, "min Pt of Ks candidate"};
    Allen::Property<float> m_minEta_Ks {this, "minEta_Ks", 2.0f, "min Pseudorapidity of KS candidate"};
    Allen::Property<float> m_maxEta_Ks {this, "maxEta_Ks", 5.0f, "max Pseudorapidity of KS candidate"};
    Allen::Property<float> m_minM_Ks {this, "minM_Ks", 455.0f * Allen::Units::MeV, "min mass of KS candidate"};
    Allen::Property<float> m_maxM_Ks {this, "maxM_Ks", 545.0f * Allen::Units::MeV, "max mass of KS candidate"};
    Allen::Property<float> m_maxDOCA_hh {this, "maxDOCA_hh", 0.05f, "max DOCA of hh tracks"};
    Allen::Property<float> m_minEta_hh {this, "minEta_hh", 2.0f, "min Pseudorapidity of hh candidate"};
    Allen::Property<float> m_maxEta_hh {this, "maxEta_hh", 5.0f, "max Pseudorapidity of hh candidate"};
    Allen::Property<float> m_minTrackPt_hh {this,
                                            "minTrackPt_hh",
                                            250.f * Allen::Units::MeV,
                                            "min Pt of D0 candidate tracks"};
    Allen::Property<float> m_minTrackP_hh {this,
                                           "minTrackP_hh",
                                           1500.f * Allen::Units::MeV,
                                           "min P of hh candidate tracks"};
    Allen::Property<float> m_minTrackIP_hh {this,
                                            "minTrackIP_hh",
                                            0.06f * Allen::Units::mm,
                                            "min IP of D0 candidate tracks"};
    Allen::Property<float> m_minComboPt_D0 {this,
                                            "minComboPt_D0",
                                            1500.0f * Allen::Units::MeV,
                                            "min Pt of D0 candidate"};
    Allen::Property<float> m_minCTau_D0 {this, "minCTau_D0", 0.5f * 0.1229f, "minimum D0 proper time"}; // 0.5 * D0 ctau
    Allen::Property<float> m_massWindow {this, "massWindow", 100.f * Allen::Units::MeV, "D0 massWindow"};

    Allen::Monitoring::Histogram<> m_histogram_d02kshh_mass {this, "d02kshh_mass", "m(D0)", {100u, 1765.f, 1965.f}};
    Allen::Monitoring::Histogram<> m_histogram_d02kshh_pt {this, "d02kshh_pt", "pT(D0)", {100u, 0.f, 1e4f}};
    Allen::Monitoring::Histogram<> m_histogram_d02kshh_ctau {this,
                                                             "d02kshh_ctau",
                                                             "ctau(D0)",
                                                             {100u, 0.f, 10.f * 0.1229f}};
    Allen::Monitoring::Histogram<> m_histogram_d02kshh_mKS {this, "d02kshh_mKS", "m(KS)", {100u, 455.f, 545.f}};
    Allen::Monitoring::Histogram<> m_histogram_d02kshh_mhh {this, "d02kshh_mhh", "m(hh)", {100u, 275.f, 1555.f}};
  };
} // namespace d2kshh_line

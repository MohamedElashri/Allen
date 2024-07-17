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

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string)
    pre_scaler_hash_string;
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string)
    post_scaler_hash_string;
    // Line-specific inputs and properties
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
    // Combination properties
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "max VertexChi2 of the two vertices", float) maxVertexChi2;
    PROPERTY(maxDOCA_t, "maxDOCA", "max DOCA of the two vertices", float) maxDOCA;
    // KS0 properties
    PROPERTY(minTrackPt_Ks_t, "minTrackPt_Ks", "min Pt of KS vertex tracks", float) minTrackPt_Ks;
    PROPERTY(minTrackP_Ks_t, "minTrackP_Ks", "min P of KS vertex tracks", float) minTrackP_Ks;
    PROPERTY(minTrackIP_Ks_t, "minTrackIP_Ks", "min IP of KS vertex tracks", float) minTrackIP_Ks;
    PROPERTY(minComboPt_Ks_t, "minComboPt_Ks", "min Pt of Ks candidate", float) minComboPt_Ks;
    PROPERTY(minEta_Ks_t, "minEta_Ks", "min Pseudorapidity of KS candidate", float) minEta_Ks;
    PROPERTY(maxEta_Ks_t, "maxEta_Ks", "max Pseudorapidity of KS candidate", float) maxEta_Ks;
    PROPERTY(minM_Ks_t, "minM_Ks", "min mass of KS candidate", float) minM_Ks;
    PROPERTY(maxM_Ks_t, "maxM_Ks", "max mass of KS candidate", float) maxM_Ks;
    // hh properties
    PROPERTY(maxDOCA_hh_t, "maxDOCA_hh", "max DOCA of hh tracks", float) maxDOCA_hh;
    PROPERTY(minEta_hh_t, "minEta_hh", "min Pseudorapidity of hh candidate", float) minEta_hh;
    PROPERTY(maxEta_hh_t, "maxEta_hh", "max Pseudorapidity of hh candidate", float) maxEta_hh;
    PROPERTY(minTrackP_hh_t, "minTrackP_hh", "min P of hh candidate tracks", float) minTrackP_hh;
    PROPERTY(minTrackPt_hh_t, "minTrackPt_hh", "min Pt of D0 candidate tracks", float) minTrackPt_hh;
    PROPERTY(minTrackIP_hh_t, "minTrackIP_hh", "min IP of D0 candidate tracks", float) minTrackIP_hh;
    // D0 properties
    PROPERTY(minComboPt_D0_t, "minComboPt_D0", "min Pt of D0 candidate", float) minComboPt_D0;
    PROPERTY(minCTau_D0_t, "minCTau_D0", "minimum D0 proper time", float) minCTau_D0;
    PROPERTY(massWindow_t, "massWindow", "D0 massWindow", float) massWindow;
    // Monitoring
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line tupling", bool) enable_tupling;
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
    struct DeviceAccumulators {
      Allen::Monitoring::Histogram<>::DeviceType histogram_d02kshh_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_d02kshh_pt;
      Allen::Monitoring::Histogram<>::DeviceType histogram_d02kshh_ctau;
      Allen::Monitoring::Histogram<>::DeviceType histogram_d02kshh_mKS;
      Allen::Monitoring::Histogram<>::DeviceType histogram_d02kshh_mhh;
      DeviceAccumulators(const d2kshh_line_t& algo, const Allen::Context& ctx) :
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
    select(const Parameters&, const DeviceAccumulators&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    // // Monitoring functions
    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceAccumulators& accumulators,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<
      evtNo_t,
      runNo_t,
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
      msqm_t>;

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 20.f};
    Property<maxDOCA_t> m_maxDOCA {this, 0.5f * Gaudi::Units::mm};
    Property<minTrackPt_Ks_t> m_minTrackPt_piKs {this, 200.f * Gaudi::Units::MeV};
    Property<minTrackP_Ks_t> m_minTrackP_piKs {this, 1500.f * Gaudi::Units::MeV};
    Property<minTrackIP_Ks_t> m_minTrackIP_Ks {this, 0.2f * Gaudi::Units::mm};
    Property<minComboPt_Ks_t> m_minComboPt_Ks {this, 200.f * Gaudi::Units::MeV};
    Property<minEta_Ks_t> m_minEta_Ks {this, 2.0f};
    Property<maxEta_Ks_t> m_maxEta_Ks {this, 5.0f};
    Property<minM_Ks_t> m_minM_Ks {this, 455.0f * Gaudi::Units::MeV};
    Property<maxM_Ks_t> m_maxM_Ks {this, 545.0f * Gaudi::Units::MeV};
    Property<maxDOCA_hh_t> m_maxDOCA_hh {this, 0.05f};
    Property<minEta_hh_t> m_minEta_hh {this, 2.0f};
    Property<maxEta_hh_t> m_maxEta_hh {this, 5.0f};
    Property<minTrackPt_hh_t> m_minTrackPt_hh {this, 250.f * Gaudi::Units::MeV};
    Property<minTrackP_hh_t> m_minTrackP_hh {this, 1500.f * Gaudi::Units::MeV};
    Property<minTrackIP_hh_t> m_minTrackIP_hh {this, 0.06f * Gaudi::Units::mm};
    Property<minComboPt_D0_t> m_minComboPt_D0 {this, 1500.0f * Gaudi::Units::MeV};
    Property<minCTau_D0_t> m_minCTau_D0 {this, 0.5f * 0.1229f}; // 0.5 * D0 ctau
    Property<massWindow_t> m_massWindow {this, 100.f * Gaudi::Units::MeV};
    Property<enable_monitoring_t> m_enable_monitoring {this, false};
    Property<enable_tupling_t> m_enable_tupling {this, false};

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
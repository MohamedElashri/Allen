/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"
#include "ParticleTypes.cuh"
#include "MassDefinitions.h"

#include "AllenMonitoring.h"
#include "ROOTService.h"

namespace tautophimu_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;

    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    // Monitoring
    DEVICE_OUTPUT(min_p_t, float) min_p;
    DEVICE_OUTPUT(min_pt_t, float) min_pt;
    DEVICE_OUTPUT(min_ip_t, float) min_ip;
    DEVICE_OUTPUT(min_ipchi2_t, float) min_ipchi2;
    DEVICE_OUTPUT(doca_phi_track_t, float) doca_phi_track;
    DEVICE_OUTPUT(phi_chi2_t, float) phi_chi2;
    DEVICE_OUTPUT(phi_doca_t, float) phi_doca;
    DEVICE_OUTPUT(phi_mass_t, float) phi_mass;
    DEVICE_OUTPUT(phi_fdchi2_t, float) phi_fdchi2;
    DEVICE_OUTPUT(phi_fd_t, float) phi_fd;
    DEVICE_OUTPUT(tau_mass_t, float) tau_mass;
    DEVICE_OUTPUT(ctau_t, float) ctau;
    DEVICE_OUTPUT(phi_pt_t, float) phi_pt;
    DEVICE_OUTPUT(tau_pt_t, float) tau_pt;
    DEVICE_OUTPUT(phi_dz_t, float) phi_dz;
    DEVICE_OUTPUT(phi_eta_t, float) phi_eta;
    DEVICE_OUTPUT(mu_p_t, float) mu_p;
    DEVICE_OUTPUT(mu_pt_t, float) mu_pt;
    DEVICE_OUTPUT(mu_ismuon_t, float) mu_ismuon;
    DEVICE_OUTPUT(mu_ip_chi2_t, float) mu_ip_chi2;
    DEVICE_OUTPUT(mu_eta_t, float) mu_eta;
    DEVICE_OUTPUT(phi_drho_t, float) phi_drho;
    DEVICE_OUTPUT(phi_dira_t, float) phi_dira;
    DEVICE_OUTPUT(phi_vertex_z_t, float) phi_vertex_z;
    DEVICE_OUTPUT(pv_z_t, float) pv_z;
    DEVICE_OUTPUT(K1_ismuon_t, float) K1_ismuon;
    DEVICE_OUTPUT(K2_ismuon_t, float) K2_ismuon;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;

    DEVICE_OUTPUT(histogram_phi_m_t, unsigned) histogram_phi_m;
    DEVICE_OUTPUT(histogram_phi_pt_t, unsigned) histogram_phi_pt;
  };

  struct tautophimu_line_t : public SelectionAlgorithm,
                             Parameters,
                             CompositeParticleLine<tautophimu_line_t, Parameters> {
    struct DeviceProperties {
      float minTrackP;
      float minTrackPt;
      float minTrackIPChi2;
      float minTrackIP;
      float minTrackEta;
      float maxTrackEta;
      float minPhiPt;
      float maxPhiVertexChi2;
      float maxPhiDOCA;
      float maxDOCA;
      float minPhiFDChi2;
      float PhiMassWindow;
      float minSVpt;
      float minctau;
      float maxctau;
      float minZ;
      float minInvMass;
      float maxInvMass;
      float minThirdTrackP;
      float minThirdTrackPt;
      float minThirdTrackIPChi2;
      float minThirdTrackEta;
      float maxThirdTrackEta;
      Allen::Monitoring::Histogram<>::DeviceType histogram_phi_pt;
      Allen::Monitoring::Histogram<>::DeviceType histogram_phi_m;

      DeviceProperties(const tautophimu_line_t& algo, const Allen::Context& ctx) :
        minTrackP(algo.m_minTrackP), minTrackPt(algo.m_minTrackPt), minTrackIPChi2(algo.m_minTrackIPChi2),
        minTrackIP(algo.m_minTrackIP), minTrackEta(algo.m_minTrackEta), maxTrackEta(algo.m_maxTrackEta),
        minPhiPt(algo.m_minPhiPt), maxPhiVertexChi2(algo.m_maxPhiVertexChi2), maxPhiDOCA(algo.m_maxPhiDOCA),
        maxDOCA(algo.m_maxDOCA), minPhiFDChi2(algo.m_minPhiFDChi2), PhiMassWindow(algo.m_PhiMassWindow),
        minSVpt(algo.m_minSVpt), minctau(algo.m_minctau), maxctau(algo.m_maxctau), minZ(algo.m_minZ),
        minInvMass(algo.m_minInvMass), maxInvMass(algo.m_maxInvMass), minThirdTrackP(algo.m_minThirdTrackP),
        minThirdTrackPt(algo.m_minThirdTrackPt), minThirdTrackIPChi2(algo.m_minThirdTrackIPChi2),
        minThirdTrackEta(algo.m_minThirdTrackEta), maxThirdTrackEta(algo.m_maxThirdTrackEta),
        histogram_phi_pt(algo.m_histogram_phi_pt.data(ctx)), histogram_phi_m(algo.m_histogram_phi_m.data(ctx))
      {}
    };

    // Get the invariant mass of the phi and an additional third track
    __device__ static float m(
      const Allen::Views::Physics::CompositeParticle* phi,
      const Allen::Views::Physics::BasicParticle* track,
      const float m1,
      const float m2);

    // Get the absolute momentum of the phi and an additional third track
    __device__ static float p(
      const Allen::Views::Physics::CompositeParticle* phi,
      const Allen::Views::Physics::BasicParticle* track);

    // Get the pt of the phi and an additional third track
    __device__ static float pt(
      const Allen::Views::Physics::CompositeParticle* phi,
      const Allen::Views::Physics::BasicParticle* track);

    // Get the proper time of the phi and an additional third track
    __device__ static float ctau(
      const Allen::Views::Physics::CompositeParticle* phi,
      const Allen::Views::Physics::BasicParticle* track);

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<
      K1_ismuon_t,
      K2_ismuon_t,
      pv_z_t,
      phi_vertex_z_t,
      mu_ismuon_t,
      mu_p_t,
      mu_pt_t,
      mu_ip_chi2_t,
      mu_eta_t,
      doca_phi_track_t,
      min_p_t,
      phi_eta_t,
      phi_chi2_t,
      phi_doca_t,
      phi_fd_t,
      min_pt_t,
      phi_dira_t,
      min_ip_t,
      min_ipchi2_t,
      phi_mass_t,
      phi_fdchi2_t,
      phi_pt_t,
      mu_pt_t,
      tau_pt_t,
      ctau_t,
      tau_mass_t,
      phi_dz_t,
      phi_drho_t,
      evtNo_t,
      runNo_t>;

  private:
    Allen::Property<float> m_minTrackP {this, "minTrackP", 3.0f * Allen::Units::GeV, "Minimum track momentum"};
    Allen::Property<float> m_minTrackPt {this, "minTrackPt", 450.0f * Allen::Units::MeV, "Minimum track pT"};
    Allen::Property<float> m_minTrackIPChi2 {this, "minTrackIPChi2", 4.0f, "Minimum track IP chi2"};
    Allen::Property<float> m_minTrackIP {this, "minTrackIP", 0.0f * Allen::Units::mm, "Minimum track IP"};
    Allen::Property<float> m_minTrackEta {this, "minTrackEta", 2.0f, "Minimum track eta"};
    Allen::Property<float> m_maxTrackEta {this, "maxTrackEta", 5.0f, "Maximum track eta"};
    Allen::Property<float> m_minPhiPt {this, "minPhiPt", 900.0f * Allen::Units::MeV, "Minimum phi pT"};
    Allen::Property<float> m_maxPhiVertexChi2 {this, "maxPhiVertexChi2", 10.0f, "Maximum phi vertex chi2"};
    Allen::Property<float> m_maxPhiDOCA {this, "maxPhiDOCA", 0.2f * Allen::Units::mm, "Maximum phi DOCA"};
    Allen::Property<float> m_maxDOCA {this, "maxDOCA", 0.2f * Allen::Units::mm, "Maximum DOCA btw phi and muon"};
    Allen::Property<float> m_minPhiFDChi2 {this, "minPhiFDChi2", 10.0f, "Minimum phi FD chi2"};
    Allen::Property<float> m_PhiMassWindow {this, "PhiMassWindow", 30.0f * Allen::Units::MeV, "Phi mass window"};
    Allen::Property<float> m_minSVpt {this, "minSVpt", 2.5f * Allen::Units::GeV, "Minimum tau pT"};
    Allen::Property<float> m_minctau {this, "minctau", 0.07f * Allen::Units::mm, "Minimum tau ctau"};
    Allen::Property<float> m_maxctau {this, "maxctau", 1.0f * Allen::Units::mm, "Maximum tau ctau"};
    Allen::Property<float> m_minZ {this, "minZ", -200.f * Allen::Units::mm, "Minimum z"};
    Allen::Property<float> m_minInvMass {this, "minInvMass", 1620.0f * Allen::Units::MeV, "Minimum tau invariant mass"};
    Allen::Property<float> m_maxInvMass {this, "maxInvMass", 2050.0f * Allen::Units::MeV, "Maximum tau invariant mass"};
    Allen::Property<float> m_minThirdTrackP {this,
                                             "minThirdTrackP",
                                             3.0f * Allen::Units::GeV,
                                             "Minimum third track momentum"};
    Allen::Property<float> m_minThirdTrackPt {this,
                                              "minThirdTrackPt",
                                              350.0f * Allen::Units::MeV,
                                              "Minimum third track pT"};
    Allen::Property<float> m_minThirdTrackIPChi2 {this, "minThirdTrackIPChi2", 9.0f, "Minimum third track IP chi2"};
    Allen::Property<float> m_minThirdTrackEta {this, "minThirdTrackEta", 2.0f, "Minimum third track eta"};
    Allen::Property<float> m_maxThirdTrackEta {this, "maxThirdTrackEta", 5.0f, "Maximum third track eta"};

    Allen::Monitoring::Histogram<> m_histogram_phi_pt {this, "phi_pt", "pT(phi)", {100u, 0.f, 1e4f}};
    Allen::Monitoring::Histogram<> m_histogram_phi_m {this, "phi_m", "m(phi)", {84u, 980.f, 1060.f}};
  };
} // namespace tautophimu_line

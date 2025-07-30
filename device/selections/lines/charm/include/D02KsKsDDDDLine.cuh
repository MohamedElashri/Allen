/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"
#include "VertexDefinitions.cuh"
#include "MassDefinitions.h"
#include "ParticleTypes.cuh"

namespace d02ksks_DDDD_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;

    // Line-specific inputs and properties
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    // Monitoring
    DEVICE_OUTPUT(dev_decision_t, bool) dev_decision;
    DEVICE_OUTPUT(dev_pt_pi1_ks1_t, float) dev_pt_pi1_ks1;
    DEVICE_OUTPUT(dev_pt_pi2_ks1_t, float) dev_pt_pi2_ks1;
    DEVICE_OUTPUT(dev_p_pi1_ks1_t, float) dev_p_pi1_ks1;
    DEVICE_OUTPUT(dev_p_pi2_ks1_t, float) dev_p_pi2_ks1;
    DEVICE_OUTPUT(dev_ipchi2_pi1_ks1_t, float) dev_ipchi2_pi1_ks1;
    DEVICE_OUTPUT(dev_ipchi2_pi2_ks1_t, float) dev_ipchi2_pi2_ks1;
    DEVICE_OUTPUT(dev_ip_pi1_ks1_t, float) dev_ip_pi1_ks1;
    DEVICE_OUTPUT(dev_ip_pi2_ks1_t, float) dev_ip_pi2_ks1;
    DEVICE_OUTPUT(dev_pt_pi1_ks2_t, float) dev_pt_pi1_ks2;
    DEVICE_OUTPUT(dev_pt_pi2_ks2_t, float) dev_pt_pi2_ks2;
    DEVICE_OUTPUT(dev_p_pi1_ks2_t, float) dev_p_pi1_ks2;
    DEVICE_OUTPUT(dev_p_pi2_ks2_t, float) dev_p_pi2_ks2;
    DEVICE_OUTPUT(dev_ipchi2_pi1_ks2_t, float) dev_ipchi2_pi1_ks2;
    DEVICE_OUTPUT(dev_ipchi2_pi2_ks2_t, float) dev_ipchi2_pi2_ks2;
    DEVICE_OUTPUT(dev_ip_pi1_ks2_t, float) dev_ip_pi1_ks2;
    DEVICE_OUTPUT(dev_ip_pi2_ks2_t, float) dev_ip_pi2_ks2;
    DEVICE_OUTPUT(dev_cos_open_pi_ks1_t, float) dev_cos_open_pi_ks1;
    DEVICE_OUTPUT(dev_ip_ks1_t, float) dev_ip_ks1;
    DEVICE_OUTPUT(dev_ip_comb_ks1_t, float) dev_ip_comb_ks1;
    DEVICE_OUTPUT(dev_pt_ks1_t, float) dev_pt_ks1;
    DEVICE_OUTPUT(dev_chi2vtx_ks1_t, float) dev_chi2vtx_ks1;
    DEVICE_OUTPUT(dev_ipchi2_ks1_t, float) dev_ipchi2_ks1;
    DEVICE_OUTPUT(dev_dira_ks1_t, float) dev_dira_ks1;
    DEVICE_OUTPUT(dev_eta_ks1_t, float) dev_eta_ks1;
    DEVICE_OUTPUT(dev_mks1_t, float) dev_mks1;
    DEVICE_OUTPUT(dev_cos_open_pi_ks2_t, float) dev_cos_open_pi_ks2;
    DEVICE_OUTPUT(dev_ip_ks2_t, float) dev_ip_ks2;
    DEVICE_OUTPUT(dev_ip_comb_ks2_t, float) dev_ip_comb_ks2;
    DEVICE_OUTPUT(dev_pt_ks2_t, float) dev_pt_ks2;
    DEVICE_OUTPUT(dev_chi2vtx_ks2_t, float) dev_chi2vtx_ks2;
    DEVICE_OUTPUT(dev_ipchi2_ks2_t, float) dev_ipchi2_ks2;
    DEVICE_OUTPUT(dev_dira_ks2_t, float) dev_dira_ks2;
    DEVICE_OUTPUT(dev_eta_ks2_t, float) dev_eta_ks2;
    DEVICE_OUTPUT(dev_mks2_t, float) dev_mks2;
    DEVICE_OUTPUT(dev_mks_pair_t, float) dev_mks_pair;
    DEVICE_OUTPUT(dev_pv1x_t, float) dev_pv1x;
    DEVICE_OUTPUT(dev_pv1y_t, float) dev_pv1y;
    DEVICE_OUTPUT(dev_pv1z_t, float) dev_pv1z;
    DEVICE_OUTPUT(dev_pv2x_t, float) dev_pv2x;
    DEVICE_OUTPUT(dev_pv2y_t, float) dev_pv2y;
    DEVICE_OUTPUT(dev_pv2z_t, float) dev_pv2z;
    DEVICE_OUTPUT(dev_sv1x_t, float) dev_sv1x;
    DEVICE_OUTPUT(dev_sv1y_t, float) dev_sv1y;
    DEVICE_OUTPUT(dev_sv1z_t, float) dev_sv1z;
    DEVICE_OUTPUT(dev_sv2x_t, float) dev_sv2x;
    DEVICE_OUTPUT(dev_sv2y_t, float) dev_sv2y;
    DEVICE_OUTPUT(dev_sv2z_t, float) dev_sv2z;
    DEVICE_OUTPUT(dev_doca1_pi_t, float) dev_doca1_pi;
    DEVICE_OUTPUT(dev_doca2_pi_t, float) dev_doca2_pi;
    DEVICE_OUTPUT(dev_px_ks1_t, float) dev_px_ks1;
    DEVICE_OUTPUT(dev_py_ks1_t, float) dev_py_ks1;
    DEVICE_OUTPUT(dev_pz_ks1_t, float) dev_pz_ks1;
    DEVICE_OUTPUT(dev_px_ks2_t, float) dev_px_ks2;
    DEVICE_OUTPUT(dev_py_ks2_t, float) dev_py_ks2;
    DEVICE_OUTPUT(dev_pz_ks2_t, float) dev_pz_ks2;
    DEVICE_OUTPUT(dev_chi2trk_pi1_ks1_t, float) dev_chi2trk_pi1_ks1;
    DEVICE_OUTPUT(dev_chi2trk_pi2_ks1_t, float) dev_chi2trk_pi2_ks1;
    DEVICE_OUTPUT(dev_chi2trk_pi1_ks2_t, float) dev_chi2trk_pi1_ks2;
    DEVICE_OUTPUT(dev_chi2trk_pi2_ks2_t, float) dev_chi2trk_pi2_ks2;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct d02ksks_DDDD_line_t : public SelectionAlgorithm,
                               Parameters,
                               CompositeParticleLine<d02ksks_DDDD_line_t, Parameters> {

    struct DeviceProperties {
      float maxVertexChi2;
      float minComboPt_Ks;
      float minEta_Ks;
      float maxEta_Ks;
      float minTrackPt_piKs;
      float minTrackP_piKs;
      float minTrackIP_piKs;
      float minM_Ks;
      float maxM_Ks;
      float minM_D0;
      float maxM_D0;
      float minZ_sv;
      float minZ_pv;
      bool OppositeSign;
      DeviceProperties(const d02ksks_DDDD_line_t& algo, const Allen::Context&) :
        maxVertexChi2(algo.m_maxVertexChi2), minComboPt_Ks(algo.m_minComboPt_Ks), minEta_Ks(algo.m_minEta_Ks),
        maxEta_Ks(algo.m_maxEta_Ks), minTrackPt_piKs(algo.m_minTrackPt_piKs), minTrackP_piKs(algo.m_minTrackP_piKs),
        minTrackIP_piKs(algo.m_minTrackIP_piKs), minM_Ks(algo.m_minM_Ks), maxM_Ks(algo.m_maxM_Ks),
        minM_D0(algo.m_minM_D0), maxM_D0(algo.m_maxM_D0), minZ_sv(algo.m_minZ_sv), minZ_pv(algo.m_minZ_pv),
        OppositeSign(algo.m_opposite_sign.value())
      {}
    };

    using monitoring_types = std::tuple<
      dev_decision_t,
      dev_pt_pi1_ks1_t,
      dev_pt_pi2_ks1_t,
      dev_p_pi1_ks1_t,
      dev_p_pi2_ks1_t,
      dev_ipchi2_pi1_ks1_t,
      dev_ipchi2_pi2_ks1_t,
      dev_ip_pi1_ks1_t,
      dev_ip_pi2_ks1_t,
      dev_pt_pi1_ks2_t,
      dev_pt_pi2_ks2_t,
      dev_p_pi1_ks2_t,
      dev_p_pi2_ks2_t,
      dev_ipchi2_pi1_ks2_t,
      dev_ipchi2_pi2_ks2_t,
      dev_ip_pi1_ks2_t,
      dev_ip_pi2_ks2_t,
      dev_cos_open_pi_ks1_t,
      dev_ip_ks1_t,
      dev_ip_comb_ks1_t,
      dev_pt_ks1_t,
      dev_chi2vtx_ks1_t,
      dev_ipchi2_ks1_t,
      dev_dira_ks1_t,
      dev_eta_ks1_t,
      dev_mks1_t,
      dev_cos_open_pi_ks2_t,
      dev_ip_ks2_t,
      dev_ip_comb_ks2_t,
      dev_pt_ks2_t,
      dev_chi2vtx_ks2_t,
      dev_ipchi2_ks2_t,
      dev_dira_ks2_t,
      dev_eta_ks2_t,
      dev_mks2_t,
      dev_mks_pair_t,
      dev_pv1x_t,
      dev_pv1y_t,
      dev_pv1z_t,
      dev_pv2x_t,
      dev_pv2y_t,
      dev_pv2z_t,
      dev_sv1x_t,
      dev_sv1y_t,
      dev_sv1z_t,
      dev_sv2x_t,
      dev_sv2y_t,
      dev_sv2z_t,
      dev_doca1_pi_t,
      dev_doca2_pi_t,
      dev_px_ks1_t,
      dev_py_ks1_t,
      dev_pz_ks1_t,
      dev_px_ks2_t,
      dev_py_ks2_t,
      dev_pz_ks2_t,
      dev_chi2trk_pi1_ks1_t,
      dev_chi2trk_pi2_ks1_t,
      dev_chi2trk_pi1_ks2_t,
      dev_chi2trk_pi2_ks2_t,
      evtNo_t,
      runNo_t>;

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    // Get the invariant mass of a pair of vertices
    __device__ static float m(
      const Allen::Views::Physics::CompositeParticle& vertex1,
      const Allen::Views::Physics::CompositeParticle& vertex2);

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input);

  private:
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 20.f, "maxVertexChi2 description"};
    Allen::Property<float> m_minComboPt_Ks {this,
                                            "minComboPt_Ks",
                                            1200.f * Allen::Units::MeV,
                                            "minComboPt_Ks description"};
    Allen::Property<float> m_minEta_Ks {this, "minEta_Ks", 2.f, "minEta_Ks description"};
    Allen::Property<float> m_maxEta_Ks {this, "maxEta_Ks", 4.2f, "maxEta_Ks description"};
    Allen::Property<float> m_minTrackPt_piKs {this,
                                              "minTrackPt_piKs",
                                              450.f * Allen::Units::MeV,
                                              "minTrackPt_piKs description"};
    Allen::Property<float> m_minTrackP_piKs {this,
                                             "minTrackP_piKs",
                                             3000.f * Allen::Units::MeV,
                                             "minTrackP_piKs description"};
    Allen::Property<float> m_minTrackIP_piKs {this, "minTrackIP_piKs", 1.f, "minTrackIP_piKs description"};
    Allen::Property<float> m_minM_Ks {this, "minM_Ks", 400.0f * Allen::Units::MeV, "minM_Ks description"};
    Allen::Property<float> m_maxM_Ks {this, "maxM_Ks", 600.0f * Allen::Units::MeV, "maxM_Ks description"};
    Allen::Property<float> m_minM_D0 {this, "minM_D0", 1650.0f * Allen::Units::MeV, "minM_D0 description"};
    Allen::Property<float> m_maxM_D0 {this, "maxM_D0", 2100.0f * Allen::Units::MeV, "maxM_D0 description"};
    Allen::Property<float> m_minZ_sv {this, "minZ_sv", 400.f * Allen::Units::mm, "minZ_sv description"};
    Allen::Property<float> m_minZ_pv {this, "minZ_pv", -330.f * Allen::Units::mm, "minZ_pv description"};
    Allen::Property<bool> m_opposite_sign {this, "OppositeSign", true, "Selects opposite sign dibody combinations"};
  };
} // namespace d02ksks_DDDD_line

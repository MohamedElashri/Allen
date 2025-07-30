/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
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
#include "MassDefinitions.h"

#include "AllenMonitoring.h"

namespace downstream_two_track_ks_line {
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
    DEVICE_OUTPUT(decision_t, bool) dev_decision;
    DEVICE_OUTPUT(pt_pi1_ks_t, float) dev_pt_pi1_ks;
    DEVICE_OUTPUT(pt_pi2_ks_t, float) dev_pt_pi2_ks;
    DEVICE_OUTPUT(p_pi1_ks_t, float) dev_p_pi1_ks;
    DEVICE_OUTPUT(p_pi2_ks_t, float) dev_p_pi2_ks;
    DEVICE_OUTPUT(ipchi2_pi1_ks_t, float) dev_ipchi2_pi1_ks;
    DEVICE_OUTPUT(ipchi2_pi2_ks_t, float) dev_ipchi2_pi2_ks;
    DEVICE_OUTPUT(ip_pi1_ks_t, float) dev_ip_pi1_ks;
    DEVICE_OUTPUT(ip_pi2_ks_t, float) dev_ip_pi2_ks;
    DEVICE_OUTPUT(ip_ks_t, float) dev_ip_ks;
    DEVICE_OUTPUT(pt_ks_t, float) dev_pt_ks;
    DEVICE_OUTPUT(chi2vtx_ks_t, float) dev_chi2vtx_ks;
    DEVICE_OUTPUT(dira_ks_t, float) dev_dira_ks;
    DEVICE_OUTPUT(eta_ks_t, float) dev_eta_ks;
    DEVICE_OUTPUT(mks_t, float) dev_mks;
    DEVICE_OUTPUT(pvx_t, float) dev_pvx;
    DEVICE_OUTPUT(pvy_t, float) dev_pvy;
    DEVICE_OUTPUT(pvz_t, float) dev_pvz;
    DEVICE_OUTPUT(svx_t, float) dev_svx;
    DEVICE_OUTPUT(svy_t, float) dev_svy;
    DEVICE_OUTPUT(svz_t, float) dev_svz;
    DEVICE_OUTPUT(px_ks_t, float) dev_px_ks;
    DEVICE_OUTPUT(py_ks_t, float) dev_py_ks;
    DEVICE_OUTPUT(pz_ks_t, float) dev_pz_ks;
    DEVICE_OUTPUT(chi2trk_pi1_ks_t, float) dev_chi2trk_pi1_ks;
    DEVICE_OUTPUT(chi2trk_pi2_ks_t, float) dev_chi2trk_pi2_ks;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;

    DEVICE_OUTPUT(dev_histogram_ks_mass_t, unsigned) dev_histogram_ks_mass;
    DEVICE_OUTPUT(dev_histogram_ks_pt_t, unsigned) dev_histogram_ks_pt;
  };

  struct downstream_two_track_ks_line_t : public SelectionAlgorithm,
                                          Parameters,
                                          CompositeParticleLine<downstream_two_track_ks_line_t, Parameters> {
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
      float minZ_sv;
      float minZ_pv;
      bool OppositeSign;
      Allen::Monitoring::Histogram<>::DeviceType histogram_ks_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_ks_pt;
      DeviceProperties(const downstream_two_track_ks_line_t& algo, const Allen::Context& ctx) :
        maxVertexChi2(algo.m_maxVertexChi2), minComboPt_Ks(algo.m_minComboPt_Ks), minEta_Ks(algo.m_minEta_Ks),
        maxEta_Ks(algo.m_maxEta_Ks), minTrackPt_piKs(algo.m_minTrackPt_piKs), minTrackP_piKs(algo.m_minTrackP_piKs),
        minTrackIP_piKs(algo.m_minTrackIP_piKs), minM_Ks(algo.m_minM_Ks), maxM_Ks(algo.m_maxM_Ks),
        minZ_sv(algo.m_minZ_sv), minZ_pv(algo.m_minZ_pv), OppositeSign(algo.m_opposite_sign.value()),
        histogram_ks_mass(algo.m_histogram_ks_mass.data(ctx)), histogram_ks_pt(algo.m_histogram_ks_pt.data(ctx))
      {}
    };

    using monitoring_types = std::tuple<
      decision_t,
      pt_pi1_ks_t,
      pt_pi2_ks_t,
      p_pi1_ks_t,
      p_pi2_ks_t,
      ipchi2_pi1_ks_t,
      ipchi2_pi2_ks_t,
      ip_pi1_ks_t,
      ip_pi2_ks_t,
      ip_ks_t,
      pt_ks_t,
      chi2vtx_ks_t,
      dira_ks_t,
      eta_ks_t,
      mks_t,
      pvx_t,
      pvy_t,
      pvz_t,
      svx_t,
      svy_t,
      svz_t,
      px_ks_t,
      py_ks_t,
      pz_ks_t,
      chi2trk_pi1_ks_t,
      chi2trk_pi2_ks_t,
      evtNo_t,
      runNo_t>;

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input);

    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

  private:
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 20.f, "maxVertexChi2 description"};
    Allen::Property<float> m_minComboPt_Ks {this,
                                            "minComboPt_Ks",
                                            3500.f * Allen::Units::MeV,
                                            "minComboPt_Ks description"};
    Allen::Property<float> m_minEta_Ks {this, "minEta_Ks", 2.f, "minEta_Ks description"};
    Allen::Property<float> m_maxEta_Ks {this, "maxEta_Ks", 4.2f, "maxEta_Ks description"};
    Allen::Property<float> m_minTrackPt_piKs {this,
                                              "minTrackPt_piKs",
                                              475.f * Allen::Units::MeV,
                                              "minTrackPt_piKs description"};
    Allen::Property<float> m_minTrackP_piKs {this,
                                             "minTrackP_piKs",
                                             5000.f * Allen::Units::MeV,
                                             "minTrackP_piKs description"};
    Allen::Property<float> m_minTrackIP_piKs {this, "minTrackIP_piKs", 1.f, "minTrackIP_piKs description"};
    Allen::Property<float> m_minM_Ks {this, "minM_Ks", 400.0f * Allen::Units::MeV, "minM_Ks description"};
    Allen::Property<float> m_maxM_Ks {this, "maxM_Ks", 600.0f * Allen::Units::MeV, "maxM_Ks description"};
    Allen::Property<float> m_minZ_sv {this, "minZ_sv", 400.f * Allen::Units::mm, "minZ_sv description"};
    Allen::Property<float> m_minZ_pv {this, "minZ_pv", -330.f * Allen::Units::mm, "minZ_pv description"};
    Allen::Property<bool> m_opposite_sign {this, "OppositeSign", true, "Selects opposite sign dibody combinations"};

    Allen::Monitoring::Histogram<> m_histogram_ks_mass {this, "ks_mass", "m(ks)", {100u, 400.f, 600.f}};
    Allen::Monitoring::Histogram<> m_histogram_ks_pt {this, "ks_pt", "pT(ks)", {100u, 0.f, 1e4f}};
  };
} // namespace downstream_two_track_ks_line

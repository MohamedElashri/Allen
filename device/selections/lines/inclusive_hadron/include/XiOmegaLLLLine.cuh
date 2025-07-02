/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
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

namespace xi_omega_lll_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(Xipi_M_t, float) Xipi_M;
    DEVICE_OUTPUT(Omegapi_M_t, float) Omegapi_M;
    DEVICE_OUTPUT(PT_t, float) PT;
    DEVICE_OUTPUT(DOCA_t, float) DOCA;
    DEVICE_OUTPUT(VZ_t, float) VZ;
    DEVICE_OUTPUT(BPVVDZ_t, float) BPVVDZ;
    DEVICE_OUTPUT(BPVVDRHO_t, float) BPVVDRHO;
    DEVICE_OUTPUT(BPVDIRA_t, float) BPVDIRA;
    DEVICE_OUTPUT(BPVIP_t, float) BPVIP;
    DEVICE_OUTPUT(BPVFD_t, float) BPVFD;
    DEVICE_OUTPUT(Xi_M_t, float) Xi_M;
    DEVICE_OUTPUT(Omega_M_t, float) Omega_M;
    DEVICE_OUTPUT(XimOmm_PT_t, float) XimOmm_PT;
    DEVICE_OUTPUT(XimOmm_DOCA_t, float) XimOmm_DOCA;
    DEVICE_OUTPUT(XimOmm_VZ_t, float) XimOmm_VZ;
    DEVICE_OUTPUT(XimOmm_BPVVDZ_t, float) XimOmm_BPVVDZ;
    DEVICE_OUTPUT(XimOmm_BPVVDRHO_t, float) XimOmm_BPVVDRHO;
    DEVICE_OUTPUT(XimOmm_BPVDIRA_t, float) XimOmm_BPVDIRA;
    DEVICE_OUTPUT(XimOmm_BPVIP_t, float) XimOmm_BPVIP;
    DEVICE_OUTPUT(XimOmm_BPVFD_t, float) XimOmm_BPVFD;
    DEVICE_OUTPUT(t_P_t, float) t_P;
    DEVICE_OUTPUT(t_PT_t, float) t_PT;
    DEVICE_OUTPUT(t_MIPCHI2_t, float) t_MIPCHI2;
    DEVICE_OUTPUT(t_MIP_t, float) t_MIP;
    DEVICE_OUTPUT(t_CHI2NDF_t, float) t_CHI2NDF;
    DEVICE_OUTPUT(t_Q_t, float) t_Q;
    DEVICE_OUTPUT(XimOmm_t_P_t, float) XimOmm_t_P;
    DEVICE_OUTPUT(XimOmm_t_PT_t, float) XimOmm_t_PT;
    DEVICE_OUTPUT(XimOmm_t_MIPCHI2_t, float) XimOmm_t_MIPCHI2;
    DEVICE_OUTPUT(XimOmm_t_MIP_t, float) XimOmm_t_MIP;
    DEVICE_OUTPUT(XimOmm_t_CHI2NDF_t, float) XimOmm_t_CHI2NDF;
    DEVICE_OUTPUT(XimOmm_t_Q_t, float) XimOmm_t_Q;
    DEVICE_OUTPUT(p_P_t, float) p_P;
    DEVICE_OUTPUT(p_PT_t, float) p_PT;
    DEVICE_OUTPUT(p_MIPCHI2_t, float) p_MIPCHI2;
    DEVICE_OUTPUT(p_MIP_t, float) p_MIP;
    DEVICE_OUTPUT(p_CHI2NDF_t, float) p_CHI2NDF;
    DEVICE_OUTPUT(p_Q_t, float) p_Q;
    DEVICE_OUTPUT(pi_P_t, float) pi_P;
    DEVICE_OUTPUT(pi_PT_t, float) pi_PT;
    DEVICE_OUTPUT(pi_MIPCHI2_t, float) pi_MIPCHI2;
    DEVICE_OUTPUT(pi_MIP_t, float) pi_MIP;
    DEVICE_OUTPUT(pi_CHI2NDF_t, float) pi_CHI2NDF;
    DEVICE_OUTPUT(pi_Q_t, float) pi_Q;
    DEVICE_OUTPUT(p_pi_DOCA_t, float) p_pi_DOCA;
    DEVICE_OUTPUT(L_M_t, float) L_M;
    DEVICE_OUTPUT(L_VCHI2_t, float) L_VCHI2;
    DEVICE_OUTPUT(L_VZ_t, float) L_VZ;
    DEVICE_OUTPUT(L_PT_t, float) L_PT;
    DEVICE_OUTPUT(L_BPVVDCHI2_t, float) L_BPVVDCHI2;
    DEVICE_OUTPUT(L_BPVVDZ_t, float) L_BPVVDZ;
    DEVICE_OUTPUT(L_BPVVDRHO_t, float) L_BPVVDRHO;
    DEVICE_OUTPUT(L_BPVDIRA_t, float) L_BPVDIRA;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct xi_omega_lll_line_t : public SelectionAlgorithm,
                               Parameters,
                               CompositeParticleLine<xi_omega_lll_line_t, Parameters> {
    struct DeviceProperties {
      float L_DOCA_max;
      float L_VCHI2_max;
      float L_M_min;
      float L_M_max;
      float BPVZ_min;
      float VZ_min;
      float VZ_max;
      float Xi_M_min;
      float Xi_M_max;
      float Omega_M_min;
      float Omega_M_max;
      float t_PT_min;
      float t_MIPCHI2_min;
      float XimOmmt_M_max;
      float LVDZ_min;
      float XimOmmVDZ_min;
      float BPVVDZ_min;
      float BPVVDRHO_min;
      Allen::Monitoring::Histogram<>::DeviceType histogram_Lambda_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_Xi_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_Omega_mass;
      DeviceProperties(const xi_omega_lll_line_t& algo, const Allen::Context& ctx) :
        L_DOCA_max(algo.m_L_DOCA_max), L_VCHI2_max(algo.m_L_VCHI2_max), L_M_min(algo.m_L_M_min),
        L_M_max(algo.m_L_M_max), BPVZ_min(algo.m_BPVZ_min), VZ_min(algo.m_VZ_min), VZ_max(algo.m_VZ_max),
        Xi_M_min(algo.m_Xi_M_min), Xi_M_max(algo.m_Xi_M_max), Omega_M_min(algo.m_Omega_M_min),
        Omega_M_max(algo.m_Omega_M_max), t_PT_min(algo.m_t_PT_min), t_MIPCHI2_min(algo.m_t_MIPCHI2_min),
        XimOmmt_M_max(algo.m_XimOmmt_M_max), LVDZ_min(algo.m_LVDZ_min), XimOmmVDZ_min(algo.m_XimOmmVDZ_min),
        BPVVDZ_min(algo.m_BPVVDZ_min), BPVVDRHO_min(algo.m_BPVVDRHO_min),
        histogram_Lambda_mass(algo.m_histogram_Lambda_mass.data(ctx)),
        histogram_Xi_mass(algo.m_histogram_Xi_mass.data(ctx)),
        histogram_Omega_mass(algo.m_histogram_Omega_mass.data(ctx))
      {}
    };

    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle>,
      unsigned,
      bool);
    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle>,
      unsigned,
      bool);

    using monitoring_types = std::tuple<
      Xipi_M_t,
      Omegapi_M_t,
      PT_t,
      DOCA_t,
      VZ_t,
      BPVVDZ_t,
      BPVVDRHO_t,
      BPVDIRA_t,
      BPVIP_t,
      BPVFD_t,
      Xi_M_t,
      Omega_M_t,
      XimOmm_PT_t,
      XimOmm_DOCA_t,
      XimOmm_VZ_t,
      XimOmm_BPVVDZ_t,
      XimOmm_BPVVDRHO_t,
      XimOmm_BPVDIRA_t,
      XimOmm_BPVIP_t,
      XimOmm_BPVFD_t,
      t_P_t,
      t_PT_t,
      t_MIPCHI2_t,
      t_MIP_t,
      t_CHI2NDF_t,
      t_Q_t,
      XimOmm_t_P_t,
      XimOmm_t_PT_t,
      XimOmm_t_MIPCHI2_t,
      XimOmm_t_MIP_t,
      XimOmm_t_CHI2NDF_t,
      XimOmm_t_Q_t,
      p_P_t,
      p_PT_t,
      p_MIPCHI2_t,
      p_MIP_t,
      p_CHI2NDF_t,
      p_Q_t,
      pi_P_t,
      pi_PT_t,
      pi_MIPCHI2_t,
      pi_MIP_t,
      pi_CHI2NDF_t,
      pi_Q_t,
      p_pi_DOCA_t,
      L_M_t,
      L_VCHI2_t,
      L_VZ_t,
      L_PT_t,
      L_BPVVDCHI2_t,
      L_BPVVDZ_t,
      L_BPVVDRHO_t,
      L_BPVDIRA_t,
      evtNo_t,
      runNo_t>;

  private:
    Allen::Property<float> m_L_DOCA_max {this, "L_DOCA_max", 180.f * Allen::Units::um, "max p, pi DOCA for Lambda LL"};
    Allen::Property<float> m_L_VCHI2_max {this, "L_VCHI2_max", 24.f, "Lambda vertex chi2"};
    Allen::Property<float> m_L_M_min {this, "L_M_min", 1090.f * Allen::Units::MeV, "min mass of Lambda candidate"};
    Allen::Property<float> m_L_M_max {this, "L_M_max", 1140.f * Allen::Units::MeV, "max mass of Lambda candidate"};
    Allen::Property<float> m_BPVZ_min {this, "BPVZ_min", -200.f * Allen::Units::mm, "min primary vertex z position"};
    Allen::Property<float> m_VZ_min {this, "VZ_min", -200.f * Allen::Units::mm, "min vertex z position"};
    Allen::Property<float> m_VZ_max {this, "VZ_max", 640.f * Allen::Units::mm, "max vertex z position"};
    Allen::Property<float> m_Xi_M_min {this,
                                       "Xi_M_min",
                                       1292.f * Allen::Units::MeV,
                                       "min mass given pion mass hypothesis for tertiary track"};
    Allen::Property<float> m_Xi_M_max {this,
                                       "Xi_M_max",
                                       1352.f * Allen::Units::MeV,
                                       "max mass given pion mass hypothesis for tertiary track"};
    Allen::Property<float> m_Omega_M_min {this,
                                          "Omega_M_min",
                                          1647.f * Allen::Units::MeV,
                                          "min mass given kaon mass hypothesis for tertiary track"};
    Allen::Property<float> m_Omega_M_max {this,
                                          "Omega_M_max",
                                          1697.f * Allen::Units::MeV,
                                          "max mass given kaon mass hypothesis for tertiary track"};
    Allen::Property<float> m_t_PT_min {this, "t_PT_min", 280.f * Allen::Units::MeV, "min companion track pT"};
    Allen::Property<float> m_t_MIPCHI2_min {this, "t_MIPCHI2_min", 6.f, "min companion track IP chi2"};
    Allen::Property<float> m_XimOmmt_M_max {this,
                                            "XimOmmt_M_max",
                                            6.f * Allen::Units::GeV,
                                            "max mass given muon mass hypothesis for companion track"};
    Allen::Property<float> m_LVDZ_min {this,
                                       "LVDZ_min",
                                       4.f * Allen::Units::mm,
                                       "min distance (in z) of Lambda to Xi/Omega vertex"};
    Allen::Property<float> m_XimOmmVDZ_min {this,
                                            "XimOmmVDZ_min",
                                            4.f * Allen::Units::mm,
                                            "min distance (in z) of Xi/Omega to charm vertex"};
    Allen::Property<float> m_BPVVDZ_min {this, "BPVVDZ_min", 1.f * Allen::Units::mm, "min distance (in z) to best PV"};
    Allen::Property<float> m_BPVVDRHO_min {this,
                                           "BPVVDRHO_min",
                                           75.f * Allen::Units::um,
                                           "min radial distance to best PV"};

    Allen::Monitoring::Histogram<> m_histogram_Lambda_mass {
      this,
      "Lambda_mass_XiOmegaLLL",
      "m(p#pi^{#minus}) [MeV]",
      {100u, 1090.f * Allen::Units::MeV, 1140.f * Allen::Units::MeV}};
    Allen::Monitoring::Histogram<> m_histogram_Xi_mass {this,
                                                        "Xi_mass",
                                                        "m(#Lambda#pi^{#minus}) [MeV]",
                                                        {60u, 1292.f * Allen::Units::MeV, 1352.f * Allen::Units::MeV}};
    Allen::Monitoring::Histogram<> m_histogram_Omega_mass {
      this,
      "Omega_mass",
      "m(#LambdaK^{#minus}) [MeV]",
      {50u, 1647.f * Allen::Units::MeV, 1697.f * Allen::Units::MeV}};
  };
} // namespace xi_omega_lll_line

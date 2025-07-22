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

namespace lambda_ll_detached_track_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(M_t, float) M;
    DEVICE_OUTPUT(MCORR_t, float) MCORR;
    DEVICE_OUTPUT(PT_t, float) PT;
    DEVICE_OUTPUT(DOCA_t, float) DOCA;
    DEVICE_OUTPUT(VZ_t, float) VZ;
    DEVICE_OUTPUT(BPVVDZ_t, float) BPVVDZ;
    DEVICE_OUTPUT(BPVVDRHO_t, float) BPVVDRHO;
    DEVICE_OUTPUT(BPVDIRA_t, float) BPVDIRA;
    DEVICE_OUTPUT(BPVIP_t, float) BPVIP;
    DEVICE_OUTPUT(BPVFD_t, float) BPVFD;
    DEVICE_OUTPUT(t_P_t, float) t_P;
    DEVICE_OUTPUT(t_PT_t, float) t_PT;
    DEVICE_OUTPUT(t_MIPCHI2_t, float) t_MIPCHI2;
    DEVICE_OUTPUT(t_MIP_t, float) t_MIP;
    DEVICE_OUTPUT(t_CHI2NDF_t, float) t_CHI2NDF;
    DEVICE_OUTPUT(t_Q_t, float) t_Q;
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

  struct lambda_ll_detached_track_line_t : public SelectionAlgorithm,
                                           Parameters,
                                           CompositeParticleLine<lambda_ll_detached_track_line_t, Parameters> {
    struct DeviceProperties {
      float pi_PT_min;
      float p_PT_min;
      float pi_MIPCHI2_min;
      float p_MIPCHI2_min;
      float L_PT_min;
      float L_DOCA_max;
      float L_VCHI2_max;
      float L_BPVFDCHI2_min;
      float L_M_min;
      float L_M_max;
      float t_MIPCHI2_min;
      float t_PT_min;
      float VZ_min;
      float VZ_max;
      float M_max;
      float BPVVDZ_min;
      float BPVVDRHO_min;
      float LVDZ_min;
      float SUMPT_min;
      Allen::Monitoring::Histogram<>::DeviceType histogram_Lambda_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_LambdaPi_mass;
      DeviceProperties(const lambda_ll_detached_track_line_t& algo, const Allen::Context& ctx) :
        pi_PT_min(algo.m_pi_PT_min), p_PT_min(algo.m_p_PT_min), pi_MIPCHI2_min(algo.m_pi_MIPCHI2_min),
        p_MIPCHI2_min(algo.m_p_MIPCHI2_min), L_PT_min(algo.m_L_PT_min), L_DOCA_max(algo.m_L_DOCA_max),
        L_VCHI2_max(algo.m_L_VCHI2_max), L_BPVFDCHI2_min(algo.m_L_BPVFDCHI2_min), L_M_min(algo.m_L_M_min),
        L_M_max(algo.m_L_M_max), t_MIPCHI2_min(algo.m_t_MIPCHI2_min), t_PT_min(algo.m_t_PT_min), VZ_min(algo.m_VZ_min),
        VZ_max(algo.m_VZ_max), M_max(algo.m_M_max), BPVVDZ_min(algo.m_BPVVDZ_min), BPVVDRHO_min(algo.m_BPVVDRHO_min),
        LVDZ_min(algo.m_LVDZ_min), SUMPT_min(algo.m_SUMPT_min),
        histogram_Lambda_mass(algo.m_histogram_Lambda_mass.data(ctx)),
        histogram_LambdaPi_mass(algo.m_histogram_LambdaPi_mass.data(ctx))
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
      M_t,
      MCORR_t,
      PT_t,
      DOCA_t,
      VZ_t,
      BPVVDZ_t,
      BPVVDRHO_t,
      BPVDIRA_t,
      BPVIP_t,
      BPVFD_t,
      t_P_t,
      t_PT_t,
      t_MIPCHI2_t,
      t_MIP_t,
      t_CHI2NDF_t,
      t_Q_t,
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
    Allen::Property<float> m_pi_PT_min {this, "pi_PT_min", 130.f * Allen::Units::MeV, "pT of pion candidate"};
    Allen::Property<float> m_p_PT_min {this, "p_PT_min", 1200.f * Allen::Units::MeV, "pT of proton candidate"};
    Allen::Property<float> m_pi_MIPCHI2_min {this, "pi_MIPCHI2_min", 64.f, "min IP chi2 of pion candidate"};
    Allen::Property<float> m_p_MIPCHI2_min {this, "p_MIPCHI2_min", 12.f, "min IP chi2 of proton candidate"};
    Allen::Property<float> m_L_PT_min {this, "L_PT_min", 1400.f * Allen::Units::MeV, "pT of Lambda candidate"};
    Allen::Property<float> m_L_DOCA_max {this, "L_DOCA_max", 100.f * Allen::Units::um, "DOCA of proton and pion"};
    Allen::Property<float> m_L_VCHI2_max {this, "L_VCHI2_max", 16.f, "Lambda vertex chi2"};
    Allen::Property<float> m_L_BPVFDCHI2_min {this,
                                              "L_BPVFDCHI2_min",
                                              240.f,
                                              "flight distance chi2 of Lambda candidate"};
    Allen::Property<float> m_L_M_min {this, "L_M_min", 1090.f * Allen::Units::MeV, "min mass of Lambda candidate"};
    Allen::Property<float> m_L_M_max {this, "L_M_max", 1140.f * Allen::Units::MeV, "max mass of Lambda candidate"};
    Allen::Property<float> m_t_MIPCHI2_min {this, "t_MIPCHI2_min", 12.f, "min companion track IP chi2"};
    Allen::Property<float> m_t_PT_min {this, "t_PT_min", 700.f * Allen::Units::MeV, "min companion track PT"};
    Allen::Property<float> m_VZ_min {this, "VZ_min", -200.f * Allen::Units::mm, "min vertex z position"};
    Allen::Property<float> m_VZ_max {this, "VZ_max", 250.f * Allen::Units::mm, "max vertex z position"};
    Allen::Property<float> m_M_max {this,
                                    "M_max",
                                    3.6f * Allen::Units::GeV,
                                    "max mass given pion mass hypothesis for companion track"};
    Allen::Property<float> m_BPVVDZ_min {this, "BPVVDZ_min", 1.5f * Allen::Units::mm, "min distance (in z) to best PV"};
    Allen::Property<float> m_BPVVDRHO_min {this,
                                           "BPVVDRHO_min",
                                           120.f * Allen::Units::um,
                                           "min distance (in z) to best PV"};
    Allen::Property<float> m_LVDZ_min {this,
                                       "LVDZ_min",
                                       8.f * Allen::Units::mm,
                                       "min distance (in z) to Lambda vertex"};
    Allen::Property<float> m_SUMPT_min {this, "SUMPT_min", 2.8f * Allen::Units::GeV, "sum of Lambda and track pT"};

    Allen::Monitoring::Histogram<> m_histogram_Lambda_mass {
      this,
      "Lambda_mass_LambdaLLDetachedTrack",
      "m(p#pi^{#minus}) [MeV]",
      {100u, 1090.f * Allen::Units::MeV, 1140.f * Allen::Units::MeV}};
    Allen::Monitoring::Histogram<> m_histogram_LambdaPi_mass {
      this,
      "LambdaTrack_mass",
      "m(#Lambda#pi^{+}) [MeV]",
      {94u, 1.25f * Allen::Units::GeV, 3.6f * Allen::Units::GeV}};
  };
} // namespace lambda_ll_detached_track_line

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
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line tupling", bool) enable_tupling;

    PROPERTY(L_M_max_t, "L_M_max", "max mass of Lambda candidate", float) L_M_max;
    PROPERTY(t_PT_min_t, "t_PT_min", "min companion track pT", float) t_PT_min;
    PROPERTY(t_MIPCHI2_min_t, "t_MIPCHI2_min", "min companion track IP chi2", float) t_MIPCHI2_min;
    PROPERTY(L_t_DOCA_max_t, "L_t_DOCA_max", "DOCA of Lambda and companion track", float) L_t_DOCA_max;
    PROPERTY(Xi_M_max_t, "Xi_M_max", "max mass given pion mass hypothesis for companion track", float) Xi_M_max;
    PROPERTY(Omega_M_max_t, "Omega_M_max", "max mass given kaon mass hypothesis for companion track", float)
    Omega_M_max;
    PROPERTY(VZ_min_t, "VZ_min", "min vertex z position", float) VZ_min;
    PROPERTY(VZ_max_t, "VZ_max", "max vertex z position", float) VZ_max;
    PROPERTY(BPVVDZ_min_t, "BPVVDZ_min", "min distance (in z) to best PV", float) BPVVDZ_min;
    PROPERTY(LVDZ_min_t, "LVDZ_min", "min distance (in z) to Lambda vertex", float) LVDZ_min;
    PROPERTY(BPVDIRA_min_t, "BPVDIRA_min", "min DIRA to best PV", float) BPVDIRA_min;
    PROPERTY(BPVDRHO_min_t, "BPVDRHO_min", "min radial distance to best PV", float) BPVDRHO_min;

    DEVICE_OUTPUT(Xi_M_t, float) Xi_M;
    DEVICE_OUTPUT(Omega_M_t, float) Omega_M;
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

  struct xi_omega_lll_line_t : public SelectionAlgorithm,
                               Parameters,
                               CompositeParticleLine<xi_omega_lll_line_t, Parameters> {
    struct DeviceAccumulators {
      Allen::Monitoring::Histogram<>::DeviceType histogram_Lambda_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_Xi_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_Omega_mass;
      DeviceAccumulators(const xi_omega_lll_line_t& algo, const Allen::Context& ctx) :
        histogram_Lambda_mass(algo.m_histogram_Lambda_mass.data(ctx)),
        histogram_Xi_mass(algo.m_histogram_Xi_mass.data(ctx)),
        histogram_Omega_mass(algo.m_histogram_Omega_mass.data(ctx))
      {}
    };

    __device__ static bool
    select(const Parameters&, const DeviceAccumulators&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);
    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceAccumulators& accumulators,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<
      Xi_M_t,
      Omega_M_t,
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
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<L_M_max_t> m_L_M_max {this, 1140.f * Gaudi::Units::MeV};
    Property<t_PT_min_t> m_t_PT_min {this, 80.f * Gaudi::Units::MeV};
    Property<t_MIPCHI2_min_t> m_t_MIPCHI2_min {this, 9.f};
    Property<L_t_DOCA_max_t> m_L_t_DOCA_max {this, 500.f * Gaudi::Units::um};
    Property<VZ_min_t> m_VZ_min {this, -341.f * Gaudi::Units::mm};
    Property<VZ_max_t> m_VZ_max {this, 640.f * Gaudi::Units::mm};
    Property<Xi_M_max_t> m_Xi_M_max {this, 1350.f * Gaudi::Units::MeV};
    Property<Omega_M_max_t> m_Omega_M_max {this, 1710.f * Gaudi::Units::MeV};
    Property<BPVVDZ_min_t> m_BPVVDZ_min {this, 4.f * Gaudi::Units::mm};
    Property<BPVDRHO_min_t> m_BPVDRHO_min {this, 0.5f * Gaudi::Units::mm};
    Property<LVDZ_min_t> m_LVDZ_min {this, 8.f * Gaudi::Units::mm};
    Property<BPVDIRA_min_t> m_BPVDIRA_min {this, 0.99};
    Property<enable_monitoring_t> m_enable_monitoring {this, false};
    Property<enable_tupling_t> m_enable_tupling {this, false};

    Allen::Monitoring::Histogram<> m_histogram_Lambda_mass {
      this,
      "Lambda_mass_XiOmegaLLL",
      "m(p#pi^{#minus}) [MeV]",
      {125u, 1077.5f * Gaudi::Units::MeV, 1140.f * Gaudi::Units::MeV}};
    Allen::Monitoring::Histogram<> m_histogram_Xi_mass {this,
                                                        "Xi_mass",
                                                        "m(#Lambda#pi^{#minus}) [MeV]",
                                                        {96u, 1254.f * Gaudi::Units::MeV, 1350.f * Gaudi::Units::MeV}};
    Allen::Monitoring::Histogram<> m_histogram_Omega_mass {
      this,
      "Omega_mass",
      "m(#LambdaK^{#minus}) [MeV]",
      {100u, 1610.f * Gaudi::Units::MeV, 1710.f * Gaudi::Units::MeV}};
  };
} // namespace xi_omega_lll_line

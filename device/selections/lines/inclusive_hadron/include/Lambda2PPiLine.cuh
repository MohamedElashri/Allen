/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "TwoTrackLine.cuh"
#include "MassDefinitions.h"

namespace lambda2ppi_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line monitoring", bool) enable_tupling;
    PROPERTY(L_p_MIPCHI2_min_t, "L_p_MIPCHI2_min", "proton min ip chi^2 for Lambda LL", float) L_p_MIPCHI2_min;
    PROPERTY(L_pi_MIPCHI2_min_t, "L_pi_MIPCHI2_min", "pion min ip chi^2 for Lambda LL", float) L_pi_MIPCHI2_min;
    PROPERTY(L_p_MIP_min_t, "L_p_MIP_min", "proton min ip for Lambda LL", float) L_p_MIP_min;
    PROPERTY(L_pi_MIP_min_t, "L_pi_MIP_min", "pion min ip for Lambda LL", float) L_pi_MIP_min;
    PROPERTY(L_p_PT_min_t, "L_p_PT_min", "proton min pT for Lambda LL", float) L_p_PT_min;
    PROPERTY(L_pi_PT_min_t, "L_pi_PT_min", "pion min pT for Lambda LL", float) L_pi_PT_min;
    PROPERTY(L_DOCA_max_t, "L_DOCA_max", "max p,pi DOCA for Lambda LL", float) L_DOCA_max;
    PROPERTY(L_PT_min_t, "L_PT_min", "min pT of Lambda LL", float) L_PT_min;
    PROPERTY(L_M_max_t, "L_M_max", "max mass for Lambda LL", float) L_M_max;
    PROPERTY(L_VCHI2_max_t, "L_VCHI2_max", "max p pi vertex chi2", float) L_VCHI2_max;
    PROPERTY(L_VZ_min_t, "L_VZ_min", "min vertex z position of Lambda candidate", float) L_VZ_min;
    PROPERTY(L_VZ_max_t, "L_VZ_max", "max vertex z position of Lambda candidate", float) L_VZ_max;
    PROPERTY(L_BPVVDZ_min_t, "L_BPVVDZ_min", "min distance (in z) between Lambda vertex and best PV", float)
    L_BPVVDZ_min;
    PROPERTY(
      L_BPVVDCHI2_min_t,
      "L_BPVVDCHI2_min",
      "min flight distance chi2 between p pi vertex and its best PV",
      float)
    L_BPVVDCHI2_min;
    PROPERTY(
      L_BPVVDRHO_min_t,
      "L_BPVVDRHO_min",
      "min squared radial vertex distance of Lambda w.r.t. its best PV",
      float)
    L_BPVVDRHO_min;
    PROPERTY(L_BPVDIRA_min_t, "L_BPVDIRA_min", "min cosine of direction angle of Lambda w.r.t. its best PV", float)
    L_BPVDIRA_min;

    DEVICE_OUTPUT(L_M_t, float) L_M;
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
    DEVICE_OUTPUT(L_PT_t, float) L_PT;
    DEVICE_OUTPUT(L_VCHI2_t, float) L_VCHI2;
    DEVICE_OUTPUT(L_BPVVDCHI2_t, float) L_BPVVDCHI2;
    DEVICE_OUTPUT(L_BPVVDZ_t, float) L_BPVVDZ;
    DEVICE_OUTPUT(L_BPVVDRHO_t, float) L_BPVVDRHO;
    DEVICE_OUTPUT(L_BPVDIRA_t, float) L_BPVDIRA;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct lambda2ppi_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<lambda2ppi_line_t, Parameters> {
    __device__ static bool select(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle>,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<
      L_M_t,
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
      L_VCHI2_t,
      p_pi_DOCA_t,
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
    Property<enable_tupling_t> m_enable_tupling {this, false};
    Property<L_p_MIPCHI2_min_t> m_L_p_MIPCHI2_min {this, 12.f};
    Property<L_pi_MIPCHI2_min_t> m_L_pi_MIPCHI2_min {this, 32.f};
    Property<L_p_MIP_min_t> m_L_p_MIP_min {this, 80.f * Gaudi::Units::um};
    Property<L_pi_MIP_min_t> m_L_pi_MIP_min {this, 200.f * Gaudi::Units::um};
    Property<L_p_PT_min_t> m_L_p_PT_min {this, 450.f * Gaudi::Units::MeV};
    Property<L_pi_PT_min_t> m_L_pi_PT_min {this, 80.f * Gaudi::Units::MeV};
    Property<L_DOCA_max_t> m_DOCA_max {this, 500.f * Gaudi::Units::um};
    Property<L_PT_min_t> m_PT_min {this, 500.f * Gaudi::Units::MeV};
    Property<L_M_max_t> m_M_max {this, 1140.f * Gaudi::Units::MeV};
    Property<L_VCHI2_max_t> m_L_VCHI2_max {this, 16.f};
    Property<L_VZ_min_t> m_L_VZ_min {this, -80.f * Gaudi::Units::mm};
    Property<L_VZ_max_t> m_L_VZ_max {this, 650.f * Gaudi::Units::mm};
    Property<L_BPVVDCHI2_min_t> m_L_BPVVDCHI2_min {this, 180.f};
    Property<L_BPVVDZ_min_t> m_L_BPVVDZ_min {this, 12.f * Gaudi::Units::mm};
    Property<L_BPVVDRHO_min_t> m_L_BPVVDRHO_min {this, 2.f * Gaudi::Units::mm};
    Property<L_BPVDIRA_min_t> m_L_BPVDIRA_min {this, 0.9997};
  };
} // namespace lambda2ppi_line

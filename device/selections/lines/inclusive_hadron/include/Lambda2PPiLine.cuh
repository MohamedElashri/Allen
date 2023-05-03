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
    PROPERTY(p_MIPCHI2_min_t, "p_MIPCHI2_min", "Proton min IP chi^2 of p w.r.t. any PV", float) p_MIPCHI2_min;
    PROPERTY(pi_MIPCHI2_min_t, "pi_MIPCHI2_min", "Pion min IP chi^2 of pi w.r.t. any PV", float)
    pi_MIPCHI2_min;
    PROPERTY(p_P_min_t, "p_P_min", "min p of the proton candidate", float) p_P_min;
    PROPERTY(p_PT_min_t, "p_PT_min", "min pT of the proton candidate", float) p_PT_min;
    PROPERTY(L_M_max_t, "L_M_max", "max p pi invariant mass", float) L_M_max;
    PROPERTY(p_pi_DOCA_max_t, "p_pi_DOCA_max", "max distance of closest approach between p and pi candidates", float)
    p_pi_DOCA_max;
    PROPERTY(L_VCHI2_max_t, "L_VCHI2_max", "max p pi vertex chi2", float) L_VCHI2_max;
    PROPERTY(L_VZ_min_t, "L_VZ_min", "min vertex z position of Lambda candidate", float) L_VZ_min;
    PROPERTY(L_VZ_max_t, "L_VZ_max", "max vertex z position of Lambda candidate", float) L_VZ_max;
    PROPERTY(L_PT_min_t, "L_PT_min", "min Lambda pT", float) L_PT_min;
    PROPERTY(L_BPVVDZ_min_t, "L_BPVVDZ_min", "min distance (in z) between Lambda vertex and best PV", float)
    L_BPVVDZ_min;
    PROPERTY(
      L_BPVVDCHI2_min_t,
      "L_BPVVDCHI2_min",
      "min flight distance chi2 between p pi vertex and its best PV",
      float)
    L_BPVVDCHI2_min;
    PROPERTY(L_BPVVDRHO_min_t, "L_BPVVDRHO_min", "min radial vertex distance of Lambda w.r.t. its best PV", float)
    L_BPVVDRHO_min;
    PROPERTY(L_BPVDIRA_min_t, "L_BPVDIRA_min", "min cosine of direction angle of Lambda w.r.t. its best PV", float)
    L_BPVDIRA_min;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;

    DEVICE_OUTPUT(L_M_t, float) L_M;
    DEVICE_OUTPUT(p_P_t, float) p_P;
    DEVICE_OUTPUT(p_PT_t, float) p_PT;
    DEVICE_OUTPUT(p_MIPCHI2_t, float) p_MIPCHI2;
    DEVICE_OUTPUT(pi_P_t, float) pi_P;
    DEVICE_OUTPUT(pi_PT_t, float) pi_PT;
    DEVICE_OUTPUT(pi_MIPCHI2_t, float) pi_MIPCHI2;
    DEVICE_OUTPUT(L_VCHI2_t, float) L_VCHI2;
    DEVICE_OUTPUT(p_pi_DOCA_t, float) p_pi_DOCA;
    DEVICE_OUTPUT(L_PT_t, float) L_PT;
    DEVICE_OUTPUT(L_BPVVDCHI2_t, float) L_BPVVDCHI2;
    DEVICE_OUTPUT(L_BPVVDZ_t, float) L_BPVVDZ;
    DEVICE_OUTPUT(L_BPVVDRHO_t, float) L_BPVVDRHO;
    DEVICE_OUTPUT(L_BPVDIRA_t, float) L_BPVDIRA;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct lambda2ppi_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<lambda2ppi_line_t, Parameters> {
    __device__ static bool select(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    __device__ static void monitor(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<
      L_M_t,
      p_P_t,
      p_PT_t,
      p_MIPCHI2_t,
      pi_P_t,
      pi_PT_t,
      pi_MIPCHI2_t,
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
    Property<p_MIPCHI2_min_t> m_p_MIPCHI2_min {this, 12.f};
    Property<pi_MIPCHI2_min_t> m_pi_MIPCHI2_min {this, 32.f};
    Property<p_P_min_t> m_p_P_min {this, 8.f * Gaudi::Units::GeV};
    Property<p_PT_min_t> m_p_PT_min {this, 600.f * Gaudi::Units::MeV};
    Property<L_M_max_t> m_L_M_max {this, 1140.f * Gaudi::Units::MeV};
    Property<p_pi_DOCA_max_t> m_p_pi_DOCA_max {this, 500.f * Gaudi::Units::um};
    Property<L_VCHI2_max_t> m_L_VCHI2_max {this, 16.f};
    Property<L_VZ_min_t> m_L_VZ_min {this, -80.f * Gaudi::Units::mm};
    Property<L_VZ_max_t> m_L_VZ_max {this, 650.f * Gaudi::Units::mm};
    Property<L_PT_min_t> m_L_PT_min {this, 700.f * Gaudi::Units::MeV};
    Property<L_BPVVDCHI2_min_t> m_L_BPVVDCHI2_min {this, 180.f};
    Property<L_BPVVDZ_min_t> m_L_BPVVDZ_min {this, 12.f * Gaudi::Units::mm};
    Property<L_BPVVDRHO_min_t> m_L_BPVVDRHO_min {this, 2.f * Gaudi::Units::mm};
    Property<L_BPVDIRA_min_t> m_L_BPVDIRA_min {this, 0.9997};

    Property<enable_monitoring_t> m_enableMonitoring {this, false};
  };
} // namespace lambda2ppi_line

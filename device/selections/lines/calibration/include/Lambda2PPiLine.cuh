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
    PROPERTY(p_BPVIPCHI2_min_t, "p_BPVIPCHI2_min", "Smallest min IP chi^2 of p w.r.t. any PV", float) p_BPVIPCHI2_min;
    PROPERTY(pi_BPVIPCHI2_min_t, "pi_BPVIPCHI2_min", "Smallest min IP chi^2 of pi w.r.t. any PV", float)
    pi_BPVIPCHI2_min;
    PROPERTY(p_P_min_t, "p_P_min", "min p of the proton candidate", float) p_P_min;
    PROPERTY(p_PT_min_t, "p_PT_min", "min pT of the proton candidate", float) p_PT_min;
    PROPERTY(diff_P_min_t, "diff_P_min", "min difference of proton minus pion p", float) diff_P_min;
    PROPERTY(diff_PT_min_t, "diff_PT_min", "min difference of proton minus pion pT", float) diff_PT_min;
    PROPERTY(L_M_max_t, "L_M_max", "max p pi invariant mass", float) L_M_max;
    PROPERTY(p_pi_DOCA_max_t, "p_pi_DOCA_max", "max distance of closest approach between p and pi candidates", float)
    p_pi_DOCA_max;
    PROPERTY(L_VCHI2_max_t, "L_VCHI2_max", "max p pi vertex chi2", float) L_VCHI2_max;
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
  };

  struct lambda2ppi_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<lambda2ppi_line_t, Parameters> {
    __device__ static bool select(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<p_BPVIPCHI2_min_t> m_L_min_BPVIPCHI2_min {this, 6.f};
    Property<pi_BPVIPCHI2_min_t> m_L_max_BPVIPCHI2_min {this, 24.f};
    Property<p_P_min_t> m_p_P_min {this, 6.f * Gaudi::Units::GeV};
    Property<p_PT_min_t> m_p_PT_min {this, 400.f * Gaudi::Units::MeV};
    Property<diff_P_min_t> diff_P_min {this, 1.f * Gaudi::Units::GeV};
    Property<diff_PT_min_t> diff_PT_min {this, 200.f * Gaudi::Units::MeV};
    Property<L_M_max_t> m_L_M_max {this, 1200.f * Gaudi::Units::MeV};
    Property<p_pi_DOCA_max_t> m_p_pi_DOCA_max {this, 500.f * Gaudi::Units::um};
    Property<L_VCHI2_max_t> m_L_VCHI2_max {this, 12.f};
    Property<L_PT_min_t> m_L_PT_min {this, 500.f * Gaudi::Units::MeV};
    Property<L_BPVVDCHI2_min_t> m_L_BPVVDCHI2_min {this, 60.f};
    Property<L_BPVVDZ_min_t> m_L_BPVVDZ_min {this, 4.f * Gaudi::Units::mm};
    Property<L_BPVVDRHO_min_t> m_L_BPVVDRHO_min {this, 2.f * Gaudi::Units::mm};
  };
} // namespace lambda2ppi_line

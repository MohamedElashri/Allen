/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "TwoTrackLine.cuh"

namespace di_muon_soft_line {
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
    PROPERTY(DESoftM0_t, "DESoftM0", "lower m(pipi) for KS->pipi veto", float) DESoftM0;
    PROPERTY(DESoftM1_t, "DESoftM1", "higher m(pipi) for KS->pipi veto", float) DESoftM1;
    PROPERTY(DESoftM2_t, "DESoftM2", "upper m(ee)", float) DESoftM2;
    PROPERTY(DESoftMinIPChi2_t, "DESoftMinIPChi2", "DESoftMinIPChi2 description", float) DESoftMinIPChi2;
    PROPERTY(DESoftMinRho2_t, "DESoftMinRho2", "DESoftMinRho2 description", float) DESoftMinRho2;
    PROPERTY(DESoftMinZ_t, "DESoftMinZ", "DESoftMinZ description", float) DESoftMinZ;
    PROPERTY(DESoftMaxZ_t, "DESoftMaxZ", "DESoftMaxZ description", float) DESoftMaxZ;
    PROPERTY(DESoftMaxDOCA_t, "DESoftMaxDOCA", "DESoftMaxDOCA description", float) DESoftMaxDOCA;
    PROPERTY(DESoftMaxIPDZ_t, "DESoftMaxIPDZ", "DESoftMaxIPDZ description", float) DESoftMaxIPDZ;
    PROPERTY(DESoftGhost_t, "DESoftGhost", "DESoftGhost description", float) DESoftGhost;
    PROPERTY(OppositeSign_t, "OppositeSign", "Selects opposite sign dielectron combinations", bool) OppositeSign;
  };

  struct di_electron_soft_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<di_electron_soft_line_t, Parameters> {
    __device__ static bool select(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<DESoftM0_t> m_DESoftM0 {this, 460.f};
    Property<DESoftM1_t> m_DESoftM1 {this, 536.f};
    Property<DESoftM2_t> m_DESoftM2 {this, 600.f};
    Property<DESoftMinIPChi2_t> m_DESoftMinIPChi2 {this, 100.f};
    Property<DESoftMinRho2_t> m_DESoftMinRho2 {this, 9.f};
    Property<DESoftMinZ_t> m_DESoftMinZ {this, -375.f};
    Property<DESoftMaxZ_t> m_DESoftMaxZ {this, 635.f};
    Property<DESoftMaxDOCA_t> m_DESoftMaxDOCA {this, 0.1f};
    Property<DESoftMaxIPDZ_t> m_DESoftMaxIPDZ {this, 0.04f};
    Property<DESoftGhost_t> m_DESoftGhost {this, 4.e-06f};
    Property<OppositeSign_t> m_opposite_sign {this, true};
  };
} // namespace di_electron_soft_line

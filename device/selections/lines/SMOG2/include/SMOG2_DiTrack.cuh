/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "TwoTrackLine.cuh"

namespace SMOG2_ditrack_line {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(maxTrackChi2Ndf_t, "minTrackChi2Ndf", "max track fit Chi2ndf", float) maxTrackChi2Ndf;
    PROPERTY(minTrackP_t, "minTrackP", "minimum final-state particles momentum", float) minTrackP;
    PROPERTY(minTrackPt_t, "minTrackPt", "minimum final-state particles transverse momentum", float) minTrackPt;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "max SV Chi2", float) maxVertexChi2;
    PROPERTY(maxDoca_t, "maxDoca", "max distance of closest approach", float) maxDoca;
    PROPERTY(minZ_t, "minZ", "minimum accepted SV z", float) minZ;
    PROPERTY(maxZ_t, "maxZ", "maximum accepted SV z", float) maxZ;
    PROPERTY(combCharge_t, "combCharge", "Charge of the combination", int) combCharge;
    PROPERTY(m1_t, "m1", "first final-state particle mass", float) m1;
    PROPERTY(m2_t, "m2", "second final-state particle mass", float) m2;
    PROPERTY(mMother_t, "mMother", "resonance mass", float) mMother;
    PROPERTY(massWindow_t, "massWindow", "maximum mass difference wrt mM", float) massWindow;
  };
  struct SMOG2_ditrack_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<SMOG2_ditrack_line_t, Parameters> {
    __device__ static bool select(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};

    Property<maxTrackChi2Ndf_t> m_maxTrackChi2Ndf {this, 4.f};
    Property<minTrackP_t> m_minTrackP {this, 3.f * Gaudi::Units::GeV};
    Property<minTrackPt_t> m_minTrackPt {this, 400.f * Gaudi::Units::MeV};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 25.f};
    Property<minZ_t> m_minZ {this, -550.f * Gaudi::Units::mm};
    Property<maxZ_t> m_maxZ {this, -300.f * Gaudi::Units::mm};
    Property<maxDoca_t> m_maxDoca {this, 0.5f * Gaudi::Units::mm};
    Property<combCharge_t> m_combCharge {this, 0};
    Property<m1_t> m_m1 {this, -1.f * Gaudi::Units::MeV};
    Property<m2_t> m_m2 {this, -1.f * Gaudi::Units::MeV};
    Property<mMother_t> m_mMother {this, -1.f * Gaudi::Units::MeV};
    Property<massWindow_t> m_massWindow {this, -1.f * Gaudi::Units::MeV};
  };
} // namespace SMOG2_ditrack_line

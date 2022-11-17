/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "TwoTrackLine.cuh"

namespace di_muon_mass_alignment_line {
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
    PROPERTY(minHighMassTrackPt_t, "minHighMassTrackPt", "minHighMassTrackPt description", float) minHighMassTrackPt;
    PROPERTY(minHighMassTrackP_t, "minHighMassTrackP", "minHighMassTrackP description", float) minHighMassTrackP;
    PROPERTY(minMass_t, "minMass", "minMass description", float) minMass;
    PROPERTY(maxDoca_t, "maxDoca", "maxDoca description", float) maxDoca;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "maxVertexChi2 description", float) maxVertexChi2;
    PROPERTY(minIPChi2_t, "minIPChi2", "minIPChi2 description", float) minIPChi2;
    PROPERTY(minZ_t, "minZ", "minimum vertex z coordinate", float) minZ;
  };

  struct di_muon_mass_alignment_line_t : public SelectionAlgorithm,
                                         Parameters,
                                         TwoTrackLine<di_muon_mass_alignment_line_t, Parameters> {
    __device__ static bool select(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minHighMassTrackPt_t> m_minHighMassTrackPt {this, 300.f / Gaudi::Units::MeV};
    Property<minHighMassTrackP_t> m_minHighMassTrackP {this, 6000.f / Gaudi::Units::MeV};
    Property<minMass_t> m_minMass {this, 9000.f / Gaudi::Units::MeV};
    Property<maxDoca_t> m_maxDoca {this, 0.2f};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 25.0f};
    Property<minIPChi2_t> m_minIPChi2 {this, 0.f};
    Property<minZ_t> m_minZ {this, -341.f * Gaudi::Units::mm};
  };
} // namespace di_muon_mass_alignment_line

/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "TwoTrackLine.cuh"

namespace displaced_di_muon_line {
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
    PROPERTY(minDispTrackPt_t, "minDispTrackPt", "minDispTrackPt description", float) minDispTrackPt;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "maxVertexChi2 description", float) maxVertexChi2;
    PROPERTY(dispMinIPChi2_t, "dispMinIPChi2", "dispMinIPChi2 description", float) dispMinIPChi2;
    PROPERTY(dispMinEta_t, "dispMinEta", "dispMinEta description", float) dispMinEta;
    PROPERTY(dispMaxEta_t, "dispMaxEta", "dispMaxEta description", float) dispMaxEta;
    PROPERTY(minZ_t, "minZ", "minimum vertex z dimuon coordinate", float) minZ;
  };

  struct displaced_di_muon_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    TwoTrackLine<displaced_di_muon_line_t, Parameters> {
    __device__ static bool select(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    // Dimuon track pt.
    Property<minDispTrackPt_t> m_minDispTrackPt {this, 500.f / Gaudi::Units::MeV};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 6.f};
    // Displaced dimuon selections.
    Property<dispMinIPChi2_t> m_dispMinIPChi2 {this, 6.f};
    Property<dispMinEta_t> m_dispMinEta {this, 2.f};
    Property<dispMaxEta_t> m_dispMaxEta {this, 5.f};
    Property<minZ_t> m_minZ {this, -300.f};
  };
} // namespace displaced_di_muon_line

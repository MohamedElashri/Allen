/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "TwoTrackLine.cuh"
#include "MassDefinitions.h"

namespace d2pipi_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_selected_events_t) dev_selected_events;
    HOST_OUTPUT(host_selected_events_size_t, unsigned) host_selected_events_size;
    DEVICE_OUTPUT(dev_selected_events_size_t, unsigned) dev_selected_events_size;
    DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
    DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
    DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
    DEVICE_OUTPUT(dev_decisions_t, bool) dev_decisions;
    DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned) dev_decisions_offsets;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_lhcbid_container_t, uint8_t) host_lhcbid_container;
    HOST_OUTPUT(host_particle_container_ptr_t, Allen::Views::Physics::IMultiEventParticleContainer*)
    host_particle_container_ptr;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(dev_particle_container_ptr_t, 
      DEPENDENCIES(dev_particle_container_t),
      Allen::Views::Physics::IMultiEventParticleContainer*)
    dev_particle_container_ptr;
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minComboPt_t, "minComboPt", "minComboPt description", float) minComboPt;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "maxVertexChi2 description", float) maxVertexChi2;
    PROPERTY(maxDOCA_t, "maxDOCA", "maxDOCA description", float) maxDOCA;
    PROPERTY(minEta_t, "minEta", "minEta description", float) minEta;
    PROPERTY(maxEta_t, "maxEta", "maxEta description", float) maxEta;
    PROPERTY(minTrackPt_t, "minTrackPt", "minTrackPt description", float) minTrackPt;
    PROPERTY(massWindow_t, "massWindow", "massWindow description", float) massWindow;
    PROPERTY(minTrackIP_t, "minTrackIP", "minTrackIP description", float) minTrackIP;
  };

  struct d2pipi_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<d2pipi_line_t, Parameters> {
    __device__ static bool select(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minComboPt_t> m_minComboPt {this, 2000.0f * Gaudi::Units::MeV};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 10.f};
    Property<maxDOCA_t> m_maxDOCA {this, 0.15f * Gaudi::Units::mm};
    Property<minEta_t> m_minEta {this, 2.0f};
    Property<maxEta_t> m_maxEta {this, 5.0f};
    Property<minTrackPt_t> m_minTrackPt {this, 800.f * Gaudi::Units::MeV};
    Property<massWindow_t> m_massWindow {this, 100.f * Gaudi::Units::MeV};
    Property<minTrackIP_t> m_minTrackIP {this, 0.06f * Gaudi::Units::mm};
  };
} // namespace d2pipi_line

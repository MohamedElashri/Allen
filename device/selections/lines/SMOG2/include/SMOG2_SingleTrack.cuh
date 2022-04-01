/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "OneTrackLine.cuh"

namespace SMOG2_singletrack_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_selected_events_size_t, unsigned) host_selected_events_size;
    
    DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
    DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
    DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
				    dev_particle_container_ptr_t,
				    DEPENDENCIES(dev_particle_container_t),
				    Allen::IMultiEventContainer*)
    dev_particle_container_ptr;
    DEVICE_OUTPUT(dev_decisions_t, bool) dev_decisions;
    DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned) dev_decisions_offsets;
    DEVICE_OUTPUT(dev_selected_events_size_t, unsigned) dev_selected_events_size;
																				
    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_selected_events_t) dev_selected_events;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string) pre_scaler_hash_string;
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string) post_scaler_hash_string;

    // SMOG2_SINGLETRACK
    PROPERTY(maxChi2Ndof_t, "maxChi2Ndof", "maximum track fit chi2 per degree of freedom", float) maxChi2Ndof;
    PROPERTY(minPt_t, "minPt", "minimum Pt", float) minPt;
    PROPERTY(minP_t, "minP", "minimum P", float) minP;
    PROPERTY(minBPVz_t, "minBPVz", "minimum z for the best associated primary vertex", float) minBPVz;
    PROPERTY(maxBPVz_t, "maxBPVz", "maximum z for the best associated primary vertex", float) maxBPVz;
  };
  struct SMOG2_singletrack_line_t : public SelectionAlgorithm, Parameters, OneTrackLine<SMOG2_singletrack_line_t, Parameters> {
    __device__ static bool select(const Parameters& parameters, std::tuple<const Allen::Views::Physics::BasicParticle> input);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minP_t> m_minP {this, 3.f * Gaudi::Units::GeV};
    Property<minPt_t> m_minPt {this, 1.f * Gaudi::Units::GeV};
    Property<maxChi2Ndof_t> m_maxChi2Ndof {this, 4.f};
    Property<minBPVz_t> m_minBPVz {this, -550.f * Gaudi::Units::mm};
    Property<maxBPVz_t> m_maxBPVz {this, -300.f * Gaudi::Units::mm};
  };
} // namespace SMOG2_singletrack_line

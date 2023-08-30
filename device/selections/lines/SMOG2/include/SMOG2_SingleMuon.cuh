/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "OneTrackLine.cuh"

namespace SMOG2_single_muon_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;
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
    PROPERTY(maxChi2Ndof_t, "maxChi2Ndof", "maxChi2Ndof description", float) maxChi2Ndof;
    PROPERTY(MinPt_t, "MinPt", "Minimum PT", float) MinPt;
    PROPERTY(MinP_t, "MinP", "Minimum P", float) MinP;
    PROPERTY(minBPVz_t, "minBPVz", "minimum z for the track BPV", float) minBPVz;
    PROPERTY(maxBPVz_t, "maxBPVz", "maximum z for the track BPV", float) maxBPVz;
  };

  struct SMOG2_single_muon_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    OneTrackLine<SMOG2_single_muon_line_t, Parameters> {
    __device__ static bool select(const Parameters& ps, std::tuple<const Allen::Views::Physics::BasicParticle> input);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<maxChi2Ndof_t> m_maxChi2Ndof {this, 100.f};
    Property<MinPt_t> m_MinPt {this, 500.f / Gaudi::Units::MeV};
    Property<MinP_t> m_MinP {this, 5000.f / Gaudi::Units::MeV};
    Property<minBPVz_t> m_minBPVz {this, -541.f * Gaudi::Units::mm};
    Property<maxBPVz_t> m_maxBPVz {this, -341.f * Gaudi::Units::mm};
  };
} // namespace SMOG2_single_muon_line

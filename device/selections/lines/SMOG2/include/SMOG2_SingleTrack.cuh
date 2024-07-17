/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "OneTrackLine.cuh"

namespace SMOG2_singletrack_line {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(maxChi2Ndof_t, "maxChi2Ndof", "maximum track fit chi2 per degree of freedom", float) maxChi2Ndof;
    PROPERTY(minPt_t, "minPt", "minimum Pt", float) minPt;
    PROPERTY(minP_t, "minP", "minimum P", float) minP;
    PROPERTY(minBPVz_t, "minBPVz", "minimum z for the best associated primary vertex", float) minBPVz;
    PROPERTY(maxBPVz_t, "maxBPVz", "maximum z for the best associated primary vertex", float) maxBPVz;
    PROPERTY(maxGhostProb_t, "maxGhostProb", "Maximum ghost probability of the tracks", float) maxGhostProb;
  };
  struct SMOG2_singletrack_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    OneTrackLine<SMOG2_singletrack_line_t, Parameters> {
    __device__ static bool select(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::BasicParticle> input);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minP_t> m_minP {this, 5000.f * Gaudi::Units::MeV};
    Property<minPt_t> m_minPt {this, 1500.f * Gaudi::Units::MeV};
    Property<maxChi2Ndof_t> m_maxChi2Ndof {this, 3.f};
    Property<minBPVz_t> m_minBPVz {this, -551.f * Gaudi::Units::mm};
    Property<maxBPVz_t> m_maxBPVz {this, -331.f * Gaudi::Units::mm};
    Property<maxGhostProb_t> m_maxGhostProb {this, 0.5};
  };
} // namespace SMOG2_singletrack_line

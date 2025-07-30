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
  };
  struct SMOG2_singletrack_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    OneTrackLine<SMOG2_singletrack_line_t, Parameters> {

    struct DeviceProperties {
      float minP;
      float minPt;
      float maxChi2Ndof;
      float minBPVz;
      float maxBPVz;
      float maxGhostProb;

      DeviceProperties(const SMOG2_singletrack_line_t& algo, const Allen::Context&) :
        minP(algo.m_minP), minPt(algo.m_minPt), maxChi2Ndof(algo.m_maxChi2Ndof), minBPVz(algo.m_minBPVz),
        maxBPVz(algo.m_maxBPVz), maxGhostProb(algo.m_maxGhostProb)
      {}
    };

    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::BasicParticle> input);

  private:
    Allen::Property<float> m_minP {this, "minP", 5000.f * Allen::Units::MeV, "minimum P"};
    Allen::Property<float> m_minPt {this, "minPt", 1500.f * Allen::Units::MeV, "minimum Pt"};
    Allen::Property<float> m_maxChi2Ndof {this, "maxChi2Ndof", 3.f, "maximum track fit chi2 per degree of freedom"};
    Allen::Property<float> m_minBPVz {this,
                                      "minBPVz",
                                      -537.5f * Allen::Units::mm,
                                      "minimum z for the best associated primary vertex"};
    Allen::Property<float> m_maxBPVz {this,
                                      "maxBPVz",
                                      -337.5f * Allen::Units::mm,
                                      "maximum z for the best associated primary vertex"};
    Allen::Property<float> m_maxGhostProb {this, "maxGhostProb", 0.5, "Maximum ghost probability of the tracks"};
  };
} // namespace SMOG2_singletrack_line

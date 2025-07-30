/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
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

namespace low_pt_muon_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
  };

  struct low_pt_muon_line_t : public SelectionAlgorithm, Parameters, OneTrackLine<low_pt_muon_line_t, Parameters> {

    struct DeviceProperties {
      float maxChi2Ndof;
      float minPt;
      float minIP;
      float minIPChi2;
      float minBPVz;
      DeviceProperties(const low_pt_muon_line_t& algo, const Allen::Context&) :
        maxChi2Ndof(algo.m_maxChi2Ndof), minPt(algo.m_minPt), minIP(algo.m_minIP), minIPChi2(algo.m_minIPChi2),
        minBPVz(algo.m_minBPVz)
      {}
    };
    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::BasicParticle> input);

  private:
    Allen::Property<float> m_maxChi2Ndof {this, "maxChi2Ndof", 100.f, "maxChi2Ndof description"};
    // NB: This pt cut is looser than default tracking threshold.
    Allen::Property<float> m_minPt {this, "minPt", 80.0f * Allen::Units::MeV, "minPt description"};
    Allen::Property<float> m_minIP {this, "minIP", 4.f, "minIP description"};
    Allen::Property<float> m_minIPChi2 {this, "minIPChi2", 7.4f, "minIPChi2 description"};
    Allen::Property<float> m_minBPVz {this,
                                      "minBPVz",
                                      -330.f * Allen::Units::mm,
                                      "minimum z for the best primary vertex associated to the muon"};
  };
} // namespace low_pt_muon_line

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

namespace single_high_pt_muon_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct single_high_pt_muon_line_t : public SelectionAlgorithm,
                                      Parameters,
                                      OneTrackLine<single_high_pt_muon_line_t, Parameters> {

    struct DeviceProperties {
      float maxChi2Ndof;
      float singleMinPt;
      float singleMinP;
      float minZ;
      DeviceProperties(const single_high_pt_muon_line_t& algo, const Allen::Context&) :
        maxChi2Ndof(algo.m_maxChi2Ndof), singleMinPt(algo.m_singleMinPt), singleMinP(algo.m_singleMinP),
        minZ(algo.m_minZ)
      {}
    };
    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::BasicParticle>);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::BasicParticle>,
      unsigned,
      bool);

    using monitoring_types = std::tuple<pt_t, evtNo_t, runNo_t>;

  private:
    Allen::Property<float> m_maxChi2Ndof {this, "maxChi2Ndof", 100.f, "maxChi2Ndof description"};
    Allen::Property<float> m_singleMinPt {this, "singleMinPt", 6000.f / Allen::Units::MeV, "singleMinPt description"};
    Allen::Property<float> m_singleMinP {this, "singleMinP", 6000.f / Allen::Units::MeV, "singleMinP description"};
    Allen::Property<float> m_minZ {this, "minZ", -330.f * Allen::Units::mm, "minimum Z for the track state"};
  };
} // namespace single_high_pt_muon_line

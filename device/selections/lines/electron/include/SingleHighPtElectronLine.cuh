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

#include "ParticleTypes.cuh"
#include "AlgorithmTypes.cuh"
#include "OneTrackLine.cuh"

namespace single_high_pt_electron_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_track_isElectron_t, bool) dev_track_isElectron;
    DEVICE_INPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
    DEVICE_OUTPUT(pt_corrected_t, float) pt_corrected;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct single_high_pt_electron_line_t : public SelectionAlgorithm,
                                          Parameters,
                                          OneTrackLine<single_high_pt_electron_line_t, Parameters> {
    struct DeviceProperties {
      float maxChi2Ndof;
      float singleMinPt;
      float minZ;
      DeviceProperties(const single_high_pt_electron_line_t& algo, const Allen::Context&) :
        maxChi2Ndof(algo.m_maxChi2Ndof), singleMinPt(algo.m_singleMinPt), minZ(algo.m_minZ)
      {}
    };

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::BasicParticle, const bool, const float>);

    __device__ static std::tuple<const Allen::Views::Physics::BasicParticle, const bool, const float>
    get_input(const Parameters&, const unsigned, const unsigned);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::BasicParticle, const bool, const float>,
      unsigned,
      bool);

    using monitoring_types = std::tuple<pt_corrected_t, evtNo_t, runNo_t>;

  private:
    Allen::Property<float> m_maxChi2Ndof {this, "maxChi2Ndof", 100.f, "maxChi2Ndof description"};
    Allen::Property<float> m_singleMinPt {this, "singleMinPt", 6000.f / Allen::Units::MeV, "singleMinPt description"};
    Allen::Property<float> m_minZ {this, "MinZ", -330.f * Allen::Units::mm, "Minimum track state z"};
  };
} // namespace single_high_pt_electron_line

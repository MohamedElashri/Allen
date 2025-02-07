/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
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

namespace SMOG2_single_muon_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    DEVICE_INPUT(dev_chi2muon_t, float) dev_chi2muon;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
  };

  struct SMOG2_single_muon_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    OneTrackLine<SMOG2_single_muon_line_t, Parameters> {

    struct DeviceProperties {
      float maxChi2Ndof;
      float MinPt;
      float MinP;
      float minBPVz;
      float maxBPVz;
      float maxChi2Corr;
      DeviceProperties(const SMOG2_single_muon_line_t& algo, const Allen::Context&) :
        maxChi2Ndof(algo.m_maxChi2Ndof), MinPt(algo.m_MinPt), MinP(algo.m_MinP), minBPVz(algo.m_minBPVz),
        maxBPVz(algo.m_maxBPVz), maxChi2Corr(algo.m_maxChi2Corr)
      {}
    };

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::BasicParticle, const float> input);

    __device__ std::tuple<const Allen::Views::Physics::BasicParticle, const float> static get_input(
      const Parameters& parameters,
      const unsigned event_number,
      const unsigned i);

  private:
    Allen::Property<float> m_maxChi2Ndof {this, "maxChi2Ndof", 100.f, "maxChi2Ndof description"};
    Allen::Property<float> m_MinPt {this, "MinPt", 600.f / Gaudi::Units::MeV, "Minimum PT"};
    Allen::Property<float> m_MinP {this, "MinP", 5000.f / Gaudi::Units::MeV, "Minimum P"};
    Allen::Property<float> m_minBPVz {this, "minBPVz", -541.f * Gaudi::Units::mm, "minimum z for the track BPV"};
    Allen::Property<float> m_maxBPVz {this, "maxBPVz", -341.f * Gaudi::Units::mm, "maximum z for the track BPV"};
    Allen::Property<float> m_maxChi2Corr {this, "maxChi2Corr", 1.8, "maximum Chi2Muon evaluation"};
  };
} // namespace SMOG2_single_muon_line

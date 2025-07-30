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
    DEVICE_INPUT(dev_muonidnn_t, float) dev_muonidnn;
    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(ipchi2_t, float) ipchi2;
    DEVICE_OUTPUT(muonchi2_t, float) muonchi2;
    DEVICE_OUTPUT(muon_nn_t, float) muon_nn;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
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
      float minMuonNN;
      bool useNN;
      DeviceProperties(const SMOG2_single_muon_line_t& algo, const Allen::Context&) :
        maxChi2Ndof(algo.m_maxChi2Ndof), MinPt(algo.m_MinPt), MinP(algo.m_MinP), minBPVz(algo.m_minBPVz),
        maxBPVz(algo.m_maxBPVz), maxChi2Corr(algo.m_maxChi2Corr), minMuonNN(algo.m_minMuonNN), useNN(algo.m_useNN)
      {}
    };

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned> input);

    __device__ std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned> static get_input(
      const Parameters& parameters,
      const unsigned event_number,
      const unsigned i);
    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned>,
      unsigned,
      bool);

    using monitoring_types = std::tuple<pt_t, ipchi2_t, muonchi2_t, muon_nn_t, evtNo_t, runNo_t>;

  private:
    Allen::Property<float> m_maxChi2Ndof {this, "maxChi2Ndof", 100.f, "maxChi2Ndof description"};
    Allen::Property<float> m_MinPt {this, "MinPt", 600.f / Allen::Units::MeV, "Minimum PT"};
    Allen::Property<float> m_MinP {this, "MinP", 5000.f / Allen::Units::MeV, "Minimum P"};
    Allen::Property<float> m_minBPVz {this, "minBPVz", -537.5f * Allen::Units::mm, "minimum z for the track BPV"};
    Allen::Property<float> m_maxBPVz {this, "maxBPVz", -337.5f * Allen::Units::mm, "maximum z for the track BPV"};
    Allen::Property<float> m_maxChi2Corr {this, "maxChi2Corr", 1.8, "maximum Chi2Muon evaluation"};
    Allen::Property<float> m_minMuonNN {this, "minMuonNN", 0.15, "minimum NN evaluation"};
    Allen::Property<bool> m_useNN {this, "useNN", true, "Use NN instead of Chi2Corr"};
  };
} // namespace SMOG2_single_muon_line

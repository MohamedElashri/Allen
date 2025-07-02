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

namespace track_muon_mva_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;
    DEVICE_INPUT(dev_chi2muon_t, float) dev_chi2muon;
    DEVICE_INPUT(dev_muonidnn_t, float) dev_muonidnn;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(ipchi2_t, float) ipchi2;
    DEVICE_OUTPUT(muonchi2_t, float) muonchi2;
    DEVICE_OUTPUT(muon_nn_t, float) muon_nn;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct track_muon_mva_line_t : public SelectionAlgorithm,
                                 Parameters,
                                 OneTrackLine<track_muon_mva_line_t, Parameters> {
    struct DeviceProperties {
      float maxChi2Ndof;
      float minPt;
      float maxPt;
      float minIPChi2;
      float param1;
      float param2;
      float param3;
      float alpha;
      float minBPVz;
      float maxChi2Muon;
      float minMuonNN;
      bool useNN;
      DeviceProperties(const track_muon_mva_line_t& algo, const Allen::Context&) :
        maxChi2Ndof(algo.m_maxChi2Ndof), minPt(algo.m_minPt), maxPt(algo.m_maxPt), minIPChi2(algo.m_minIPChi2),
        param1(algo.m_param1), param2(algo.m_param2), param3(algo.m_param3), alpha(algo.m_alpha),
        minBPVz(algo.m_minBPVz), maxChi2Muon(algo.m_maxChi2Muon), minMuonNN(algo.m_minMuonNN), useNN(algo.m_useNN)
      {}
    };

    __device__ std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned> static get_input(
      const Parameters&,
      const unsigned,
      const unsigned);
    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned>);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned>,
      unsigned,
      bool);

    using monitoring_types = std::tuple<pt_t, ipchi2_t, muonchi2_t, muon_nn_t, evtNo_t, runNo_t>;

  private:
    Allen::Property<float> m_maxChi2Ndof {this, "maxChi2Ndof", 100.0f, "maxChi2Ndof description"};
    Allen::Property<float> m_minPt {this, "minPt", 2000.0f * Allen::Units::MeV, "minPt description"};
    Allen::Property<float> m_maxPt {this, "maxPt", 26000.0f * Allen::Units::MeV, "maxPt description"};
    Allen::Property<float> m_minIPChi2 {this, "minIPChi2", 7.4f, "minIPChi2 description"};
    Allen::Property<float> m_param1 {this, "param1", 1.0f, "param1 description"};
    Allen::Property<float> m_param2 {this, "param2", 2.0f, "param2 description"};
    Allen::Property<float> m_param3 {this, "param3", 1.248f, "param3 description"};
    Allen::Property<float> m_alpha {this, "alpha", 0.f, "alpha description"};
    Allen::Property<float> m_minBPVz {this,
                                      "minBPVz",
                                      -330.f * Allen::Units::mm,
                                      "minimum z for the best primary vertex associated to the muon"};
    Allen::Property<float> m_maxChi2Muon {this, "maxChi2Muon", 1.8, "maximum Chi2Muon evaluation"};
    Allen::Property<float> m_minMuonNN {this, "minMuonNN", 0.15, "minimum NN evaluation"};
    Allen::Property<bool> m_useNN {this, "useNN", true, "Use NN instead of Chi2Corr"};
  };
} // namespace track_muon_mva_line

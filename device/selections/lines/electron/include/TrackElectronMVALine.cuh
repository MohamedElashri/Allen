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

namespace track_electron_mva_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_track_isElectron_t, bool) dev_track_isElectron;
    DEVICE_INPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
    DEVICE_INPUT(dev_electronidnn_t, float) dev_electronidnn;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(electron_nn_t, float) electron_nn;
    DEVICE_OUTPUT(pt_corrected_t, float) pt_corrected;
    DEVICE_OUTPUT(ipchi2_t, float) ipchi2;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct track_electron_mva_line_t : public SelectionAlgorithm,
                                     Parameters,
                                     OneTrackLine<track_electron_mva_line_t, Parameters> {

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
      float minElectronNN;
      bool useNN;
      DeviceProperties(const track_electron_mva_line_t& algo, const Allen::Context&) :
        maxChi2Ndof(algo.m_maxChi2Ndof), minPt(algo.m_minPt), maxPt(algo.m_maxPt), minIPChi2(algo.m_minIPChi2),
        param1(algo.m_param1), param2(algo.m_param2), param3(algo.m_param3), alpha(algo.m_alpha),
        minBPVz(algo.m_minBPVz), minElectronNN(algo.m_minElectronNN), useNN(algo.m_useNN)
      {}
    };

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

    using monitoring_types = std::tuple<pt_t, electron_nn_t, pt_corrected_t, ipchi2_t, evtNo_t, runNo_t>;

    __device__ static std::tuple<const Allen::Views::Physics::BasicParticle, const unsigned>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

  private:
    Allen::Property<float> m_maxChi2Ndof {this, "maxChi2Ndof", 2.5f, "maxChi2Ndof description"};
    Allen::Property<float> m_minPt {this, "minPt", 1.f * Allen::Units::GeV, "minPt description"};
    Allen::Property<float> m_maxPt {this, "maxPt", 26.f * Allen::Units::GeV, "maxPt description"};
    Allen::Property<float> m_minIPChi2 {this, "minIPChi2", 3.f, "minIPChi2 description"};
    Allen::Property<float> m_param1 {this, "param1", 1.f * Allen::Units::GeV* Allen::Units::GeV, "param1 description"};
    Allen::Property<float> m_param2 {this, "param2", 1.f * Allen::Units::GeV, "param2 description"};
    Allen::Property<float> m_param3 {this, "param3", 1.248f, "param3 description"};
    Allen::Property<float> m_alpha {this, "alpha", 0.f, "alpha description"};
    Allen::Property<float> m_minBPVz {this,
                                      "min_BPVz",
                                      -330.f * Allen::Units::mm,
                                      "Minimum z for the associated best primary vertex"};
    Allen::Property<float> m_minElectronNN {this, "minElectronNN", 0.1, "min NN evaluation"};
    Allen::Property<bool> m_useNN {this, "useNN", true, "useNN"};
  };
} // namespace track_electron_mva_line

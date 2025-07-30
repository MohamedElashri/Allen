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
#include "CompositeParticleLine.cuh"

#include "AllenMonitoring.h"

namespace di_muon_mass_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    DEVICE_INPUT(dev_chi2muon_t, float) dev_chi2muon;
    DEVICE_INPUT(dev_muonidnn_t, float) dev_muonidnn;
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

  struct di_muon_mass_line_t : public SelectionAlgorithm,
                               Parameters,
                               CompositeParticleLine<di_muon_mass_line_t, Parameters> {
    struct DeviceProperties {
      float minHighMassTrackPt;
      float minHighMassTrackP;
      float minMass;
      float maxDoca;
      float maxVertexChi2;
      float minIPChi2;
      float minZ;
      float maxChi2Muon;
      float minMuonNN;
      bool oppositeSign;
      bool useNN;
      bool vetoSharedHits;
      Allen::Monitoring::Histogram<>::DeviceType histogram_Jpsi_mass;
      DeviceProperties(const di_muon_mass_line_t& algo, const Allen::Context& ctx) :
        minHighMassTrackPt(algo.m_minHighMassTrackPt), minHighMassTrackP(algo.m_minHighMassTrackP),
        minMass(algo.m_minMass), maxDoca(algo.m_maxDoca), maxVertexChi2(algo.m_maxVertexChi2),
        minIPChi2(algo.m_minIPChi2), minZ(algo.m_minZ), maxChi2Muon(algo.m_maxChi2Muon), minMuonNN(algo.m_minMuonNN),
        oppositeSign(algo.m_opposite_sign), useNN(algo.m_useNN), vetoSharedHits(algo.m_vetoSharedHits),
        histogram_Jpsi_mass(algo.m_histogram_Jpsi_mass.data(ctx))
      {}
    };
    __device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> static get_input(
      const Parameters& parameters,
      const unsigned event_number,
      const unsigned i);
    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>);
    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceProperties& properties,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
      unsigned index,
      bool sel);
    __device__ static bool fill_tuples(
      const Parameters& parameters,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<pt_t, ipchi2_t, muonchi2_t, muon_nn_t, evtNo_t, runNo_t>;

  private:
    Allen::Property<float> m_minHighMassTrackPt {this,
                                                 "minHighMassTrackPt",
                                                 300.f / Allen::Units::MeV,
                                                 "minHighMassTrackPt description"};
    Allen::Property<float> m_minHighMassTrackP {this,
                                                "minHighMassTrackP",
                                                6000.f / Allen::Units::MeV,
                                                "minHighMassTrackP description"};
    Allen::Property<float> m_minMass {this, "minMass", 2700.f / Allen::Units::MeV, "minMass description"};
    Allen::Property<float> m_maxDoca {this, "maxDoca", 0.2f, "maxDoca description"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 25.0f, "maxVertexChi2 description"};
    Allen::Property<float> m_minIPChi2 {this, "minIPChi2", 0.f, "minIPChi2 description"};
    Allen::Property<float> m_minZ {this, "minZ", -330.f * Allen::Units::mm, "minimum vertex z coordinate"};
    Allen::Property<float> m_maxChi2Muon {this, "maxChi2Muon", 1.8, "maximum Chi2Muon evaluation"};
    Allen::Property<float> m_minMuonNN {this, "minMuonNN", 0.1, "min NN evaluation"};
    Allen::Property<bool> m_opposite_sign {this, "OppositeSign", true, "Selects opposite sign dimuon combinations"};
    Allen::Property<bool> m_useNN {this, "useNN", false, "useNN"};
    Allen::Property<bool> m_vetoSharedHits {this, "vetoSharedHits", false, "vetoSharedHits"};

    Allen::Monitoring::Histogram<> m_histogram_Jpsi_mass {this, "Jpsi_mass", "m(J/Psi)", {300u, 2896.f, 3296.f}};
  };
} // namespace di_muon_mass_line

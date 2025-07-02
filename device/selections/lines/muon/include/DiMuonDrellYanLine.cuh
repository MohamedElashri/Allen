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
#include "CompositeParticleLine.cuh"
#include "ROOTService.h"

#include "AllenMonitoring.h"

namespace di_muon_drell_yan_line {
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

    DEVICE_OUTPUT(mass_t, float) mass;
    DEVICE_OUTPUT(chi2muon_t, float) chi2muon;
    DEVICE_OUTPUT(muon_nn_t, float) muon_nn;
    DEVICE_OUTPUT(transverse_momentum_t, float) transverse_momentum;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct di_muon_drell_yan_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    CompositeParticleLine<di_muon_drell_yan_line_t, Parameters> {
    struct DeviceProperties {
      float minTrackP;
      float minTrackPt;
      float maxTrackEta;
      float minMass;
      float maxMass;
      float maxDoca;
      float maxVertexChi2;
      bool oppositeSign;
      float minZ;
      float maxChi2Muon;
      float minMuonNN;
      bool useNN;
      Allen::Monitoring::Histogram<>::DeviceType histogram_Z_mass;
      DeviceProperties(const di_muon_drell_yan_line_t& algo, const Allen::Context& ctx) :
        minTrackP(algo.m_minTrackP), minTrackPt(algo.m_minTrackPt), maxTrackEta(algo.m_maxTrackEta),
        minMass(algo.m_minMass), maxMass(algo.m_maxMass), maxDoca(algo.m_maxDoca), maxVertexChi2(algo.m_maxVertexChi2),
        oppositeSign(algo.m_opposite_sign), minZ(algo.m_minZ), maxChi2Muon(algo.m_maxChi2Muon),
        minMuonNN(algo.m_minMuonNN), useNN(algo.m_useNN), histogram_Z_mass(algo.m_histogram_Z_mass.data(ctx))
      {}
    };

    __device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> static get_input(
      const Parameters&,
      const unsigned,
      const unsigned);

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>);

    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>,
      unsigned,
      bool);
    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>,
      unsigned,
      bool);

    using monitoring_types = std::tuple<transverse_momentum_t, chi2muon_t, muon_nn_t, mass_t, evtNo_t, runNo_t>;

  private:
    Allen::Property<float> m_minTrackP {this,
                                        "minTrackP",
                                        15.f * Allen::Units::GeV,
                                        "Minimal momentum for both daughters "};
    Allen::Property<float> m_minTrackPt {this, "minTrackPt", 1.2f * Allen::Units::GeV, "Minimal pT for both daughters"};
    Allen::Property<float> m_maxTrackEta {this, "maxTrackEta", 4.9, "Maximal ETA for both daughters"};
    Allen::Property<float> m_minMass {this, "minMass", 5.f * Allen::Units::GeV, "Min mass of the composite"};
    Allen::Property<float> m_maxMass {this, "maxMass", 400.f * Allen::Units::GeV, "Max mass of the composite"};
    Allen::Property<float> m_maxDoca {this, "maxDoca", .15f * Allen::Units::mm, "maxDoca description"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 20.f, "maxVertexChi2 description"};
    Allen::Property<bool> m_opposite_sign {this, "OppositeSign", true, "Selects opposite sign dimuon combinations"};
    Allen::Property<float> m_minZ {this, "minZ", -330.f * Allen::Units::mm, "minimum dimuon vertex z coordinate"};
    Allen::Property<float> m_maxChi2Muon {this, "maxChi2Muon", 2.2, "maximum muonID chi2corr value"};
    Allen::Property<float> m_minMuonNN {this, "minMuonNN", 0.15, "minimum NN evaluation"};
    Allen::Property<bool> m_useNN {this, "useNN", true, "Use NN instead of Chi2Corr"};

    Allen::Monitoring::Histogram<> m_histogram_Z_mass {this, "Z_mass", "m(mu+mu-)", {100u, 60000.f, 120000.f}};
  };
} // namespace di_muon_drell_yan_line

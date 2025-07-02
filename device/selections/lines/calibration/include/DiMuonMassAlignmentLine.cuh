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

namespace di_muon_mass_alignment_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    DEVICE_INPUT(dev_chi2muon_t, float) dev_chi2muon;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
  };

  struct di_muon_mass_alignment_line_t : public SelectionAlgorithm,
                                         Parameters,
                                         CompositeParticleLine<di_muon_mass_alignment_line_t, Parameters> {

    struct DeviceProperties {
      float minHighMassTrackPt;
      float minHighMassTrackP;
      float minMass;
      float maxMass;
      float maxDoca;
      float maxVertexChi2;
      float minIP;
      float minFdChi2;
      float minZ;
      float minEta;
      float maxEta;
      float minDira;
      float minComboPt;
      float maxChi2Muon;
      int diMuonCharge;

      DeviceProperties(const di_muon_mass_alignment_line_t& algo, const Allen::Context&) :
        minHighMassTrackPt(algo.m_minHighMassTrackPt), minHighMassTrackP(algo.m_minHighMassTrackP),
        minMass(algo.m_minMass), maxMass(algo.m_maxMass), maxDoca(algo.m_maxDoca), maxVertexChi2(algo.m_maxVertexChi2),
        minIP(algo.m_minIP), minFdChi2(algo.m_minFdChi2), minZ(algo.m_minZ), minEta(algo.m_minEta),
        maxEta(algo.m_maxEta), minDira(algo.m_minDira), minComboPt(algo.m_minComboPt), maxChi2Muon(algo.m_maxChi2Muon),
        diMuonCharge(algo.m_dimuon_charge)
      {}
    };

    __device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const float> static get_input(
      const Parameters& parameters,
      const unsigned event_number,
      const unsigned i);

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>);

  private:
    Allen::Property<float> m_minHighMassTrackPt {this,
                                                 "minHighMassTrackPt",
                                                 1000.f / Allen::Units::MeV,
                                                 "minHighMassTrackPt description"};
    Allen::Property<float> m_minHighMassTrackP {this,
                                                "minHighMassTrackP",
                                                6000.f / Allen::Units::MeV,
                                                "minHighMassTrackP description"};
    Allen::Property<float> m_minMass {this, "minMass", 2996.f / Allen::Units::MeV, "minMass description"};
    Allen::Property<float> m_maxMass {this, "maxMass", 3196.f / Allen::Units::MeV, "maxMass description"};
    Allen::Property<float> m_maxDoca {this, "maxDoca", 0.2f, "maxDoca description"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 10.0f, "maxVertexChi2 description"};
    Allen::Property<float> m_minIP {this, "minIP", 0.07f * Allen::Units::mm, "minIP description"};
    Allen::Property<float> m_minFdChi2 {this, "minFdChi2", 5.f, "minFdChi2 description"};
    Allen::Property<float> m_minZ {this, "minZ", -330.f * Allen::Units::mm, "minimum vertex z coordinate"};
    Allen::Property<float> m_minEta {this, "minEta", 2.0f, "minEta description"};
    Allen::Property<float> m_maxEta {this, "maxEta", 5.0f, "maxEta description"};
    Allen::Property<float> m_minDira {this, "minDira", 0.9995f, "minimum value of cos(theta_dira)"};
    Allen::Property<float> m_minComboPt {this, "minComboPt", 2000.0f * Allen::Units::MeV, "minComboPt description"};
    Allen::Property<float> m_maxChi2Muon {this, "maxChi2Muon", 1.8, "max Chi2Muon evaluation"};
    Allen::Property<int> m_dimuon_charge {this, "DiMuonCharge", 0, "Charge of the dimuon combination"};
  };
} // namespace di_muon_mass_alignment_line

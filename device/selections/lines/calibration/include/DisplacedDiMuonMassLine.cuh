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

namespace displaced_di_muon_mass_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
  };

  struct displaced_di_muon_mass_line_t : public SelectionAlgorithm,
                                         Parameters,
                                         CompositeParticleLine<displaced_di_muon_mass_line_t, Parameters> {
    struct DeviceProperties {
      float minMass;
      float minDispTrackPt;
      float maxVertexChi2;
      float dispMinIPChi2;
      float dispMinEta;
      float dispMaxEta;
      float minZ;
      int diMuonCharge;

      DeviceProperties(const displaced_di_muon_mass_line_t& algo, const Allen::Context&) :
        minMass(algo.m_minMass), minDispTrackPt(algo.m_minDispTrackPt), maxVertexChi2(algo.m_maxVertexChi2),
        dispMinIPChi2(algo.m_dispMinIPChi2), dispMinEta(algo.m_dispMinEta), dispMaxEta(algo.m_dispMaxEta),
        minZ(algo.m_minZ), diMuonCharge(algo.m_dimuon_charge)
      {}
    };
    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

  private:
    // Dimuon mass cut
    Allen::Property<float> m_minMass {this, "minMass", 2700.f / Allen::Units::MeV, "minMass description"};
    // Dimuon track pt.
    Allen::Property<float> m_minDispTrackPt {this,
                                             "minDispTrackPt",
                                             500.f / Allen::Units::MeV,
                                             "minDispTrackPt description"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 6.f, "maxVertexChi2 description"};
    // Displaced dimuon selections.
    Allen::Property<float> m_dispMinIPChi2 {this, "dispMinIPChi2", 6.f, "dispMinIPChi2 description"};
    Allen::Property<float> m_dispMinEta {this, "dispMinEta", 2.f, "dispMinEta description"};
    Allen::Property<float> m_dispMaxEta {this, "dispMaxEta", 5.f, "dispMaxEta description"};
    Allen::Property<float> m_minZ {this, "minZ", -330.f * Allen::Units::mm, "minimum vertex z dimuon coordinate"};
    Allen::Property<int> m_dimuon_charge {this, "DiMuonCharge", 0, "Charge of the dimuon combination"};
  };
} // namespace displaced_di_muon_mass_line

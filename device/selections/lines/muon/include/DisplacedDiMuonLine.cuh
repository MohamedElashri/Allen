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

namespace displaced_di_muon_line {
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

  struct displaced_di_muon_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    CompositeParticleLine<displaced_di_muon_line_t, Parameters> {
    struct DeviceProperties {
      float minDispTrackPt;
      float maxVertexChi2;
      float dispMinIPChi2;
      float dispMinEta;
      float dispMaxEta;
      float minZ;
      float maxChi2Muon;
      Allen::Monitoring::Histogram<>::DeviceType histogram_displaced_dimuon_mass;
      DeviceProperties(const displaced_di_muon_line_t& algo, const Allen::Context& ctx) :
        minDispTrackPt(algo.m_minDispTrackPt), maxVertexChi2(algo.m_maxVertexChi2), dispMinIPChi2(algo.m_dispMinIPChi2),
        dispMinEta(algo.m_dispMinEta), dispMaxEta(algo.m_dispMaxEta), minZ(algo.m_minZ),
        maxChi2Muon(algo.m_maxChi2Muon),
        histogram_displaced_dimuon_mass(algo.m_histogram_displaced_dimuon_mass.data(ctx))
      {}
    };
    __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);
    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>);
    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>,
      unsigned,
      bool);

  private:
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
    Allen::Property<float> m_maxChi2Muon {this, "maxChi2Muon", 1.8, "maximum Chi2Muon evaluation"};

    Allen::Monitoring::Histogram<> m_histogram_displaced_dimuon_mass {this,
                                                                      "displaced_dimuon_mass",
                                                                      "m(displ)",
                                                                      {295u, 215.f, 7000.f}};
  };
} // namespace displaced_di_muon_line

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

namespace SMOG2_displaced_di_muon_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    DEVICE_INPUT(dev_chi2muon_t, float) dev_chi2muon;
    DEVICE_INPUT(dev_muonidnn_t, float) dev_muonidnn;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(ipchi2_t, float) ipchi2;
    DEVICE_OUTPUT(muonchi2_t, float) muonchi2;
    DEVICE_OUTPUT(muon_nn_t, float) muon_nn;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
  };

  struct SMOG2_displaced_di_muon_line_t : public SelectionAlgorithm,
                                          Parameters,
                                          CompositeParticleLine<SMOG2_displaced_di_muon_line_t, Parameters> {
    struct DeviceProperties {
      float minDispTrackPt;
      float maxVertexChi2;
      float minComboPt;
      float mass;
      float minZ;
      float maxChi2CorrMuon;
      float minPVZ;
      float maxPVZ;
      float minFDCHI2;
      float maxIP;
      float minMuonNN;
      bool useNN;

      Allen::Monitoring::Histogram<>::DeviceType histogram_displaced_dimuon_mass;
      DeviceProperties(const SMOG2_displaced_di_muon_line_t& algo, const Allen::Context& ctx) :
        minDispTrackPt(algo.m_minDispTrackPt), maxVertexChi2(algo.m_maxVertexChi2), minComboPt(algo.m_minComboPt),
        mass(algo.m_mass), minZ(algo.m_minZ), maxChi2CorrMuon(algo.m_maxChi2CorrMuon), minPVZ(algo.m_minPVZ),
        maxPVZ(algo.m_maxPVZ), minFDCHI2(algo.m_minFDCHI2), maxIP(algo.m_maxIP), minMuonNN(algo.m_minMuonNN),
        useNN(algo.m_useNN), histogram_displaced_dimuon_mass(algo.m_histogram_displaced_dimuon_mass.data(ctx))
      {}
    };
    __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);
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
    // Dimuon track pt.
    Allen::Property<float> m_minDispTrackPt {this,
                                             "minDispTrackPt",
                                             250.f * Allen::Units::MeV,
                                             "minDispTrackPt description"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 30.f, "maxVertexChi2 description"};
    Allen::Property<float> m_minComboPt {this, "minComboPt", 1.f * Allen::Units::GeV, "minComboPt description"};
    // Displaced dimuon selections.
    Allen::Property<float> m_mass {this, "mass", 500.f * Allen::Units::MeV, "mass of dimuon"};
    Allen::Property<float> m_minZ {this, "minZ", -537.5f * Allen::Units::mm, "minimum vertex z dimuon coordinate"};
    Allen::Property<float> m_maxChi2CorrMuon {this, "maxChi2CorrMuon", 2.5, "maximum Chi2CorrMuon evaluation"};
    Allen::Property<float> m_minPVZ {this, "minPVZ", -537.5f * Allen::Units::mm, "minimum PV z coordinate"};
    Allen::Property<float> m_maxPVZ {this, "maxPVZ", -337.5f * Allen::Units::mm, "maximum PV z coordinate"};
    Allen::Property<float> m_minFDCHI2 {this, "minFDCHI2", 15.f, "chi2 of pv and endvertex"};
    Allen::Property<float> m_maxIP {this, "maxIP", 1.f * Allen::Units::mm, "mother IP"};
    Allen::Property<float> m_minMuonNN {this, "minMuonNN", 0.1, "min NN evaluation"};
    Allen::Property<float> m_useNN {this, "useNN", true, "useNN"};

    Allen::Monitoring::Histogram<> m_histogram_displaced_dimuon_mass {this,
                                                                      "displaced_dimuon_mass",
                                                                      "m(displ)",
                                                                      {295u, 215.f, 7000.f}};
  };
} // namespace SMOG2_displaced_di_muon_line

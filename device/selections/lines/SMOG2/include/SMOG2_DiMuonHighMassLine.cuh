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
#include "AllenMonitoring.h"

namespace SMOG2_dimuon_highmass_line {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    DEVICE_INPUT(dev_chi2muon_t, float) dev_chi2muon;

    DEVICE_OUTPUT(mass_t, float) mass;
    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(pvz_t, float) pvz;
    DEVICE_OUTPUT(svz_t, float) svz;
    DEVICE_OUTPUT(maxchi2corr_t, float) maxchi2corr;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
  };

  struct SMOG2_dimuon_highmass_line_t : public SelectionAlgorithm,
                                        Parameters,
                                        CompositeParticleLine<SMOG2_dimuon_highmass_line_t, Parameters> {
    struct DeviceProperties {
      float maxTrackChi2Ndf;
      float minTrackPt;
      float minTrackP;
      float minMass;
      int HighMassCombCharge;
      float maxDoca;
      float maxVertexChi2;
      float minZ;
      float maxZ;
      float maxChi2Corr;

      Allen::Monitoring::Histogram<>::DeviceType histogram_smogdimuon_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogdimuon_pt;
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogdimuon_pvz;
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogdimuon_svz;

      DeviceProperties(const SMOG2_dimuon_highmass_line_t& algo, const Allen::Context& ctx) :
        maxTrackChi2Ndf(algo.m_maxTrackChi2Ndf), minTrackPt(algo.m_minTrackPt), minTrackP(algo.m_minTrackP),
        minMass(algo.m_minMass), HighMassCombCharge(algo.m_CombCharge), maxDoca(algo.m_maxDoca),
        maxVertexChi2(algo.m_maxVertexChi2), minZ(algo.m_minZ), maxZ(algo.m_maxZ), maxChi2Corr(algo.m_maxChi2Corr),
        histogram_smogdimuon_mass(algo.m_histogram_smogdimuon_mass.data(ctx)),
        histogram_smogdimuon_pt(algo.m_histogram_smogdimuon_pt.data(ctx)),
        histogram_smogdimuon_pvz(algo.m_histogram_smogdimuon_pvz.data(ctx)),
        histogram_smogdimuon_svz(algo.m_histogram_smogdimuon_svz.data(ctx))
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
    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceProperties& properties,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
      unsigned index,
      bool sel);
    __device__ static bool fill_tuples(
      const Parameters& parameters,
      const DeviceProperties& properties,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<mass_t, svz_t, pvz_t, pt_t, maxchi2corr_t>;

  private:
    Allen::Property<float> m_maxTrackChi2Ndf {this, "maxTrackChi2Ndf", 5.f, "max track fit Chi2ndf"};
    Allen::Property<float> m_minTrackPt {this,
                                         "minTrackPt",
                                         500.f * Allen::Units::MeV,
                                         "min track transverse momentum"};
    Allen::Property<float> m_minTrackP {this, "minTrackP", 3000.f * Allen::Units::MeV, "min track momentum"};
    Allen::Property<float> m_minMass {this,
                                      "minMass",
                                      2700.f * Allen::Units::MeV,
                                      "min invariant mass for track combination"};
    Allen::Property<int> m_CombCharge {this, "HighMassCombCharge", 0, "Charge of the combination"};
    Allen::Property<float> m_maxDoca {this, "maxDoca", 0.5f * Allen::Units::mm, "max distance of closest approach"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 25.0f, "Max vertex chi2"};
    Allen::Property<float> m_minZ {this, "minZ", -537.5f * Allen::Units::mm, "minimum vertex z"};
    Allen::Property<float> m_maxZ {this, "maxZ", -337.5f * Allen::Units::mm, "maximum vertex z"};
    Allen::Property<float> m_maxChi2Corr {this, "maxChi2Corr", 1.8, "maximum Chi2Muon evaluation"};

    Allen::Monitoring::Histogram<> m_histogram_smogdimuon_mass {this,
                                                                "SMOG2_dimuon_mass",
                                                                "m(#mu#mu)",
                                                                {100u, 2700.f, 4000.f}};
    Allen::Monitoring::Histogram<> m_histogram_smogdimuon_pt {this, "SMOG2_dimuon_pt", "pT", {100u, 100.f, 8000.f}};
    Allen::Monitoring::Histogram<> m_histogram_smogdimuon_svz {this,
                                                               "smogdimuon_svz",
                                                               "SV_z(smogdimuon)",
                                                               {100u, -550.f, -300.f}};
    Allen::Monitoring::Histogram<> m_histogram_smogdimuon_pvz {this,
                                                               "smogdimuon_Pvz",
                                                               "PV_z (smogdimuon)",
                                                               {100u, -550.f, -300.f}};
  };
} // namespace SMOG2_dimuon_highmass_line

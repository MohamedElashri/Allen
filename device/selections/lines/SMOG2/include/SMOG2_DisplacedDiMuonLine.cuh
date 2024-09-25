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
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minDispTrackPt_t, "minDispTrackPt", "minDispTrackPt description", float) minDispTrackPt;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "maxVertexChi2 description", float) maxVertexChi2;
    PROPERTY(minComboPt_t, "minComboPt", "minComboPt description", float) minComboPt;
    PROPERTY(mass_t, "mass", "mass of dimuon", float) mass;
    PROPERTY(minZ_t, "minZ", "minimum vertex z dimuon coordinate", float) minZ;
    PROPERTY(maxChi2Muon_t, "maxChi2CorrMuon", "minimum Chi2CorrMuon evaluation", float) maxChi2CorrMuon;
    PROPERTY(minPVZ_t, "minPVZ", "minimum PV z coordinate", float) minPVZ;
    PROPERTY(maxPVZ_t, "maxPVZ", "maximum PV z coordinate", float) maxPVZ;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
    PROPERTY(minFDCHI2_t, "minFDCHI2", "chi2 of pv and endvertex", float) m_minFDCHI2;
    PROPERTY(maxIP_t, "maxIP", "mother IP", float) m_maxIP;
  };

  struct SMOG2_displaced_di_muon_line_t : public SelectionAlgorithm,
                                          Parameters,
                                          CompositeParticleLine<SMOG2_displaced_di_muon_line_t, Parameters> {
    struct DeviceAccumulators {
      Allen::Monitoring::Histogram<>::DeviceType histogram_displaced_dimuon_mass;
      DeviceAccumulators(const SMOG2_displaced_di_muon_line_t& algo, const Allen::Context& ctx) :
        histogram_displaced_dimuon_mass(algo.m_histogram_displaced_dimuon_mass.data(ctx))
      {}
    };
    __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);
    __device__ static bool select(
      const Parameters&,
      const DeviceAccumulators&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>);
    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceAccumulators& accumulators,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
      unsigned index,
      bool sel);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    // Dimuon track pt.
    Property<minDispTrackPt_t> m_minDispTrackPt {this, 250.f * Gaudi::Units::MeV};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 30.f};
    Property<minComboPt_t> m_minComboPt {this, 1.f * Gaudi::Units::GeV};
    // Displaced dimuon selections.
    Property<mass_t> m_mass {this, 500.f * Gaudi::Units::MeV};
    Property<minZ_t> m_minZ {this, -541.f * Gaudi::Units::mm};
    Property<maxChi2Muon_t> m_minChi2Muon {this, 2.5};
    Property<minPVZ_t> m_minPVZ {this, -541.f * Gaudi::Units::mm};
    Property<maxPVZ_t> m_maxPVZ {this, -341.f * Gaudi::Units::mm};
    Property<enable_monitoring_t> m_enable_monitoring {this, false};
    Property<minFDCHI2_t> m_minFDCHI2 {this, 15.f};
    Property<maxIP_t> m_maxIP {this, 1.f * Gaudi::Units::mm};

    Allen::Monitoring::Histogram<> m_histogram_displaced_dimuon_mass {this,
                                                                      "displaced_dimuon_mass",
                                                                      "m(displ)",
                                                                      {295u, 215.f, 7000.f}};
  };
} // namespace SMOG2_displaced_di_muon_line

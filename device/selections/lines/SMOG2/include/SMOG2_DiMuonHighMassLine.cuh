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

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(maxTrackChi2Ndf_t, "minTrackChi2Ndf", "max track fit Chi2ndf", float) maxTrackChi2Ndf;
    PROPERTY(minTrackPt_t, "minTrackPt", "min track transverse momentum", float) minTrackPt;
    PROPERTY(minTrackP_t, "minTrackP", "min track momentum", float) minTrackP;
    PROPERTY(minMass_t, "minMass", "min invariant mass for track combination", float) minMass;
    PROPERTY(maxDoca_t, "maxDoca", "max distance of closest approach", float) maxDoca;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "Max vertex chi2", float) maxVertexChi2;
    PROPERTY(minZ_t, "minZ", "minimum vertex z", float) minZ;
    PROPERTY(maxZ_t, "maxZ", "maximum vertex z", float) maxZ;
    PROPERTY(CombCharge_t, "HighMassCombCharge", "Charge of the combination", int) CombCharge;
    PROPERTY(maxChi2Corr_t, "maxChi2Corr", "maximum Chi2Muon evaluation", float) maxChi2Corr;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line tupling", bool) enable_tupling;
  };

  struct SMOG2_dimuon_highmass_line_t : public SelectionAlgorithm,
                                        Parameters,
                                        CompositeParticleLine<SMOG2_dimuon_highmass_line_t, Parameters> {
    struct DeviceAccumulators {
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogdimuon_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogdimuon_pt;
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogdimuon_pvz;
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogdimuon_svz;

      DeviceAccumulators(const SMOG2_dimuon_highmass_line_t& algo, const Allen::Context& ctx) :
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
      const DeviceAccumulators&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>);
    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceAccumulators& accumulators,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
      unsigned index,
      bool sel);
    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<mass_t, svz_t, pvz_t, pt_t, maxchi2corr_t>;

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<maxTrackChi2Ndf_t> m_maxTrackChi2Ndf {this, 3.f};
    Property<minTrackPt_t> m_minTrackPt {this, 500.f * Gaudi::Units::MeV};
    Property<minTrackP_t> m_minTrackP {this, 3000.f * Gaudi::Units::MeV};
    Property<minMass_t> m_minMass {this, 2700.f * Gaudi::Units::MeV};
    Property<CombCharge_t> m_CombCharge {this, 0};
    Property<maxDoca_t> m_maxDoca {this, 0.5f * Gaudi::Units::mm};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 25.0f};
    Property<minZ_t> m_minZ {this, -551.f * Gaudi::Units::mm};
    Property<maxZ_t> m_maxZ {this, -331.f * Gaudi::Units::mm};
    Property<maxChi2Corr_t> m_maxChi2Corr {this, 1.8};

    // Switch to create monitoring histograms
    Property<enable_monitoring_t> m_enable_monitoring {this, false};
    // Switch to create tuple
    Property<enable_tupling_t> m_enable_tupling {this, false};

    Allen::Monitoring::Histogram<> m_histogram_smogdimuon_mass {this,
                                                                "SMOG2_dimuon_mass",
                                                                "m(#mu#mu)",
                                                                {100u, 2700.f, 4000.f}};
    Allen::Monitoring::Histogram<> m_histogram_smogdimuon_pt {this, "SMOG2_dimuon_pt", "pT", {100u, 100.f, 8000.f}};
    Allen::Monitoring::Histogram<> m_histogram_smogdimuon_svz {this,
                                                               "smogdimuon_svz",
                                                               "SV_z(smogdimuon)",
                                                               {100u, -541.f, -300.f}};
    Allen::Monitoring::Histogram<> m_histogram_smogdimuon_pvz {this,
                                                               "smogdimuon_Pvz",
                                                               "PV_z (smogdimuon)",
                                                               {100u, -541.f, -341.f}};
  };
} // namespace SMOG2_dimuon_highmass_line

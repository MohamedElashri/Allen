/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
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
#include "MassDefinitions.h"

#include "AllenMonitoring.h"

namespace SMOG2_kstopipi_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(sv_masses_t, float) sv_masses;
    DEVICE_OUTPUT(svz_t, float) svz;
    DEVICE_OUTPUT(track1pt_t, float) track1pt;
    DEVICE_OUTPUT(track2pt_t, float) track2pt;
    DEVICE_OUTPUT(minipchi2_t, float) minipchi2;
    DEVICE_OUTPUT(ip_t, float) ip;

    DEVICE_OUTPUT(dev_histogram_smogks_mass_t, unsigned) dev_histogram_smogks_mass;
    DEVICE_OUTPUT(dev_histogram_smogks_svz_t, unsigned) dev_histogram_smogks_svz;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minIPChi2_t, "minIPChi2", "Minimum IPCHI2", float) minIPChi2;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "Maximum vertex Chi2", float) maxVertexChi2;
    PROPERTY(maxIP_t, "maxIP", "Maximum IP", float) maxIP;
    PROPERTY(minMass_t, "minMass", "Minimum invariant mass", float) minMass;
    PROPERTY(maxMass_t, "maxMass", "Maximum invariat mass", float) maxMass;
    PROPERTY(minPVZ_t, "minPVZ", "minimum PV z coordinate", float) minPVZ;
    PROPERTY(maxPVZ_t, "maxPVZ", "maximum PV z coordinate", float) maxPVZ;
    PROPERTY(CombCharge_t, "CombCharge", "Charge of the combination", int) CombCharge;
    PROPERTY(minTrackPt_t, "minTrackPt", "Minimum final-state particles Pt", float) minTrackPt;

    PROPERTY(histogram_smogks_mass_min_t, "histogram_smogks_mass_min", "minimum for smogks mass histogram", float)
    histogram_smogks_mass_min;
    PROPERTY(histogram_smogks_mass_max_t, "histogram_smogks_mass_max", "maximum for smogks mass histogram", float)
    histogram_smogks_mass_max;
    PROPERTY(
      histogram_smogks_mass_nbins_t,
      "histogram_smogks_mass_nbins",
      "nbins for smogks mass histogram",
      unsigned int)
    histogram_smogks_mass_nbins;
    PROPERTY(histogram_smogks_svz_min_t, "histogram_smogks_svz_min", "minimum for smogks svz histogram", float)
    histogram_smogks_svz_min;
    PROPERTY(histogram_smogks_svz_max_t, "histogram_smogks_svz_max", "maximum for smogks svz histogram", float)
    histogram_smogks_svz_max;
    PROPERTY(
      histogram_smogks_svz_nbins_t,
      "histogram_smogks_svz_nbins",
      "mbins for smogks mass histogram",
      unsigned int)
    histogram_smogks_svz_nbins;

    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line tupling", bool) enable_tupling;
  };

  struct SMOG2_kstopipi_line_t : public SelectionAlgorithm,
                                 Parameters,
                                 CompositeParticleLine<SMOG2_kstopipi_line_t, Parameters> {
    struct DeviceAccumulators {
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogks_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogks_svz;
      DeviceAccumulators(const SMOG2_kstopipi_line_t& algo, const Allen::Context& ctx) :
        histogram_smogks_mass(algo.m_histogram_smogks_mass.data(ctx)),
        histogram_smogks_svz(algo.m_histogram_smogks_svz.data(ctx))
      {}
    };
    using monitoring_types = std::tuple<sv_masses_t, svz_t, track1pt_t, track2pt_t, minipchi2_t, ip_t>;

    __device__ static bool
    select(const Parameters&, const DeviceAccumulators&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    void init();

    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceAccumulators& accumulators,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minIPChi2_t> m_minIPChi2 {this, 100.f};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 10.0f};
    Property<maxIP_t> m_maxIP {this, 0.3f * Gaudi::Units::mm};
    Property<minMass_t> m_minMass {this, 400.f * Gaudi::Units::MeV};
    Property<minTrackPt_t> m_minTrackPt {this, 200.f * Gaudi::Units::MeV};
    Property<maxMass_t> m_maxMass {this, 600.f * Gaudi::Units::MeV};
    Property<minPVZ_t> m_minPVZ {this, -541.f * Gaudi::Units::mm};
    Property<maxPVZ_t> m_maxPVZ {this, -341.f * Gaudi::Units::mm};
    Property<CombCharge_t> m_CombCharge {this, 0};

    Property<histogram_smogks_mass_min_t> m_histogramsmogksMassMin {this, 400.f};
    Property<histogram_smogks_mass_max_t> m_histogramsmogksMassMax {this, 600.f};
    Property<histogram_smogks_mass_nbins_t> m_histogramsmogksMassNBins {this, 100u};
    Property<histogram_smogks_svz_min_t> m_histogramsmogkssvzMin {this, -541.f};
    Property<histogram_smogks_svz_max_t> m_histogramsmogkssvzMax {this, 2700.f};
    Property<histogram_smogks_svz_nbins_t> m_histogramsmogkssvzNBins {this, 100u};
    // Switch to create monitoring tuple
    Property<enable_monitoring_t> m_enable_monitoring {this, false};
    Property<enable_tupling_t> m_enable_tupling {this, false};

    Allen::Monitoring::Histogram<> m_histogram_smogks_mass {this, "ks_mass", "M(Ks) [MeV]", {100u, 400.f, 600.f}};
    Allen::Monitoring::Histogram<> m_histogram_smogks_svz {this, "smogks_svz", "SV_z (Ks)", {100u, -541.f, 2700.f}};
  };
} // namespace SMOG2_kstopipi_line

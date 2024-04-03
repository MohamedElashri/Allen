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
#include "ROOTService.h"
#include "MassDefinitions.h"

#include "AllenMonitoring.h"

namespace kstopipi_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(sv_masses_t, float) sv_masses;
    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(mipchi2_t, float) mipchi2;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minIPChi2_t, "minIPChi2", "Minimum IPCHI2", float) minIPChi2;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "Maximum vertex Chi2", float) maxVertexChi2;
    PROPERTY(maxIP_t, "maxIP", "Maximum IP", float) maxIP;
    PROPERTY(minMass_t, "minMass", "Minimum invariant mass", float) minMass;
    PROPERTY(maxMass_t, "maxMass", "Maximum invariat mass", float) maxMass;
    PROPERTY(minZ_t, "minZ", "minimum vertex z coordinate", float) minZ;
    PROPERTY(OppositeSign_t, "OppositeSign", "Selects opposite sign dimuon combinations", bool) OppositeSign;
    PROPERTY(double_muon_misid_t, "double_muon_misid", "Selects dimuon combinations", bool) double_muon_misid;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
  };

  struct kstopipi_line_t : public SelectionAlgorithm, Parameters, CompositeParticleLine<kstopipi_line_t, Parameters> {
    struct DeviceAccumulators {
      Allen::Monitoring::Histogram<>::DeviceType histogram_ks_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_ks_pt;
      DeviceAccumulators(const kstopipi_line_t& algo, const Allen::Context& ctx) :
        histogram_ks_mass(algo.m_histogram_ks_mass.data(ctx)), histogram_ks_pt(algo.m_histogram_ks_pt.data(ctx))
      {}
    };

    using monitoring_types = std::tuple<sv_masses_t, pt_t, mipchi2_t>;

    __device__ static bool
    select(const Parameters&, const DeviceAccumulators&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceAccumulators& accumulators,
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
    Property<maxMass_t> m_maxMass {this, 600.f * Gaudi::Units::MeV};
    Property<minZ_t> m_minZ {this, -341.f * Gaudi::Units::mm};
    Property<OppositeSign_t> m_opposite_sign {this, true};
    Property<double_muon_misid_t> m_double_muon_misid {this, false};
    // Switch to create monitoring tuple
    Property<enable_monitoring_t> m_enable_monitoring {this, false};

    Allen::Monitoring::Histogram<> m_histogram_ks_mass {this, "ks_mass", "m(ks)", {100u, 400.f, 600.f}};
    Allen::Monitoring::Histogram<> m_histogram_ks_pt {this, "ks_pt", "pT(ks)", {100u, 0.f, 1e4f}};
  };
} // namespace kstopipi_line

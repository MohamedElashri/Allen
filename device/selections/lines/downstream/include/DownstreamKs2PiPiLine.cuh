/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
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
#include "CompositeParticleLineWithIndex.cuh"
#include "ROOTService.h"
#include "MassDefinitions.h"

#include "AllenMonitoring.h"

namespace downstream_kstopipi_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_downstream_mva_ks_t, float) dev_downstream_mva_ks;
    DEVICE_INPUT(dev_downstream_mva_detached_ks_t, float) dev_downstream_mva_detached_ks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(ks_mass_t, float) ks_mass;
    DEVICE_OUTPUT(ks_pt_t, float) ks_pt;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);

    // Line paramters
    PROPERTY(minMass_t, "minMass", "Minimum invariant mass", float) minMass;
    PROPERTY(maxMass_t, "maxMass", "Maximum invariat mass", float) maxMass;
    PROPERTY(mva_ks_threshold_t, "mva_ks_threshold", "MVA threshold for Kshort selection", float) mva_ks_threshold;
    PROPERTY(
      mva_detached_ks_threshold_t,
      "mva_detached_ks_threshold",
      "MVA threshold for detached kshort selection",
      float)
    mva_detached_ks_threshold;

    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
  };

  struct downstream_kstopipi_line_t : public SelectionAlgorithm,
                                      Parameters,
                                      CompositeParticleLineWithIndex<downstream_kstopipi_line_t, Parameters> {
    struct DeviceAccumulators {
      Allen::Monitoring::Histogram<>::DeviceType histogram_ks_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_ks_pt;
      DeviceAccumulators(const downstream_kstopipi_line_t& algo, const Allen::Context& ctx) :
        histogram_ks_mass(algo.m_histogram_ks_mass.data(ctx)), histogram_ks_pt(algo.m_histogram_ks_pt.data(ctx))
      {}
    };

    using monitoring_types = std::tuple<ks_mass_t, ks_pt_t>;

    __device__ static bool select(
      const Parameters&,
      const DeviceAccumulators&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>);

    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceAccumulators& accumulators,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
      unsigned index,
      bool sel);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};

    Property<minMass_t> m_minMass {this, (497.6f - 80.f) * Gaudi::Units::MeV};
    Property<maxMass_t> m_maxMass {this, (497.6f + 80.f) * Gaudi::Units::MeV};
    Property<mva_ks_threshold_t> m_mva_ks_threshold {this, 0.5f};
    Property<mva_detached_ks_threshold_t> m_mva_detached_ks_threshold {this, 0.5f};

    // Switch to create monitoring tuple
    Property<enable_monitoring_t> m_enable_monitoring {this, false};

    Allen::Monitoring::Histogram<> m_histogram_ks_mass {this, "ks_mass", "m(ks)", {100u, 400.f, 600.f}};
    Allen::Monitoring::Histogram<> m_histogram_ks_pt {this, "ks_pt", "pT(ks)", {100u, 0.f, 1e4f}};
  };
} // namespace downstream_kstopipi_line

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

namespace downstream_lambdatoppi_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_downstream_mva_l0_t, float) dev_downstream_mva_l0;
    DEVICE_INPUT(dev_downstream_mva_detached_l0_t, float) dev_downstream_mva_detached_l0;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(l0_mass_t, float) l0_mass;
    DEVICE_OUTPUT(l0_pt_t, float) l0_pt;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);

    // Line paramters
    PROPERTY(minMass_t, "minMass", "Minimum invariant mass", float) minMass;
    PROPERTY(maxMass_t, "maxMass", "Maximum invariat mass", float) maxMass;
    PROPERTY(mva_l0_threshold_t, "mva_l0_threshold", "MVA threshold for Lambda selection", float) mva_l0_threshold;
    PROPERTY(
      mva_detached_l0_threshold_t,
      "mva_detached_l0_threshold",
      "MVA threshold for detached Lambda selection",
      float)
    mva_detached_l0_threshold;

    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
  };

  struct downstream_lambdatoppi_line_t : public SelectionAlgorithm,
                                         Parameters,
                                         CompositeParticleLineWithIndex<downstream_lambdatoppi_line_t, Parameters> {
    struct DeviceAccumulators {
      Allen::Monitoring::Histogram<>::DeviceType histogram_l0_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_l0_pt;
      DeviceAccumulators(const downstream_lambdatoppi_line_t& algo, const Allen::Context& ctx) :
        histogram_l0_mass(algo.m_histogram_l0_mass.data(ctx)), histogram_l0_pt(algo.m_histogram_l0_pt.data(ctx))
      {}
    };

    using monitoring_types = std::tuple<l0_mass_t, l0_pt_t>;

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

    Property<minMass_t> m_minMass {this, (1115.7f - 30.f) * Gaudi::Units::MeV};
    Property<maxMass_t> m_maxMass {this, (1115.7f + 30.f) * Gaudi::Units::MeV};
    Property<mva_l0_threshold_t> m_mva_l0_threshold {this, 0.5f};
    Property<mva_detached_l0_threshold_t> m_mva_detached_l0_threshold {this, 0.5f};

    // Switch to create monitoring tuple
    Property<enable_monitoring_t> m_enable_monitoring {this, false};

    Allen::Monitoring::Histogram<> m_histogram_l0_mass {this,
                                                        "l0_mass",
                                                        "m(l0)",
                                                        {100u, (1115.7f - 30.f), (1115.7f + 30.f)}};
    Allen::Monitoring::Histogram<> m_histogram_l0_pt {this, "l0_pt", "pT(l0)", {100u, 0.f, 1e4f}};
  };
} // namespace downstream_lambdatoppi_line

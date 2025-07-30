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
    DEVICE_OUTPUT(mva_ks_detached_t, float) mva_ks_detached;
    DEVICE_OUTPUT(mva_ks_prompt_t, float) mva_ks_prompt;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct downstream_kstopipi_line_t : public SelectionAlgorithm,
                                      Parameters,
                                      CompositeParticleLineWithIndex<downstream_kstopipi_line_t, Parameters> {
    struct DeviceProperties {
      float minMass;
      float maxMass;
      float mva_ks_threshold;
      float mva_detached_ks_threshold;
      Allen::Monitoring::Histogram<>::DeviceType histogram_ks_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_ks_pt;
      DeviceProperties(const downstream_kstopipi_line_t& algo, const Allen::Context& ctx) :
        minMass(algo.m_minMass), maxMass(algo.m_maxMass), mva_ks_threshold(algo.m_mva_ks_threshold),
        mva_detached_ks_threshold(algo.m_mva_detached_ks_threshold),
        histogram_ks_mass(algo.m_histogram_ks_mass.data(ctx)), histogram_ks_pt(algo.m_histogram_ks_pt.data(ctx))
      {}
    };

    using monitoring_types = std::tuple<ks_mass_t, ks_pt_t, mva_ks_detached_t, mva_ks_prompt_t, evtNo_t, runNo_t>;

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>);

    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
      unsigned index,
      bool sel);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
      unsigned index,
      bool sel);

  private:
    Allen::Property<float> m_minMass {this, "minMass", (497.6f - 80.f) * Allen::Units::MeV, "Minimum invariant mass"};
    Allen::Property<float> m_maxMass {this, "maxMass", (497.6f + 80.f) * Allen::Units::MeV, "Maximum invariat mass"};
    Allen::Property<float> m_mva_ks_threshold {this, "mva_ks_threshold", 0.5f, "MVA threshold for Kshort selection"};
    Allen::Property<float> m_mva_detached_ks_threshold {this,
                                                        "mva_detached_ks_threshold",
                                                        0.5f,
                                                        "MVA threshold for detached kshort selection"};

    Allen::Monitoring::Histogram<> m_histogram_ks_mass {this, "ks_mass", "m(ks)", {100u, 400.f, 600.f}};
    Allen::Monitoring::Histogram<> m_histogram_ks_pt {this, "ks_pt", "pT(ks)", {100u, 0.f, 1e4f}};
  };
} // namespace downstream_kstopipi_line

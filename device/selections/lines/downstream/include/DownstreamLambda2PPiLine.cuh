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
    DEVICE_OUTPUT(mva_l0_detached_t, float) mva_l0_detached;
    DEVICE_OUTPUT(mva_l0_prompt_t, float) mva_l0_prompt;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct downstream_lambdatoppi_line_t : public SelectionAlgorithm,
                                         Parameters,
                                         CompositeParticleLineWithIndex<downstream_lambdatoppi_line_t, Parameters> {
    struct DeviceProperties {
      float minMass;
      float maxMass;
      float mva_l0_threshold;
      float mva_detached_l0_threshold;
      Allen::Monitoring::Histogram<>::DeviceType histogram_l0_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_l0_pt;
      DeviceProperties(const downstream_lambdatoppi_line_t& algo, const Allen::Context& ctx) :
        minMass(algo.m_minMass), maxMass(algo.m_maxMass), mva_l0_threshold(algo.m_mva_l0_threshold),
        mva_detached_l0_threshold(algo.m_mva_detached_l0_threshold),
        histogram_l0_mass(algo.m_histogram_l0_mass.data(ctx)), histogram_l0_pt(algo.m_histogram_l0_pt.data(ctx))
      {}
    };

    using monitoring_types = std::tuple<l0_mass_t, l0_pt_t, mva_l0_detached_t, mva_l0_prompt_t, evtNo_t, runNo_t>;

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
    Allen::Property<float> m_minMass {this, "minMass", (1115.7f - 30.f) * Allen::Units::MeV, "Minimum invariant mass"};
    Allen::Property<float> m_maxMass {this, "maxMass", (1115.7f + 30.f) * Allen::Units::MeV, "Maximum invariat mass"};
    Allen::Property<float> m_mva_l0_threshold {this, "mva_l0_threshold", 0.5f, "MVA threshold for Lambda selection"};
    Allen::Property<float> m_mva_detached_l0_threshold {this,
                                                        "mva_detached_l0_threshold",
                                                        0.5f,
                                                        "MVA threshold for detached Lambda selection"};

    Allen::Monitoring::Histogram<> m_histogram_l0_mass {this,
                                                        "l0_mass",
                                                        "m(l0)",
                                                        {100u, (1115.7f - 30.f), (1115.7f + 30.f)}};
    Allen::Monitoring::Histogram<> m_histogram_l0_pt {this, "l0_pt", "pT(l0)", {100u, 0.f, 1e4f}};
  };
} // namespace downstream_lambdatoppi_line

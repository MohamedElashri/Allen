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

namespace downstream_gammatoee_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(gamma_mass_t, float) gamma_mass;
    DEVICE_OUTPUT(gamma_pt_t, float) gamma_pt; // To be used in bandwidth division
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct downstream_gammatoee_line_t : public SelectionAlgorithm,
                                       Parameters,
                                       CompositeParticleLineWithIndex<downstream_gammatoee_line_t, Parameters> {
    struct DeviceProperties {
      float minMass;
      float maxMass;
      float minPt;
      float maxArmenterosY;
      Allen::Monitoring::Histogram<>::DeviceType histogram_gamma_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_gamma_pt;
      DeviceProperties(const downstream_gammatoee_line_t& algo, const Allen::Context& ctx) :
        minMass(algo.m_minMass), maxMass(algo.m_maxMass), minPt(algo.m_minPt), maxArmenterosY(algo.m_maxArmenterosY),
        histogram_gamma_mass(algo.m_histogram_gamma_mass.data(ctx)),
        histogram_gamma_pt(algo.m_histogram_gamma_pt.data(ctx))
      {}
    };

    using monitoring_types = std::tuple<gamma_mass_t, gamma_pt_t, evtNo_t, runNo_t>;

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
    Allen::Property<float> m_minMass {this, "minMass", (0.0f) * Allen::Units::MeV, "Minimum invariant mass"};
    Allen::Property<float> m_maxMass {this, "maxMass", (100.0f) * Allen::Units::MeV, "Maximum invariat mass"};
    Allen::Property<float> m_minPt {this, "minPt", (1000.0f) * Allen::Units::MeV, "Minimum pt"};
    Allen::Property<float> m_maxArmenterosY {this, "maxArmenterosY", (60.0f), "Upper limit on Armenteros y"};

    Allen::Monitoring::Histogram<> m_histogram_gamma_mass {this, "gamma_mass", "m(ee)", {100u, 0.0f, 100.0f}};
    Allen::Monitoring::Histogram<> m_histogram_gamma_pt {this, "gamma_pt", "pT(ee)", {100u, 0.0f, 1e4f}};
  };
} // namespace downstream_gammatoee_line

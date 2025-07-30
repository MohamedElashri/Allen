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

namespace diproton_highmass_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(pp_mass_t, float) pp_mass;
    DEVICE_OUTPUT(pp_pt_t, float) pp_pt;
    DEVICE_OUTPUT(pp_p_t, float) pp_p;
    DEVICE_OUTPUT(p_pt_t, float) p_pt;
    DEVICE_OUTPUT(p_p_t, float) p_p;
    DEVICE_OUTPUT(ptasym_t, float) ptasym;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct diproton_highmass_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    CompositeParticleLine<diproton_highmass_line_t, Parameters> {
    struct DeviceProperties {
      float minPT_p;
      float minP_p;
      float minPT_pp;
      float minP_pp;
      float maxVertexChi2;
      float minMass;
      float maxMass;
      float maxPtAsym;
      float maxGhostProb;
      bool oppositeSign;
      Allen::Monitoring::Histogram<>::DeviceType histogram_pp_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_pp_pt;
      Allen::Monitoring::Histogram<>::DeviceType histogram_pp_p;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p_pt;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p_p;
      Allen::Monitoring::Histogram<>::DeviceType histogram_track1_ghost_prob;
      Allen::Monitoring::Histogram<>::DeviceType histogram_track2_ghost_prob;
      DeviceProperties(const diproton_highmass_line_t& algo, const Allen::Context& ctx) :
        minPT_p(algo.m_minPT_p), minP_p(algo.m_minP_p), minPT_pp(algo.m_minPT_pp), minP_pp(algo.m_minP_pp),
        maxVertexChi2(algo.m_maxVertexChi2), minMass(algo.m_minMass), maxMass(algo.m_maxMass),
        maxPtAsym(algo.m_maxPtAsym), maxGhostProb(algo.m_maxGhostProb), oppositeSign(algo.m_opposite_sign.value()),
        histogram_pp_mass(algo.m_histogram_pp_mass.data(ctx)), histogram_pp_pt(algo.m_histogram_pp_pt.data(ctx)),
        histogram_pp_p(algo.m_histogram_pp_p.data(ctx)), histogram_p_pt(algo.m_histogram_p_pt.data(ctx)),
        histogram_p_p(algo.m_histogram_p_p.data(ctx)),
        histogram_track1_ghost_prob(algo.m_histogram_track1_ghost_prob.data(ctx)),
        histogram_track2_ghost_prob(algo.m_histogram_track2_ghost_prob.data(ctx))
      {}
    };

    using monitoring_types = std::tuple<pp_mass_t, pp_pt_t, pp_p_t, p_pt_t, p_p_t, ptasym_t, evtNo_t, runNo_t>;
    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

  private:
    Allen::Property<float> m_minPT_p {this, "minPT_p", 5000.f * Allen::Units::MeV, "Minimum proton PT"};
    Allen::Property<float> m_minP_p {this, "minP_p", 25000.f * Allen::Units::MeV, "Minimum proton P"};
    Allen::Property<float> m_minPT_pp {this, "minPT_pp", 6000.f * Allen::Units::MeV, "Minimum DiProton PT"};
    Allen::Property<float> m_minP_pp {this, "minP_pp", 60000.f * Allen::Units::MeV, "Minimum DiProton P"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 16.0f, "Maximum vertex Chi2"};
    Allen::Property<float> m_minMass {this, "minMass", 8500.f * Allen::Units::MeV, "Minimum invariant mass"};
    Allen::Property<float> m_maxMass {this, "maxMass", 12500.f * Allen::Units::MeV, "Maximum invariat mass"};
    Allen::Property<float> m_maxPtAsym {this, "maxPtAsym", 0.7f, "Maximum PT asymmetry daughters w.r.t. the mother"};
    Allen::Property<bool> m_opposite_sign {this, "OppositeSign", true, "Selects opposite sign proton combinations"};
    Allen::Property<float> m_maxGhostProb {this, "maxGhostProb", 0.5, "Maximum ghost probability of the tracks"};

    Allen::Monitoring::Histogram<> m_histogram_pp_mass {this, "pp_mass", "m(pp)", {100u, 8000.f, 13000.f}};
    Allen::Monitoring::Histogram<> m_histogram_pp_pt {this, "pp_pt", "pT(pp)", {100u, 0.f, 2e4f}};
    Allen::Monitoring::Histogram<> m_histogram_pp_p {this, "pp_p", "p(pp)", {100u, 0.f, 3e5f}};

    Allen::Monitoring::Histogram<> m_histogram_p_pt {this, "p_pt", "pT(p)", {100u, 0.f, 1e4f}};
    Allen::Monitoring::Histogram<> m_histogram_p_p {this, "p_p", "p(p)", {100u, 0.f, 1e5f}};

    Allen::Monitoring::Histogram<> m_histogram_track1_ghost_prob {this,
                                                                  "track1_ghost_prob",
                                                                  "track1 GhostProb",
                                                                  {100u, 0.f, 1.0f}};
    Allen::Monitoring::Histogram<> m_histogram_track2_ghost_prob {this,
                                                                  "track2_ghost_prob",
                                                                  "track2 GhostProb",
                                                                  {100u, 0.f, 1.0f}};
  };

} // namespace diproton_highmass_line

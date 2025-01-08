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
  };

  struct kstopipi_line_t : public SelectionAlgorithm, Parameters, CompositeParticleLine<kstopipi_line_t, Parameters> {
    struct DeviceProperties {
      float minIPChi2;
      float maxVertexChi2;
      float maxIP;
      float minMass;
      float maxMass;
      float minZ;
      bool oppositeSign;
      float double_muon_misid;
      Allen::Monitoring::Histogram<>::DeviceType histogram_ks_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_ks_pt;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p0_ghost_prob;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p1_ghost_prob;
      DeviceProperties(const kstopipi_line_t& algo, const Allen::Context& ctx) :
        minIPChi2(algo.m_minIPChi2), maxVertexChi2(algo.m_maxVertexChi2), maxIP(algo.m_maxIP), minMass(algo.m_minMass),
        maxMass(algo.m_maxMass), minZ(algo.m_minZ), oppositeSign(algo.m_opposite_sign.value()),
        double_muon_misid(algo.m_double_muon_misid), histogram_ks_mass(algo.m_histogram_ks_mass.data(ctx)),
        histogram_ks_pt(algo.m_histogram_ks_pt.data(ctx)),
        histogram_p0_ghost_prob(algo.m_histogram_p0_ghost_prob.data(ctx)),
        histogram_p1_ghost_prob(algo.m_histogram_p1_ghost_prob.data(ctx))
      {}
    };

    using monitoring_types = std::tuple<sv_masses_t, pt_t, mipchi2_t>;

    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    __device__ static void fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

  private:
    Allen::Property<float> m_minIPChi2 {this, "minIPChi2", 100.f, "Minimum IPCHI2"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 10.0f, "Maximum vertex Chi2"};
    Allen::Property<float> m_maxIP {this, "maxIP", 0.3f * Gaudi::Units::mm, "Maximum IP"};
    Allen::Property<float> m_minMass {this, "minMass", 400.f * Gaudi::Units::MeV, "Minimum invariant mass"};
    Allen::Property<float> m_maxMass {this, "maxMass", 600.f * Gaudi::Units::MeV, "Maximum invariat mass"};
    Allen::Property<float> m_minZ {this, "minZ", -341.f * Gaudi::Units::mm, "minimum vertex z coordinate"};
    Allen::Property<bool> m_opposite_sign {this, "OppositeSign", true, "Selects opposite sign dimuon combinations"};
    Allen::Property<bool> m_double_muon_misid {this, "double_muon_misid", false, "Selects dimuon combinations"};

    Allen::Monitoring::Histogram<> m_histogram_ks_mass {this, "ks_mass", "m(ks)", {100u, 400.f, 600.f}};
    Allen::Monitoring::Histogram<> m_histogram_ks_pt {this, "ks_pt", "pT(ks)", {100u, 0.f, 1e4f}};
    Allen::Monitoring::Histogram<> m_histogram_p0_ghost_prob {this,
                                                              "p0_ghost_prob",
                                                              "track0 GhostProb",
                                                              {100u, 0.f, 0.6f}};
    Allen::Monitoring::Histogram<> m_histogram_p1_ghost_prob {this,
                                                              "p1_ghost_prob",
                                                              "track1 GhostProb",
                                                              {100u, 0.f, 0.6f}};
  };
} // namespace kstopipi_line

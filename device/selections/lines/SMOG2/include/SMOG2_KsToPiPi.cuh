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
    DEVICE_OUTPUT(pvz_t, float) pvz;
    DEVICE_OUTPUT(track1pt_t, float) track1pt;
    DEVICE_OUTPUT(track2pt_t, float) track2pt;
    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(minipchi2_t, float) minipchi2;
    DEVICE_OUTPUT(ip_t, float) ip;
  };

  struct SMOG2_kstopipi_line_t : public SelectionAlgorithm,
                                 Parameters,
                                 CompositeParticleLine<SMOG2_kstopipi_line_t, Parameters> {
    struct DeviceProperties {
      float minIPChi2;
      float maxVertexChi2;
      float maxIP;
      float minMass;
      float minTrackPt;
      float maxMass;
      float minPVZ;
      float maxPVZ;
      int CombCharge;

      Allen::Monitoring::Histogram<>::DeviceType histogram_smogks_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogks_svz;
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogks_pvz;
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogks_pt;
      DeviceProperties(const SMOG2_kstopipi_line_t& algo, const Allen::Context& ctx) :
        minIPChi2(algo.m_minIPChi2), maxVertexChi2(algo.m_maxVertexChi2), maxIP(algo.m_maxIP), minMass(algo.m_minMass),
        minTrackPt(algo.m_minTrackPt), maxMass(algo.m_maxMass), minPVZ(algo.m_minPVZ), maxPVZ(algo.m_maxPVZ),
        CombCharge(algo.m_CombCharge), histogram_smogks_mass(algo.m_histogram_smogks_mass.data(ctx)),
        histogram_smogks_svz(algo.m_histogram_smogks_svz.data(ctx)),
        histogram_smogks_pvz(algo.m_histogram_smogks_pvz.data(ctx)),
        histogram_smogks_pt(algo.m_histogram_smogks_pt.data(ctx))
      {}
    };
    using monitoring_types = std::tuple<sv_masses_t, svz_t, track1pt_t, track2pt_t, minipchi2_t, ip_t>;

    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceProperties& properties,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    __device__ static void fill_tuples(
      const Parameters& parameters,
      const DeviceProperties& properties,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

  private:
    Allen::Property<float> m_minIPChi2 {this, "minIPChi2", 100.f, "Minimum IPCHI2"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 10.0f, "Maximum vertex Chi2"};
    Allen::Property<float> m_maxIP {this, "maxIP", 0.3f * Gaudi::Units::mm, "Maximum IP"};
    Allen::Property<float> m_minMass {this, "minMass", 400.f * Gaudi::Units::MeV, "Minimum invariant mass"};
    Allen::Property<float> m_minTrackPt {this,
                                         "minTrackPt",
                                         200.f * Gaudi::Units::MeV,
                                         "Minimum final-state particles Pt"};
    Allen::Property<float> m_maxMass {this, "maxMass", 600.f * Gaudi::Units::MeV, "Maximum invariat mass"};
    Allen::Property<float> m_minPVZ {this, "minPVZ", -537.5f * Gaudi::Units::mm, "minimum PV z coordinate"};
    Allen::Property<float> m_maxPVZ {this, "maxPVZ", -337.5f * Gaudi::Units::mm, "maximum PV z coordinate"};
    Allen::Property<int> m_CombCharge {this, "CombCharge", 0, "Charge of the combination"};

    Allen::Monitoring::Histogram<> m_histogram_smogks_mass {this,
                                                            "SMOGks_mass",
                                                            "M (pipi) [MeV]",
                                                            {100u, 400.f, 600.f}};
    Allen::Monitoring::Histogram<> m_histogram_smogks_svz {this,
                                                           "SMOGks_svz",
                                                           "SV_z (Ks) [mm]",
                                                           {100u, -550.f, 1000.f}};
    Allen::Monitoring::Histogram<> m_histogram_smogks_pvz {this,
                                                           "SMOGks_pvz",
                                                           "PV_z (Ks) [mm]",
                                                           {100u, -550.f, -300.f}};
    Allen::Monitoring::Histogram<> m_histogram_smogks_pt {this, "SMOGks_pt", "pT (Ks)", {100u, 100.f, 8000.f}};
  };
} // namespace SMOG2_kstopipi_line

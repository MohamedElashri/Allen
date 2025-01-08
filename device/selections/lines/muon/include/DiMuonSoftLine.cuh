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

namespace di_muon_soft_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
  };

  struct di_muon_soft_line_t : public SelectionAlgorithm,
                               Parameters,
                               CompositeParticleLine<di_muon_soft_line_t, Parameters> {

    struct DeviceProperties {
      float DMSoftM0;
      float DMSoftM1;
      float DMSoftM2;
      float DMSoftMinIPChi2;
      float DMSoftMinRho2;
      float DMSoftMinZ;
      float DMSoftMaxZ;
      float DMSoftMaxDOCA;
      float DMSoftMaxIPDZ;
      float DMSoftGhost;
      bool oppositeSign;
      DeviceProperties(const di_muon_soft_line_t& algo, const Allen::Context&) :
        DMSoftM0(algo.m_DMSoftM0), DMSoftM1(algo.m_DMSoftM1), DMSoftM2(algo.m_DMSoftM2),
        DMSoftMinIPChi2(algo.m_DMSoftMinIPChi2), DMSoftMinRho2(algo.m_DMSoftMinRho2), DMSoftMinZ(algo.m_DMSoftMinZ),
        DMSoftMaxZ(algo.m_DMSoftMaxZ), DMSoftMaxDOCA(algo.m_DMSoftMaxDOCA), DMSoftMaxIPDZ(algo.m_DMSoftMaxIPDZ),
        DMSoftGhost(algo.m_DMSoftGhost), oppositeSign(algo.m_opposite_sign.value())
      {}
    };
    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

  private:
    Allen::Property<float> m_DMSoftM0 {this, "DMSoftM0", 400.f, "DMSoftM0 description"};
    Allen::Property<float> m_DMSoftM1 {this, "DMSoftM1", 475.f, "DMSoftM1 description"};
    Allen::Property<float> m_DMSoftM2 {this, "DMSoftM2", 600.f, "DMSoftM2 description"};
    Allen::Property<float> m_DMSoftMinIPChi2 {this, "DMSoftMinIPChi2", 100.f, "DMSoftMinIPChi2 description"};
    Allen::Property<float> m_DMSoftMinRho2 {this, "DMSoftMinRho2", 9.f, "DMSoftMinRho2 description"};
    Allen::Property<float> m_DMSoftMinZ {this, "DMSoftMinZ", -375.f, "DMSoftMinZ description"};
    Allen::Property<float> m_DMSoftMaxZ {this, "DMSoftMaxZ", 635.f, "DMSoftMaxZ description"};
    Allen::Property<float> m_DMSoftMaxDOCA {this, "DMSoftMaxDOCA", 0.1f, "DMSoftMaxDOCA description"};
    Allen::Property<float> m_DMSoftMaxIPDZ {this, "DMSoftMaxIPDZ", 0.04f, "DMSoftMaxIPDZ description"};
    Allen::Property<float> m_DMSoftGhost {this, "DMSoftGhost", 4.e-06f, "DMSoftGhost description"};
    Allen::Property<bool> m_opposite_sign {this, "OppositeSign", true, "Selects opposite sign dimuon combinations"};
  };
} // namespace di_muon_soft_line

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

namespace low_pt_di_muon_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
  };

  struct low_pt_di_muon_line_t : public SelectionAlgorithm,
                                 Parameters,
                                 CompositeParticleLine<low_pt_di_muon_line_t, Parameters> {

    struct DeviceProperties {
      float minTrackIP;
      float minTrackPt;
      float minTrackP;
      float minTrackIPChi2;
      float maxDOCA;
      float maxVertexChi2;
      float minMass;
      float minZ;
      bool oppositeSign;
      DeviceProperties(const low_pt_di_muon_line_t& algo, const Allen::Context&) :
        minTrackIP(algo.m_minTrackIP), minTrackPt(algo.m_minTrackPt), minTrackP(algo.m_minTrackP),
        minTrackIPChi2(algo.m_minTrackIPChi2), maxDOCA(algo.m_maxDOCA), maxVertexChi2(algo.m_maxVertexChi2),
        minMass(algo.m_minMass), minZ(algo.m_minZ), oppositeSign(algo.m_opposite_sign.value())
      {}
    };
    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

  private:
    Allen::Property<float> m_minTrackIP {this, "minTrackIP", 0.1f, "minTrackIP description"};
    Allen::Property<float> m_minTrackPt {this, "minTrackPt", 80.f, "minTrackPt description"};
    Allen::Property<float> m_minTrackP {this, "minTrackP", 3000.f, "minTrackP description"};
    Allen::Property<float> m_minTrackIPChi2 {this, "minTrackIPChi2", 1.f, "minTrackIPChi2 description"};
    Allen::Property<float> m_maxDOCA {this, "maxDOCA", 0.2f, "maxDOCA description"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 25.f, "maxVertexChi2 description"};
    Allen::Property<float> m_minMass {this, "minMass", 220.f, "minMass description"};
    Allen::Property<float> m_minZ {this, "minZ", -330.f * Allen::Units::mm, "minimum vertex z coordinate"};
    Allen::Property<bool> m_opposite_sign {this, "OppositeSign", true, "Selects opposite sign dimuon combinations"};
  };
} // namespace low_pt_di_muon_line

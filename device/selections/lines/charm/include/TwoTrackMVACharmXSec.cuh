/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"
#include "VertexDefinitions.cuh"
#include "MassDefinitions.h"
#include "ParticleTypes.cuh"

namespace two_track_mva_charm_xsec_line {

  using Allen::Views::Physics::BasicParticle;
  using Allen::Views::Physics::CompositeParticle;

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_two_track_mva_evaluation_t, float) dev_two_track_mva_evaluation;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
  };

  struct two_track_mva_charm_xsec_line_t : public SelectionAlgorithm,
                                           Parameters,
                                           CompositeParticleLine<two_track_mva_charm_xsec_line_t, Parameters> {

    struct DeviceProperties {
      float maxVertexChi2;
      float minTrackPt;
      float minTrackP;
      float minTrackIPChi2;
      float maxDOCA;
      float massWindow;
      float maxCombKpiMass;
      float lowSVpt;
      float minMVAhighPt;
      float minMVAlowPt;
      float minZ;
      DeviceProperties(const two_track_mva_charm_xsec_line_t& algo, const Allen::Context&) :
        maxVertexChi2(algo.m_maxVertexChi2), minTrackPt(algo.m_minTrackPt), minTrackP(algo.m_minTrackP),
        minTrackIPChi2(algo.m_minTrackIPChi2), maxDOCA(algo.m_maxDOCA), massWindow(algo.m_massWindow),
        maxCombKpiMass(algo.m_maxCombKpiMass), lowSVpt(algo.m_lowSVpt), minMVAhighPt(algo.m_minMVAhighPt),
        minMVAlowPt(algo.m_minMVAlowPt), minZ(algo.m_minZ)
      {}
    };

    __device__ static std::tuple<const CompositeParticle, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const CompositeParticle, const float> input);

  private:
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 20.f, "Maximum chi2 of the combination vertex."};
    Allen::Property<float> m_minTrackPt {this,
                                         "minTrackPt",
                                         250.f * Allen::Units::MeV,
                                         "Minimum transverse momentum of tracks."};
    Allen::Property<float> m_minTrackP {this, "minTrackP", 2000.f * Allen::Units::MeV, "Minimum momentum of tracks."};
    Allen::Property<float> m_minTrackIPChi2 {this, "minTrackIPChi2", 4.f, "Minimum IPCHI2 of tracks."};
    Allen::Property<float> m_maxDOCA {this,
                                      "maxDOCA",
                                      0.2f * Allen::Units::mm,
                                      "Maximum distance of closest approach of tracks."};
    Allen::Property<float> m_massWindow {this,
                                         "massWindow",
                                         100.f * Allen::Units::MeV,
                                         "Window around the combination mass."};
    Allen::Property<float> m_maxCombKpiMass {this,
                                             "maxCombKpiMass",
                                             1830.f * Allen::Units::MeV,
                                             "Maximum invariant mass of combination assuming kaon and pion."};
    Allen::Property<float> m_lowSVpt {this,
                                      "lowSVpt",
                                      1500.f * Allen::Units::MeV,
                                      "Value of SV pT in MeV below which the low PT MVA cut is applied."};
    Allen::Property<float> m_minMVAhighPt {this, "minMVAhighPt", 0.92385f, "Minimum passing MVA response at hight Pt."};
    Allen::Property<float> m_minMVAlowPt {this, "minMVAlowPt", 0.7f, "Minimum passing MVA response at low Pt."};
    Allen::Property<float> m_minZ {this, "minZ", -330.f * Allen::Units::mm, "minimum vertex z coordinate"};
  };
} // namespace two_track_mva_charm_xsec_line

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
#include "TwoTrackLine.cuh"
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
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;

    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);

    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "Maximum chi2 of the combination vertex.", float)
    maxVertexChi2;
    PROPERTY(minTrackPt_t, "minTrackPt", "Minimum transverse momentum of tracks.", float) minTrackPt;
    PROPERTY(minTrackP_t, "minTrackP", "Minimum momentum of tracks.", float) minTrackP;
    PROPERTY(minTrackIPChi2_t, "minTrackIPChi2", "Minimum IPCHI2 of tracks.", float) minTrackIPChi2;
    PROPERTY(maxDOCA_t, "maxDOCA", "Maximum distance of closest approach of tracks.", float) maxDOCA;
    PROPERTY(massWindow_t, "massWindow", "Window around the combination mass.", float) massWindow;
    PROPERTY(maxCombKpiMass_t, "maxCombKpiMass", "Maximum invariant mass of combination assuming kaon and pion.", float)
    maxCombKpiMass;
    PROPERTY(lowSVpt_t, "lowSVpt", "Value of SV pT in MeV below which the low PT MVA cut is applied.", float) lowSVpt;
    PROPERTY(minMVAhightPt_t, "minMVAhighPt", "Minimum passing MVA response at hight Pt.", float) minMVAhighPt;
    PROPERTY(minMVAlowPt_t, "minMVAlowPt", "Minimum passing MVA response at low Pt.", float) minMVAlowPt;
    PROPERTY(minZ_t, "minZ", "minimum vertex z coordinate", float) minZ;
  };

  struct two_track_mva_charm_xsec_line_t : public SelectionAlgorithm,
                                           Parameters,
                                           TwoTrackLine<two_track_mva_charm_xsec_line_t, Parameters> {

    __device__ static std::tuple<const CompositeParticle, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    __device__ static bool select(const Parameters& parameters, std::tuple<const CompositeParticle, const float> input);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<maxVertexChi2_t> m_maxVertexChi {this, 20.f};
    Property<minTrackPt_t> m_minTrackPt {this, 250.f * Gaudi::Units::MeV};
    Property<minTrackP_t> m_minTrackP {this, 2000.f * Gaudi::Units::MeV};
    Property<minTrackIPChi2_t> m_minTrackIPChi2 {this, 4.f};
    Property<maxDOCA_t> m_maxDOCA {this, 0.2f * Gaudi::Units::mm};
    Property<massWindow_t> m_massWindow {this, 100.f * Gaudi::Units::MeV};
    Property<maxCombKpiMass_t> m_maxCombKpiMass {this, 1830.f * Gaudi::Units::MeV};
    Property<lowSVpt_t> m_lowSVpt {this, 1500.f * Gaudi::Units::MeV};
    Property<minMVAhightPt_t> m_minMVAhighPt {this, 0.92385f};
    Property<minMVAlowPt_t> m_minMVAlowPt {this, 0.7f};
    Property<minZ_t> m_minZ {this, -341.f * Gaudi::Units::mm};
  };
} // namespace two_track_mva_charm_xsec_line

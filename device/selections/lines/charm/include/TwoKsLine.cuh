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

namespace two_ks_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    // Line-specific inputs and properties
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char) host_fn_parameters;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "maxVertexChi2 description", float) maxVertexChi2;
    PROPERTY(minComboPt_Ks_t, "minComboPt_Ks", "minComboPt Ks description", float) minComboPt_Ks;
    PROPERTY(minCosDira_t, "minCosDira", "minCosDira description", float) minCosDira;
    PROPERTY(minEta_Ks_t, "minEta_Ks", "minEta_Ks description", float) minEta_Ks;
    PROPERTY(maxEta_Ks_t, "maxEta_Ks", "maxEta_Ks description", float) maxEta_Ks;
    PROPERTY(minTrackPt_piKs_t, "minTrackPt_piKs", "minTrackPt_piKs description", float) minTrackPt_piKs;
    PROPERTY(minTrackP_piKs_t, "minTrackP_piKs", "minTrackP_piKs description", float) minTrackP_piKs;
    PROPERTY(minTrackIPChi2_Ks_t, "minTrackIPChi2_Ks", "minTrackIPChi2_Ks description", float) minTrackIPChi2_Ks;
    PROPERTY(minM_Ks_t, "minM_Ks", "minM_Ks description", float) minM_Ks;
    PROPERTY(maxM_Ks_t, "maxM_Ks", "maxM_Ks description", float) maxM_Ks;
    PROPERTY(minCosOpening_t, "minCosOpening", "minCosOpening description", float) minCosOpening;
    PROPERTY(min_combip_t, "min_combip", "min_combip description", float) min_combip;
  };

  struct two_ks_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<two_ks_line_t, Parameters> {
    __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    __device__ static bool select(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned, const unsigned> input);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 20.f};
    Property<minComboPt_Ks_t> m_minComboPt_Ks {this, 1150.f / Gaudi::Units::MeV};
    Property<minCosDira_t> m_minCosDira {this, 0.99f};
    Property<minEta_Ks_t> m_minEta_Ks {this, 2.f};
    Property<maxEta_Ks_t> m_maxEta_Ks {this, 4.2f};
    Property<minTrackPt_piKs_t> m_minTrackPt_piKs {this, 425.f / Gaudi::Units::MeV};
    Property<minTrackP_piKs_t> m_minTrackP_piKs {this, 3000.f / Gaudi::Units::MeV};
    Property<minTrackIPChi2_Ks_t> m_minTrackIPChi2_Ks {this, 15.f};
    Property<minM_Ks_t> m_minM_Ks {this, 455.0f / Gaudi::Units::MeV};
    Property<maxM_Ks_t> m_maxM_Ks {this, 545.0f / Gaudi::Units::MeV};
    Property<minCosOpening_t> m_minCosOpening {this, 0.99f};
    Property<min_combip_t> m_min_combip {this, 0.23f / Gaudi::Units::mm};
  };
} // namespace two_ks_line

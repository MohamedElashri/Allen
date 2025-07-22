/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
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
#include "MassDefinitions.h"

namespace two_track_line_ks {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    // Line-specific inputs and properties
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(eta_ks_t, float) eta_ks;
    DEVICE_OUTPUT(pt_ks_t, float) pt_ks;
    DEVICE_OUTPUT(min_pt_t, float) min_pt;
    DEVICE_OUTPUT(min_ipchi2_t, float) min_ipchi2;
    DEVICE_OUTPUT(min_p_t, float) min_p;
    DEVICE_OUTPUT(comb_ip_t, float) comb_ip;
    DEVICE_OUTPUT(mass_t, float) mass;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct two_track_line_ks_t : public SelectionAlgorithm,
                               Parameters,
                               CompositeParticleLine<two_track_line_ks_t, Parameters> {

    struct DeviceProperties {
      float maxVertexChi2;
      float minComboPt_Ks;
      float minCosDira;
      float minEta_Ks;
      float maxEta_Ks;
      float minTrackPt_piKs;
      float minTrackP_piKs;
      float minTrackIPChi2_Ks;
      float minM_Ks;
      float maxM_Ks;
      float minCosOpening;
      float min_combip;
      float minZ;
      bool oppositeSign;
      DeviceProperties(const two_track_line_ks_t& algo, const Allen::Context&) :
        maxVertexChi2(algo.m_maxVertexChi2), minComboPt_Ks(algo.m_minComboPt_Ks), minCosDira(algo.m_minCosDira),
        minEta_Ks(algo.m_minEta_Ks), maxEta_Ks(algo.m_maxEta_Ks), minTrackPt_piKs(algo.m_minTrackPt_piKs),
        minTrackP_piKs(algo.m_minTrackP_piKs), minTrackIPChi2_Ks(algo.m_minTrackIPChi2_Ks), minM_Ks(algo.m_minM_Ks),
        maxM_Ks(algo.m_maxM_Ks), minCosOpening(algo.m_minCosOpening), min_combip(algo.m_min_combip), minZ(algo.m_minZ),
        oppositeSign(algo.m_opposite_sign)
      {}
    };

    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);
    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle>,
      unsigned,
      bool);

    using monitoring_types =
      std::tuple<eta_ks_t, pt_ks_t, min_pt_t, min_ipchi2_t, min_p_t, comb_ip_t, mass_t, evtNo_t, runNo_t>;

  private:
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 20.f, "maxVertexChi2 description"};
    Allen::Property<float> m_minComboPt_Ks {this,
                                            "minComboPt_Ks",
                                            2500.f / Allen::Units::MeV,
                                            "minComboPt Ks description"};
    Allen::Property<float> m_minCosDira {this, "minCosDira", 0.99f, "minCosDira description"};
    Allen::Property<float> m_minEta_Ks {this, "minEta_Ks", 2.f, "minEta_Ks description"};
    Allen::Property<float> m_maxEta_Ks {this, "maxEta_Ks", 4.2f, "maxEta_Ks description"};
    Allen::Property<float> m_minTrackPt_piKs {this,
                                              "minTrackPt_piKs",
                                              470.f / Allen::Units::MeV,
                                              "minTrackPt_piKs description"};
    Allen::Property<float> m_minTrackP_piKs {this,
                                             "minTrackP_piKs",
                                             5000.f / Allen::Units::MeV,
                                             "minTrackP_piKs description"};
    Allen::Property<float> m_minTrackIPChi2_Ks {this, "minTrackIPChi2_Ks", 50.f, "minTrackIPChi2_Ks description"};
    Allen::Property<float> m_minM_Ks {this, "minM_Ks", 455.0f / Allen::Units::MeV, "minM_Ks description"};
    Allen::Property<float> m_maxM_Ks {this, "maxM_Ks", 545.0f / Allen::Units::MeV, "maxM_Ks description"};
    Allen::Property<float> m_minCosOpening {this, "minCosOpening", 0.99f, "minCosOpening description"};
    Allen::Property<float> m_min_combip {this, "min_combip", 0.72f / Allen::Units::mm, "min_combip description"};
    Allen::Property<float> m_minZ {this, "minZ", -330.f * Allen::Units::mm, "minimum vertex z coordinate"};
    Allen::Property<bool> m_opposite_sign {this, "OppositeSign", true, "Selects opposite sign dimuon combinations"};
  };
} // namespace two_track_line_ks

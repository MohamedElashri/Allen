/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
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

#include "AllenMonitoring.h"

namespace dst_d2kpi_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;

    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    // Monitoring
    DEVICE_OUTPUT(min_pt_t, float) min_pt; // To be used in bandwidth division.
    DEVICE_OUTPUT(min_ip_t, float) min_ip; // To be used in bandwidth division.
    DEVICE_OUTPUT(D0_ct_t, float) D0_ct;   // To be used in bandwidth division.
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct dst_d2kpi_line_t : public SelectionAlgorithm, Parameters, CompositeParticleLine<dst_d2kpi_line_t, Parameters> {
    struct DeviceProperties {
      float minComboPt;
      float maxVertexChi2;
      float minFDChi2;
      float maxDOCA;
      float minEta;
      float maxEta;
      float minTrackPt;
      float massWindow;
      float minTrackIP;
      float ctIPScale;
      float dmMax;
      float minZ;

      Allen::Monitoring::Histogram<>::DeviceType histogram_d0_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_d0_pt;
      Allen::Monitoring::Histogram<>::DeviceType histogram_dst_dm;
      DeviceProperties(const dst_d2kpi_line_t& algo, const Allen::Context& ctx) :
        minComboPt(algo.m_minComboPt), maxVertexChi2(algo.m_maxVertexChi2), minFDChi2(algo.m_minFDChi2),
        maxDOCA(algo.m_maxDOCA), minEta(algo.m_minEta), maxEta(algo.m_maxEta), minTrackPt(algo.m_minTrackPt),
        massWindow(algo.m_massWindow), minTrackIP(algo.m_minTrackIP), ctIPScale(algo.m_ctIPScale), dmMax(algo.m_dmMax),
        minZ(algo.m_minZ), histogram_d0_mass(algo.m_histogram_d0_mass.data(ctx)),
        histogram_d0_pt(algo.m_histogram_d0_pt.data(ctx)), histogram_dst_dm(algo.m_histogram_dst_dm.data(ctx))
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

    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle>,
      unsigned,
      bool);

    using monitoring_types = std::tuple<min_pt_t, min_ip_t, D0_ct_t, evtNo_t, runNo_t>;

  private:
    Allen::Property<float> m_minComboPt {this, "minComboPt", 500.0f * Allen::Units::MeV, "minComboPt description"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 20.f, "maxVertexChi2 description"};
    Allen::Property<float> m_minFDChi2 {this, "minFDChi2", 25.f, "minFDChi2 description"};
    Allen::Property<float> m_maxDOCA {this, "maxDOCA", 0.2f * Allen::Units::mm, "maxDOCA description"};
    Allen::Property<float> m_minEta {this, "minEta", 2.0f, "minEta description"};
    Allen::Property<float> m_maxEta {this, "maxEta", 5.0f, "maxEta description"};
    Allen::Property<float> m_minTrackPt {this, "minTrackPt", 250.f * Allen::Units::MeV, "minTrackPt description"};
    Allen::Property<float> m_massWindow {this, "massWindow", 100.f * Allen::Units::MeV, "massWindow description"};
    Allen::Property<float> m_minTrackIP {this, "minTrackIP", 0.06f * Allen::Units::mm, "minTrackIP description"};
    Allen::Property<float> m_ctIPScale {this, "ctIPScale", 1.f, "D0 ct should be larger than this time minTrackIP"};
    Allen::Property<float> m_dmMax {this, "dmMax", 160.f * Allen::Units::MeV, "Maximum Dst-D0 mass difference."};
    Allen::Property<float> m_minZ {this, "minZ", -330.f * Allen::Units::mm, "minimum vertex z coordinate"};

    Allen::Monitoring::Histogram<> m_histogram_d0_mass {this, "d0_mass", "m(D0)", {100u, 1765.f, 1965.f}};
    Allen::Monitoring::Histogram<> m_histogram_d0_pt {this, "d0_pt", "pT(D0)", {100u, 0.f, 1e4f}};
    Allen::Monitoring::Histogram<> m_histogram_dst_dm {this, "dst_dm", "m(D*)-m(D0)", {84u, 139.f, 160.f}};
  };

} // namespace dst_d2kpi_line

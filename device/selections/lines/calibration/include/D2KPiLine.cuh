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

namespace d2kpi_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    // Monitoring
    DEVICE_OUTPUT(min_pt_t, float) min_pt; // To be used in bandwidth division
    DEVICE_OUTPUT(min_ip_t, float) min_ip; // To be used in bandwidth division
    DEVICE_OUTPUT(D0_ct_t, float) D0_ct;   // To be used in bandwidth division
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct d2kpi_line_t : public SelectionAlgorithm, Parameters, CompositeParticleLine<d2kpi_line_t, Parameters> {
    struct DeviceProperties {
      float minComboPt;
      float maxVertexChi2;
      float maxDOCA;
      float minEta;
      float maxEta;
      float minTrackPt;
      float minTrackP;
      float massWindow;
      float minTrackIP;
      float ctIPScale;
      float minZ;
      float minDira;
      bool oppositeSign;

      Allen::Monitoring::Histogram<>::DeviceType histogram_d0_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_d0_pt;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p0_ipx;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p0_ipy;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p1_ipx;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p1_ipy;
      DeviceProperties(const d2kpi_line_t& algo, const Allen::Context& ctx) :
        minComboPt(algo.m_minComboPt), maxVertexChi2(algo.m_maxVertexChi2), maxDOCA(algo.m_maxDOCA),
        minEta(algo.m_minEta), maxEta(algo.m_maxEta), minTrackPt(algo.m_minTrackPt), minTrackP(algo.m_minTrackP),
        massWindow(algo.m_massWindow), minTrackIP(algo.m_minTrackIP), ctIPScale(algo.m_ctIPScale), minZ(algo.m_minZ),
        minDira(algo.m_minDira), oppositeSign(algo.m_opposite_sign),
        histogram_d0_mass(algo.m_histogram_d0_mass.data(ctx)), histogram_d0_pt(algo.m_histogram_d0_pt.data(ctx)),
        histogram_p0_ipx(algo.m_histogram_p0_ipx.data(ctx)), histogram_p0_ipy(algo.m_histogram_p0_ipy.data(ctx)),
        histogram_p1_ipx(algo.m_histogram_p1_ipx.data(ctx)), histogram_p1_ipy(algo.m_histogram_p1_ipy.data(ctx))
      {}
    };

    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);
    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceProperties& properties,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<min_pt_t, min_ip_t, D0_ct_t, evtNo_t, runNo_t>;

  private:
    Allen::Property<float> m_minComboPt {this, "minComboPt", 2000.0f * Allen::Units::MeV, "minComboPt description"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 20.f, "maxVertexChi2 description"};
    Allen::Property<float> m_maxDOCA {this, "maxDOCA", 0.2f * Allen::Units::mm, "maxDOCA description"};
    Allen::Property<float> m_minEta {this, "minEta", 2.0f, "minEta description"};
    Allen::Property<float> m_maxEta {this, "maxEta", 5.0f, "maxEta description"};
    Allen::Property<float> m_minTrackPt {this, "minTrackPt", 800.f * Allen::Units::MeV, "minTrackPt description"};
    Allen::Property<float> m_minTrackP {this, "minTrackP", 0.f * Allen::Units::MeV, "minTrackP description"};
    Allen::Property<float> m_massWindow {this, "massWindow", 100.f * Allen::Units::MeV, "massWindow description"};
    Allen::Property<float> m_minTrackIP {this, "minTrackIP", 0.06f * Allen::Units::mm, "minTrackIP description"};
    Allen::Property<float> m_ctIPScale {this, "ctIPScale", 1.f, "D0 ct should be larger than this time minTrackIP"};
    Allen::Property<float> m_minZ {this, "minZ", -330.f * Allen::Units::mm, "minimum vertex z coordinate"};
    Allen::Property<float> m_minDira {this, "minDira", 0.f, "minimum value of cos(theta_dira)"};
    Allen::Property<bool> m_opposite_sign {this, "OppositeSign", true, "Selects opposite sign dibody combinations"};

    Allen::Monitoring::Histogram<> m_histogram_d0_mass {this, "d0_mass", "m(D0)", {100u, 1765.f, 1965.f}};
    Allen::Monitoring::Histogram<> m_histogram_d0_pt {this, "d0_pt", "pT(D0)", {100u, 800.f, 1e4f}};
    Allen::Monitoring::Histogram<> m_histogram_p0_ipx {this, "p0_ipx", "IP_{x}(p0)", {100u, -3.f, 3.f}};
    Allen::Monitoring::Histogram<> m_histogram_p0_ipy {this, "p0_ipy", "IP_{y}(p0)", {100u, -3.f, 3.f}};
    Allen::Monitoring::Histogram<> m_histogram_p1_ipx {this, "p1_ipx", "IP_{x}(p1)", {100u, -3.f, 3.f}};
    Allen::Monitoring::Histogram<> m_histogram_p1_ipy {this, "p1_ipy", "IP_{y}(p1)", {100u, -3.f, 3.f}};
  };
} // namespace d2kpi_line

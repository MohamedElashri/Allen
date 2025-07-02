/*****************************************************************************\
 * (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
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
#include "OneTrackLine.cuh"
#include "AllenMonitoring.h"
#include "ROOTService.h"

namespace track_mva_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(ipchi2_t, float) ipchi2;
    DEVICE_OUTPUT(ghostProb_t, float) ghostProb;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct track_mva_line_t : public SelectionAlgorithm, Parameters, OneTrackLine<track_mva_line_t, Parameters> {
    struct DeviceProperties {
      float maxChi2Ndof;
      float minPt;
      float maxPt;
      float minIPChi2;
      float param1;
      float param2;
      float param3;
      float alpha;
      float minBPVz;
      float maxGhostProb;
      Allen::Monitoring::Histogram<>::DeviceType histogram_ghost_prob;
      Allen::Monitoring::Histogram<>::DeviceType histogram_ip_x;
      Allen::Monitoring::Histogram<>::DeviceType histogram_ip_y;
      DeviceProperties(const track_mva_line_t& algo, const Allen::Context& ctx) :
        maxChi2Ndof(algo.m_maxChi2Ndof), minPt(algo.m_minPt), maxPt(algo.m_maxPt), minIPChi2(algo.m_minIPChi2),
        param1(algo.m_param1), param2(algo.m_param2), param3(algo.m_param3), alpha(algo.m_alpha),
        minBPVz(algo.m_minBPVz), maxGhostProb(algo.m_maxGhostProb),
        histogram_ghost_prob(algo.m_histogram_ghost_prob.data(ctx)), histogram_ip_x(algo.m_histogram_ip_x.data(ctx)),
        histogram_ip_y(algo.m_histogram_ip_y.data(ctx))
      {}
    };

    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::BasicParticle>);
    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::BasicParticle>,
      unsigned,
      bool);
    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::BasicParticle>,
      unsigned,
      bool);

    using monitoring_types = std::tuple<pt_t, ipchi2_t, ghostProb_t, evtNo_t, runNo_t>;

  private:
    Allen::Property<float> m_maxChi2Ndof {this, "maxChi2Ndof", 2.5f, "maxChi2Ndof description"};
    Allen::Property<float> m_minPt {this, "minPt", 2.f * Allen::Units::GeV, "minPt description"};
    Allen::Property<float> m_maxPt {this, "maxPt", 26.f * Allen::Units::GeV, "maxPt description"};
    Allen::Property<float> m_minIPChi2 {this, "minIPChi2", 7.4f, "minIPChi2 description"};
    Allen::Property<float> m_param1 {this, "param1", 1.f * Allen::Units::GeV* Allen::Units::GeV, "param1 description"};
    Allen::Property<float> m_param2 {this, "param2", 2.f * Allen::Units::GeV, "param2 description"};
    Allen::Property<float> m_param3 {this, "param3", 1.248f, "param3 description"};
    Allen::Property<float> m_alpha {this,
                                    "alpha",
                                    296.f * Allen::Units::MeV,
                                    "alpha description"}; // tuned to about 330 kHz (modulo GEC)
    Allen::Property<float> m_minBPVz {this,
                                      "minBPVz",
                                      -330.f * Allen::Units::mm,
                                      "minimum z for the best associated primary vertex"};
    Allen::Property<float> m_maxGhostProb {this, "maxGhostProb", 0.5, "Maximum ghost probability of the tracks"};

    Allen::Monitoring::Histogram<> m_histogram_ghost_prob {this, "ghost_prob", "track GhostProb", {100u, 0.f, 0.6f}};
    Allen::Monitoring::Histogram<> m_histogram_ip_x {this, "ip_x", "IP_{x}", {100u, -3.f, 3.f}};
    Allen::Monitoring::Histogram<> m_histogram_ip_y {this, "ip_y", "IP_{y}", {100u, -3.f, 3.f}};
  };
} // namespace track_mva_line

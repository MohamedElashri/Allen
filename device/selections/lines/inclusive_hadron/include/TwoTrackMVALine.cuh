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
#include "CompositeParticleLine.cuh"
#include "ParticleTypes.cuh"
#include "AllenMonitoring.h"
#include "ROOTService.h"

namespace two_track_mva_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_two_track_mva_evaluation_t, float) dev_two_track_mva_evaluation;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(mva_t, float) mva;
    DEVICE_OUTPUT(maxChildGhostProb_t, float) maxChildGhostProb;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct two_track_mva_line_t : public SelectionAlgorithm,
                                Parameters,
                                CompositeParticleLine<two_track_mva_line_t, Parameters> {
    __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    struct DeviceProperties {
      float minMVA;
      float minPt;
      float minSVpt;
      float minEta;
      float maxEta;
      float minMcor;
      float maxSVchi2;
      float maxDOCA;
      float minipchi2;
      float minZ;
      float maxGhostProb;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p0_ghost_prob;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p1_ghost_prob;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p0_ip_x;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p1_ip_x;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p0_ip_y;
      Allen::Monitoring::Histogram<>::DeviceType histogram_p1_ip_y;
      Allen::Monitoring::Histogram<>::DeviceType histogram_d0_mass;
      DeviceProperties(const two_track_mva_line_t& algo, const Allen::Context& ctx) :
        minMVA(algo.m_minMVA), minPt(algo.m_minPt), minSVpt(algo.m_minSVpt), minEta(algo.m_minEta),
        maxEta(algo.m_maxEta), minMcor(algo.m_minMcor), maxSVchi2(algo.m_maxSVchi2), maxDOCA(algo.m_maxDOCA),
        minipchi2(algo.m_minipchi2), minZ(algo.m_minZ), maxGhostProb(algo.m_maxGhostProb),
        histogram_p0_ghost_prob(algo.m_histogram_p0_ghost_prob.data(ctx)),
        histogram_p1_ghost_prob(algo.m_histogram_p1_ghost_prob.data(ctx)),
        histogram_p0_ip_x(algo.m_histogram_p0_ip_x.data(ctx)), histogram_p1_ip_x(algo.m_histogram_p1_ip_x.data(ctx)),
        histogram_p0_ip_y(algo.m_histogram_p0_ip_y.data(ctx)), histogram_p1_ip_y(algo.m_histogram_p1_ip_y.data(ctx)),
        histogram_d0_mass(algo.m_histogram_d0_mass.data(ctx))
      {}
    };

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>);

    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>,
      unsigned,
      bool);

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>,
      unsigned,
      bool);

    using monitoring_types = std::tuple<mva_t, maxChildGhostProb_t, evtNo_t, runNo_t>;

  private:
    Allen::Property<float> m_minMVA {this,
                                     "minMVA",
                                     0.9569f,
                                     "Minimum passing MVA response."}; // tuned to about 660 kHz (modulo GEC)
    Allen::Property<float> m_minPt {this, "minPt", 200.f * Allen::Units::MeV, "Minimum track pT in MeV."};
    Allen::Property<float> m_minSVpt {this, "minSVpt", 1000.f * Allen::Units::MeV, "Minimum SV pT in MeV."};
    Allen::Property<float> m_minEta {this, "minEta", 2.f, "Minimum PV-SV eta."};
    Allen::Property<float> m_maxEta {this, "maxEta", 5.f, "Maximum PV-SV eta."};
    Allen::Property<float> m_minMcor {this, "minMcor", 1000.f, "Minimum corrected mass in MeV"};
    Allen::Property<float> m_maxSVchi2 {this, "maxSVchi2", 20.f, "Maximum SV chi2"};
    Allen::Property<float> m_maxDOCA {this, "maxDOCA", 0.2f, "Maximum DOCA between two tracks"};
    Allen::Property<float> m_minipchi2 {
      this,
      "minipchi2",
      4.f,
      "minimum ipchi2 of the tracks"}; // this is probably a noop, but better safe than sorry
    Allen::Property<float> m_minZ {this, "minZ", -330.f * Allen::Units::mm, "minimum vertex z coordinate"};
    Allen::Property<float> m_maxGhostProb {this, "maxGhostProb", 0.5, "Maximum ghost probability of the tracks"};

    Allen::Monitoring::Histogram<> m_histogram_p0_ghost_prob {this,
                                                              "p0_ghost_prob",
                                                              "track0 GhostProb",
                                                              {100u, 0.f, 0.6f}};
    Allen::Monitoring::Histogram<> m_histogram_p1_ghost_prob {this,
                                                              "p1_ghost_prob",
                                                              "track1 GhostProb",
                                                              {100u, 0.f, 0.6f}};
    Allen::Monitoring::Histogram<> m_histogram_p0_ip_x {this, "p0_ip_x", "IP_{x}(p0)", {100u, -3.f, 3.f}};
    Allen::Monitoring::Histogram<> m_histogram_p1_ip_x {this, "p1_ip_x", "IP_{x}(p1)", {100u, -3.f, 3.f}};
    Allen::Monitoring::Histogram<> m_histogram_p0_ip_y {this, "p0_ip_y", "IP_{y}(p0)", {100u, -3.f, 3.f}};
    Allen::Monitoring::Histogram<> m_histogram_p1_ip_y {this, "p1_ip_y", "IP_{y}(p1)", {100u, -3.f, 3.f}};
    Allen::Monitoring::Histogram<> m_histogram_d0_mass {this, "d0_mass", "m(K#pi)", {100u, 1765.f, 1965.f}};
  };

} // namespace two_track_mva_line

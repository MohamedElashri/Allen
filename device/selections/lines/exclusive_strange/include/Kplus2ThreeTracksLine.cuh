/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
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

namespace kplus_to_three_tracks_line {
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
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct kplus_to_three_tracks_line_t : public SelectionAlgorithm,
                                        Parameters,
                                        CompositeParticleLine<kplus_to_three_tracks_line_t, Parameters> {

    struct DeviceProperties {
      float minComboPt;
      float maxVertexChi2;
      float maxDOCA;
      float minEta;
      float maxEta;
      float minTrackPt;
      float minTrackP;
      float massWindow_min;
      float massWindow_max;
      float minTrackIP;
      float minZ;
      float minPairMass;
      float maxPairMass;
      bool is_dimuon;
      bool is_dielectron;
      float mass_companion;
      float mass_seed_track_one;
      float mass_seed_track_two;
      float minFlightDistance;
      Allen::Monitoring::Histogram<>::DeviceType histogramTwoBodySeedMass;
      Allen::Monitoring::Histogram<>::DeviceType histogramTwoBodySeedPt;
      DeviceProperties(const kplus_to_three_tracks_line_t& algo, const Allen::Context& ctx) :
        minComboPt(algo.m_minComboPt), maxVertexChi2(algo.m_maxVertexChi2), maxDOCA(algo.m_maxDOCA),
        minEta(algo.m_minEta), maxEta(algo.m_maxEta), minTrackPt(algo.m_minTrackPt), minTrackP(algo.m_minTrackP),
        massWindow_min(algo.m_massWindow_min), massWindow_max(algo.m_massWindow_max), minTrackIP(algo.m_minTrackIP),
        minZ(algo.m_minZ), minPairMass(algo.m_minPairMass), maxPairMass(algo.m_maxPairMass),
        is_dimuon(algo.m_is_dimuon), is_dielectron(algo.m_is_dielectron), mass_companion(algo.m_mass_companion),
        mass_seed_track_one(algo.m_mass_seed_track_one), mass_seed_track_two(algo.m_mass_seed_track_two),
        minFlightDistance(algo.m_minFlightDistance),
        histogramTwoBodySeedMass(algo.m_histogramTwoBodySeedMass.data(ctx)),
        histogramTwoBodySeedPt(algo.m_histogramTwoBodySeedPt.data(ctx))
      {}
    };

    __device__ static bool select(
      const Parameters& parameters,
      const DeviceProperties& properties,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input);

    __device__ static bool fill_tuples(
      const Parameters& parameters,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties& accumulators,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<min_pt_t, min_ip_t, evtNo_t, runNo_t>;

  private:
    Allen::Property<float> m_minComboPt {this, "minComboPt", 100.0f * Allen::Units::MeV, "Minimum combination pt"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 20.f, "Maximum vertex chi2"};
    Allen::Property<float> m_maxDOCA {this, "maxDOCA", 0.2f * Allen::Units::mm, "Maximum DOCA"};
    Allen::Property<float> m_minEta {this, "minEta", 2.0f, "Minimum PV-SV eta"};
    Allen::Property<float> m_maxEta {this, "maxEta", 5.0f, "Maximum PV-SV eta"};
    Allen::Property<float> m_minTrackPt {this, "minTrackPt", 100.f * Allen::Units::MeV, "Minimum track pt"};
    Allen::Property<float> m_minTrackP {this, "minTrackP", 100.f * Allen::Units::MeV, "Minimum track P"};
    Allen::Property<float> m_massWindow_min {this, "massWindow_min", 200.f * Allen::Units::MeV, "Low mass window"};
    Allen::Property<float> m_massWindow_max {this, "massWindow_max", 200.f * Allen::Units::MeV, "Upper mass window"};
    Allen::Property<float> m_minTrackIP {this, "minTrackIP", 0.5f * Allen::Units::mm, "Minimum track IP"};
    Allen::Property<float> m_minZ {this, "minZ", -341.f * Allen::Units::mm, "Minimum z of vertex"};
    Allen::Property<float> m_minPairMass {this,
                                          "minPairMass",
                                          0.f * Allen::Units::MeV,
                                          "Minimum mass of the two-track pair"};
    Allen::Property<float> m_maxPairMass {this,
                                          "maxPairMass",
                                          1000.f * Allen::Units::MeV,
                                          "Maximum mass of the two-track pair"};
    Allen::Property<bool> m_is_dimuon {this, "is_dimuon", false, "Require dimuon"};
    Allen::Property<bool> m_is_dielectron {this, "is_dielectron", false, "Require dielectron"};
    Allen::Property<float> m_mass_companion {this, "mass_companion", Allen::mPi, "Mass of child 0"};
    Allen::Property<float> m_mass_seed_track_one {this, "mass_seed_track_one", Allen::mPi, "Mass of child 1"};
    Allen::Property<float> m_mass_seed_track_two {this, "mass_seed_track_two", Allen::mPi, "Mass of child 2"};
    Allen::Property<float> m_minFlightDistance {this,
                                                "minFlightDistance",
                                                Allen::Units::mm,
                                                "Mininum Flight Distance of mother"};
    Allen::Monitoring::Histogram<> m_histogramTwoBodySeedMass {this,
                                                               "two_body_seed_mass",
                                                               "m(TwoBodySeed)",
                                                               {100u, 0.f, Allen::mK}};
    Allen::Monitoring::Histogram<> m_histogramTwoBodySeedPt {this,
                                                             "two_body_seed_Pt",
                                                             "pT(TwoBodySeed)",
                                                             {100u, 0.f, 1e4}};
  };

} // namespace kplus_to_three_tracks_line

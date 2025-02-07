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
#include "OneTrackLine.cuh"
#include <ROOTService.h>

namespace rich_1_line {
  struct Parameters {
    // Commonly required inputs, outputs and properties
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;

    // Line-specific inputs and properties
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    // Monitoring
    DEVICE_OUTPUT(dev_decision_t, bool) dev_decision;
    HOST_OUTPUT(host_decision_t, bool) host_decision;

    DEVICE_OUTPUT(dev_pt_t, float) dev_pt;
    HOST_OUTPUT(host_pt_t, float) host_pt;

    DEVICE_OUTPUT(dev_p_t, float) dev_p;
    HOST_OUTPUT(host_p_t, float) host_p;

    DEVICE_OUTPUT(dev_track_chi2_t, float) dev_track_chi2;
    HOST_OUTPUT(host_track_chi2_t, float) host_track_chi2;

    DEVICE_OUTPUT(dev_eta_t, float) dev_eta;
    HOST_OUTPUT(host_eta_t, float) host_eta;

    DEVICE_OUTPUT(dev_phi_t, float) dev_phi;
    HOST_OUTPUT(host_phi_t, float) host_phi;
  };

  // SelectionAlgorithm definition
  struct rich_1_line_t : public SelectionAlgorithm, Parameters, OneTrackLine<rich_1_line_t, Parameters> {

    struct DeviceProperties {
      float minPt;
      float minP;
      float maxTrChi2;
      std::array<float, 1> minEta;
      std::array<float, 1> maxEta;
      std::array<float, 4> minPhi;
      std::array<float, 4> maxPhi;
      DeviceProperties(const rich_1_line_t& algo, const Allen::Context&) :
        minPt(algo.m_minPt), minP(algo.m_minP), maxTrChi2(algo.m_maxTrChi2), minEta(algo.m_minEta.value()),
        maxEta(algo.m_maxEta.value()), minPhi(algo.m_minPhi.value()), maxPhi(algo.m_maxPhi.value())
      {}
    };

    __device__ static __host__ KalmanFloat trackPhi(const Allen::Views::Physics::BasicParticle& track)
    {
      const auto state = track.state();
      return atan2f(state.py(), state.px());
    }

    // Selection function.
    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::BasicParticle> input);

    // Stuff for monitoring hists
    void init_tuples(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context) const;

    __device__ static void fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::BasicParticle> input,
      unsigned index,
      bool sel);

    void output_tuples(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Allen::Context& context) const;

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

  private:
    // Commonly required properties
    // RICH 1 Line-specific properties
    Allen::Property<float> m_minPt {this, "minPt", 500.0f / Gaudi::Units::MeV, "minPt description"};
    Allen::Property<float> m_minP {this, "minP", 30000.0f / Gaudi::Units::MeV, "minP description"};
    Allen::Property<float> m_maxTrChi2 {this, "maxTrChi2", 2.0f, "max track chi2"};

    Allen::Property<std::array<float, 1>> m_minEta {this, "minEta", {1.60}, "minimum pseudorapidity"};
    Allen::Property<std::array<float, 1>> m_maxEta {this, "maxEta", {2.04}, "maximum pseudorapidity"};
    Allen::Property<std::array<float, 4>> m_minPhi {this, "minPhi", {-2.65, -0.80, 0.50, 2.30}, "minimum azi angle"};
    Allen::Property<std::array<float, 4>> m_maxPhi {this, "maxPhi", {-2.30, -0.50, 0.80, 2.65}, "maximum azi angle"};
  };

} // namespace rich_1_line

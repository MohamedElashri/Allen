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

namespace rich_2_line {
  struct Parameters {
    // Commonly required inputs, outputs and properties
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
    DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
    DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
    DEVICE_OUTPUT(dev_decisions_t, bool) dev_decisions;
    DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned) dev_decisions_offsets;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_lhcbid_container_t, uint8_t) host_lhcbid_container;
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string)
    pre_scaler_hash_string;
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string)
    post_scaler_hash_string;

    MASK_OUTPUT(dev_selected_events_t) dev_selected_events;
    HOST_OUTPUT(host_selected_events_size_t, unsigned) host_selected_events_size;
    DEVICE_OUTPUT(dev_selected_events_size_t, unsigned) dev_selected_events_size;

    // Line-specific inputs and properties
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;
    HOST_OUTPUT(host_particle_container_t, Allen::Views::Physics::IMultiEventParticleContainer*) host_particle_container;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;

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

    PROPERTY(minPt_t, "minPt", "minPt description", float) minPt;
    PROPERTY(minP_t, "minP", "minP description", float) minP;
    PROPERTY(maxTrChi2_t, "maxTrChi2", "max track chi2", float) maxTrChi2;

    PROPERTY(minEta_t, "minEta", "minimum pseudorapidity", std::array<float, 1>) minEta;
    PROPERTY(maxEta_t, "maxEta", "maximum pseudorapidity", std::array<float, 1>) maxEta;
    PROPERTY(minPhi_t, "minPhi", "minimum azi angle", std::array<float, 4>) minPhi;
    PROPERTY(maxPhi_t, "maxPhi", "maximum azi angle", std::array<float, 4>) maxPhi;

    PROPERTY(make_tuple_t, "make_tuple", "Make tuple for monitoring", bool) make_tuple;
  };

  // SelectionAlgorithm definition
  struct rich_2_line_t : public SelectionAlgorithm, Parameters, OneTrackLine<rich_2_line_t, Parameters> {

    __device__ static __host__ KalmanFloat trackPhi(const Allen::Views::Physics::BasicParticle& track)
    {
      return atan2f(track.py(), track.px());
    }
    // Selection helper
    __device__ static bool passes(const Allen::Views::Physics::BasicParticle& track, const Parameters& parameters);

    // Selection function.
    __device__ static bool select(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::BasicParticle> input);

    // Stuff for monitoring hists
#ifdef WITH_ROOT
    static void init_monitor(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context);
    __device__ static void monitor(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::BasicParticle> input,
      unsigned index,
      bool sel);
    __host__ void output_monitor(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Allen::Context& context) const;
#endif

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

  private:
    // Commonly required properties
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, "hello"};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, "bye"};

    // RICH 2 Line-specific properties
    Property<minPt_t> m_minPt {this, 500.0f / Gaudi::Units::MeV};
    Property<minP_t> m_minP {this, 40000.0f / Gaudi::Units::MeV};
    Property<maxTrChi2_t> m_maxTrChi2 {this, 2.0f};

    Property<minEta_t> m_minEta {this, {2.65}};
    Property<maxEta_t> m_maxEta {this, {2.80}};
    Property<minPhi_t> m_minPhi {this, {-2.59, -0.65, 0.55, 2.49}};
    Property<maxPhi_t> m_maxPhi {this, {-2.49, -0.55, 0.65, 2.59}};

    // Switch to create monitoring tuple
    Property<make_tuple_t> m_make_tuple {this, false};
  };

} // namespace rich_2_line

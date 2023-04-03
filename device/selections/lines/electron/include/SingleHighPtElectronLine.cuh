/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "ParticleTypes.cuh"
#include "AlgorithmTypes.cuh"
#include "OneTrackLine.cuh"

namespace single_high_pt_electron_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_track_isElectron_t, bool) dev_track_isElectron;
    DEVICE_INPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;

    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(maxChi2Ndof_t, "maxChi2Ndof", "maxChi2Ndof description", float) maxChi2Ndof;
    PROPERTY(singleMinPt_t, "singleMinPt", "singleMinPt description", float) singleMinPt;
    PROPERTY(minZ_t, "MinZ", "Minimum track state z", float) minZ;

    DEVICE_OUTPUT(pt_corrected_t, float) pt_corrected;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;

    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
  };

  struct single_high_pt_electron_line_t : public SelectionAlgorithm,
                                          Parameters,
                                          OneTrackLine<single_high_pt_electron_line_t, Parameters> {
    __device__ static bool select(
      const Parameters& ps,
      std::tuple<const Allen::Views::Physics::BasicParticle, const bool, const float> input);

    __device__ static std::tuple<const Allen::Views::Physics::BasicParticle, const bool, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    __device__ static void monitor(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::BasicParticle, const bool, const float> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<pt_corrected_t, evtNo_t, runNo_t>;

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<maxChi2Ndof_t> m_maxChi2Ndof {this, 100.f};
    Property<singleMinPt_t> m_singleMinPt {this, 6000.f / Gaudi::Units::MeV};
    Property<minZ_t> m_minZ {this, -341.f * Gaudi::Units::mm};
    Property<enable_monitoring_t> m_enableMonitoring {this, false};
  };
} // namespace single_high_pt_electron_line

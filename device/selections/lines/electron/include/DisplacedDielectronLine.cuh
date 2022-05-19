/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "TwoTrackLine.cuh"

namespace displaced_dielectron_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // Kalman fitted tracks
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    // ECAL
    DEVICE_INPUT(dev_track_isElectron_t, bool) dev_track_isElectron;
    DEVICE_INPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
    // Outputs
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;

    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
    // Properties
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(MinIPChi2_t, "MinIPChi2", "Min IP Chi2", float) minIPChi2;
    PROPERTY(MaxDOCA_t, "MaxDOCA", "Max DOCA", float) maxDOCA;
    PROPERTY(MinPT_t, "MinPT", "Min PT", float) minPT;
    PROPERTY(MaxVtxChi2_t, "MaxVtxChi2", "Max vertex chi2", float) maxVtxChi2;
    PROPERTY(MinZ_t, "MinZ", "Min z dielectron coordinate", float) minZ;
  };

  struct displaced_dielectron_line_t : public SelectionAlgorithm,
                                       Parameters,
                                       TwoTrackLine<displaced_dielectron_line_t, Parameters> {
    __device__ static bool select(
      const Parameters&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const bool, const float>);

    __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, const bool, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    // Displaced dielectron selections.
    Property<MinIPChi2_t> m_MinIPChi2 {this, 7.4f};
    Property<MaxDOCA_t> m_MaxDOCA {this, 0.082f};
    Property<MinPT_t> m_MinPT {this, 500.f};
    Property<MaxVtxChi2_t> m_MaxVtxChi2 {this, 7.4f};
    Property<MinZ_t> m_MinZ {this, -300.f * Gaudi::Units::mm};
  };
} // namespace displaced_dielectron_line

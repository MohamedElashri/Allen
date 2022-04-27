/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "EventLine.cuh"
#include "ParticleTypes.cuh"

namespace displaced_leptons_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // TODO: For now, this is called a "track" container instead of a "particle"
    // container to trick the SelReport writer into not looking for individual
    // selected candidates. This line needs to be reworked to save individual
    // candidate information to the SelReport.
    DEVICE_INPUT(dev_track_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_track_container;
    DEVICE_INPUT(dev_track_isElectron_t, bool) dev_track_isElectron;
    DEVICE_INPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
    DEVICE_OUTPUT(dev_particle_container_ptr_t, Allen::IMultiEventContainer*) dev_particle_container_ptr;
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(min_ipchi2_t, "min_ipchi2", "Minimum ipchi2", float) min_ipchi2;
    PROPERTY(min_pt_t, "min_pt", "Minimum pt", float) min_pt;
  };

  struct displaced_leptons_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    EventLine<displaced_leptons_line_t, Parameters> {
    __device__ static std::tuple<const Allen::Views::Physics::BasicParticles, const unsigned, const bool*, const float*>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned);

    __device__ static bool select(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::BasicParticles, const unsigned, const bool*, const float*> input);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<min_ipchi2_t> m_min_ipchi2 {this, 7.4f};
    Property<min_pt_t> m_min_pt {this, 1000.f};
  };
} // namespace displaced_leptons_line
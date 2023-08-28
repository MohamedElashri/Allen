/*****************************************************************************\
 * (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
 \*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "Line.cuh"

namespace t_track_cosmic_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_seeding_tracks_t, SciFi::Seeding::Track) dev_seeding_tracks;
    DEVICE_INPUT(dev_seeding_offsets_t, unsigned) dev_seeding_offsets;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(max_chi2X_t, "max_chi2X", "Max value of chi2X", float) max_chi2X;
    PROPERTY(max_chi2Y_t, "max_chi2Y", "Max value of chi2Y", float) max_chi2Y;
  };

  struct t_track_cosmic_line_t : public SelectionAlgorithm, Parameters, Line<t_track_cosmic_line_t, Parameters> {

    __device__ static bool select(const Parameters& ps, std::tuple<const SciFi::Seeding::Track> input);

    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_seeding_offsets[event_number];
    }

    __device__ static std::tuple<const SciFi::Seeding::Track>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
    {
      const SciFi::Seeding::Track event_scifi_track =
        parameters.dev_seeding_tracks[event_number * SciFi::Constants::Nmax_seeds + i];
      return std::forward_as_tuple(event_scifi_track);
    }

    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments)
    {
      return first<host_number_of_reconstructed_scifi_tracks_t>(arguments);
    }

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<max_chi2X_t> m_max_chi2X {this, 0.26f};  // 95 percentile of chi2X distribution
    Property<max_chi2Y_t> m_max_chi2Y {this, 134.0f}; // 95 percentile of chi2Y distribution
  };
} // namespace t_track_cosmic_line

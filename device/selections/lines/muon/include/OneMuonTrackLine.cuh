/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "Line.cuh"
#include "MuonDefinitions.cuh"

namespace one_muon_track_line {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_muon_total_number_of_tracks_t, unsigned) host_muon_total_number_of_tracks;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_muon_tracks_t, MuonTrack) dev_muon_tracks;
    DEVICE_INPUT(dev_muon_tracks_offsets_t, unsigned) dev_muon_tracks_offsets;
    DEVICE_INPUT(dev_muon_number_of_tracks_t, unsigned) dev_muon_number_of_tracks;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(max_chi2x_t, "max_chi2x", "Maximum chi2 for the xz plane", float) max_chi2x;
    PROPERTY(max_chi2y_t, "max_chi2y", "Maximum chi2 for the yz plane", float) max_chi2y;
  };

  struct one_muon_track_line_t : public SelectionAlgorithm, Parameters, Line<one_muon_track_line_t, Parameters> {

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const;

    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_muon_tracks_offsets[event_number];
    }

    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments)
    {
      return first<typename Parameters::host_muon_total_number_of_tracks_t>(arguments);
    }

    __device__ static std::tuple<const MuonTrack>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
    {
      const auto muon_tracks_offsets = parameters.dev_muon_tracks_offsets;
      const auto muon_tracks = parameters.dev_muon_tracks;

      const unsigned track_index = i + muon_tracks_offsets[event_number];

      return std::forward_as_tuple(muon_tracks[track_index]);
    }

    __device__ static unsigned input_size(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_muon_number_of_tracks[event_number];
    }

    __device__ static bool select(const Parameters& parameters, std::tuple<const MuonTrack> input);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<max_chi2x_t> m_max_chi2x {this, 1.f};
    Property<max_chi2y_t> m_max_chi2y {this, 0.3f};
  };
} // namespace one_muon_track_line

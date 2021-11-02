/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "Line.cuh"
#include "TwoTrackLine.cuh"

namespace two_track_catboost_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_svs_t, VertexFit::TrackMVAVertex) dev_svs;
    DEVICE_INPUT(dev_two_track_evaluation_t, float) dev_two_track_evaluation;
    DEVICE_INPUT(dev_sv_offsets_t, unsigned) dev_sv_offsets;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_selected_events_t) dev_selected_events;
    HOST_OUTPUT(host_selected_events_size_t, unsigned) host_selected_events_size;
    DEVICE_OUTPUT(dev_selected_events_size_t, unsigned) dev_selected_events_size;
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
    PROPERTY(minMVA_t, "minMVA", "Minimum passing MVA response.", float) minMVA;
    PROPERTY(minPt_t, "minPt", "Minimum track pT in MeV.", float) minPt;
    PROPERTY(minEta_t, "minEta", "Minimum PV-SV eta.", float) minEta;
    PROPERTY(maxEta_t, "maxEta", "Maximum PV-SV eta.", float) maxEta;
    PROPERTY(minMcor_t, "minMcor", "Minimum corrected mass in MeV", float) minMcor;
  };

  struct two_track_catboost_line_t : public SelectionAlgorithm,
                                     Parameters,
                                     Line<two_track_catboost_line_t, Parameters> {

    constexpr static auto lhcbid_container = LHCbIDContainer::sv;

    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number);

    static unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments);

    __device__ static std::tuple<const VertexFit::TrackMVAVertex&, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    __device__ static bool select(
      const Parameters& parameters,
      std::tuple<const VertexFit::TrackMVAVertex&, const float> input);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    // Just a guess for now.
    Property<minMVA_t> m_minMVA {this, 0.10f};
    Property<minPt_t> m_minPt {this, 500.f};
    Property<minEta_t> m_minEta {this, 2.f};
    Property<maxEta_t> m_maxEta {this, 5.f};
    Property<minMcor_t> m_minMcor {this, 1000.f};
  };

} // namespace two_track_catboost_line

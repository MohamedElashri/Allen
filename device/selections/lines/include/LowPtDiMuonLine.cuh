/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "SelectionAlgorithm.cuh"
#include "TwoTrackLine.cuh"

namespace low_pt_di_muon_line {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_number_of_svs_t, unsigned), host_number_of_svs),
    (DEVICE_INPUT(dev_svs_t, VertexFit::TrackMVAVertex), dev_svs),
    (DEVICE_INPUT(dev_sv_offsets_t, unsigned), dev_sv_offsets),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_odin_raw_input_t, char), dev_odin_raw_input),
    (DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned), dev_odin_raw_input_offsets),
    (DEVICE_INPUT(dev_mep_layout_t, unsigned), dev_mep_layout),
    (DEVICE_OUTPUT(dev_decisions_t, bool), dev_decisions),
    (DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned), dev_decisions_offsets),
    (HOST_OUTPUT(host_post_scaler_t, float), host_post_scaler),
    (HOST_OUTPUT(host_post_scaler_hash_t, uint32_t), host_post_scaler_hash),
    (PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float), pre_scaler),
    (PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float), post_scaler),
    (PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string),
     pre_scaler_hash_string),
    (PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string),
     post_scaler_hash_string),
    (PROPERTY(minTrackIP_t, "minTrackIP", "minTrackIP description", float), minTrackIP),
    (PROPERTY(minTrackPt_t, "minTrackPt", "minTrackPt description", float), minTrackPt),
    (PROPERTY(minTrackP_t, "minTrackP", "minTrackP description", float), minTrackP),
    (PROPERTY(minTrackIPChi2_t, "minTrackIPChi2", "minTrackIPChi2 description", float), minTrackIPChi2),
    (PROPERTY(maxDOCA_t, "maxDOCA", "maxDOCA description", float), maxDOCA),
    (PROPERTY(maxVertexChi2_t, "maxVertexChi2", "maxVertexChi2 description", float), maxVertexChi2),
    (PROPERTY(minMass_t, "minMass", "minMass description", float), minMass))

  struct low_pt_di_muon_line_t : public SelectionAlgorithm,
                                 Parameters,
                                 TwoTrackLine<low_pt_di_muon_line_t, Parameters> {
    __device__ bool select(const Parameters&, std::tuple<const VertexFit::TrackMVAVertex&>) const;

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minTrackIP_t> m_minTrackIP {this, 0.1f};
    Property<minTrackPt_t> m_minTrackPt {this, 80.f};
    Property<minTrackP_t> m_minTrackP {this, 3000.f};
    Property<minTrackIPChi2_t> m_minTrackIPChi2 {this, 1.f};
    Property<maxDOCA_t> m_maxDOCA {this, 0.2f};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 25.f};
    Property<minMass_t> m_minMass {this, 220.f};
  };
} // namespace low_pt_di_muon_line

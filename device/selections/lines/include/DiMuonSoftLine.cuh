/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "SelectionAlgorithm.cuh"
#include "TwoTrackLine.cuh"

namespace di_muon_soft_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_svs_t, VertexFit::TrackMVAVertex) dev_svs;
    DEVICE_INPUT(dev_sv_offsets_t, unsigned) dev_sv_offsets;
    DEVICE_INPUT(dev_event_list_t, unsigned) dev_event_list;
    DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
    DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
    DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
    DEVICE_OUTPUT(dev_decisions_t, bool) dev_decisions;
    DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned) dev_decisions_offsets;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(DMSoftM0_t, "DMSoftM0", "DMSoftM0 description", float) DMSoftM0;
    PROPERTY(DMSoftM1_t, "DMSoftM1", "DMSoftM1 description", float) DMSoftM1;
    PROPERTY(DMSoftM2_t, "DMSoftM2", "DMSoftM2 description", float) DMSoftM2;
    PROPERTY(DMSoftMinIPChi2_t, "DMSoftMinIPChi2", "DMSoftMinIPChi2 description", float) DMSoftMinIPChi2;
    PROPERTY(DMSoftMinRho2_t, "DMSoftMinRho2", "DMSoftMinRho2 description", float) DMSoftMinRho2;
    PROPERTY(DMSoftMinZ_t, "DMSoftMinZ", "DMSoftMinZ description", float) DMSoftMinZ;
    PROPERTY(DMSoftMaxZ_t, "DMSoftMaxZ", "DMSoftMaxZ description", float) DMSoftMaxZ;
    PROPERTY(DMSoftMaxDOCA_t, "DMSoftMaxDOCA", "DMSoftMaxDOCA description", float) DMSoftMaxDOCA;
    PROPERTY(DMSoftMaxIPDZ_t, "DMSoftMaxIPDZ", "DMSoftMaxIPDZ description", float) DMSoftMaxIPDZ;
    PROPERTY(DMSoftGhost_t, "DMSoftGhost", "DMSoftGhost description", float) DMSoftGhost;
  };

  struct di_muon_soft_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<di_muon_soft_line_t, Parameters> {
    __device__ bool select(const Parameters&, std::tuple<const VertexFit::TrackMVAVertex&>) const;

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<DMSoftM0_t> m_DMSoftM0 {this, 400.f};
    Property<DMSoftM1_t> m_DMSoftM1 {this, 475.f};
    Property<DMSoftM2_t> m_DMSoftM2 {this, 600.f};
    Property<DMSoftMinIPChi2_t> m_DMSoftMinIPChi2 {this, 100.f};
    Property<DMSoftMinRho2_t> m_DMSoftMinRho2 {this, 9.f};
    Property<DMSoftMinZ_t> m_DMSoftMinZ {this, -375.f};
    Property<DMSoftMaxZ_t> m_DMSoftMaxZ {this, 635.f};
    Property<DMSoftMaxDOCA_t> m_DMSoftMaxDOCA {this, 0.1f};
    Property<DMSoftMaxIPDZ_t> m_DMSoftMaxIPDZ {this, 0.04f};
    Property<DMSoftGhost_t> m_DMSoftGhost {this, 4.e-06f};
  };
} // namespace di_muon_soft_line

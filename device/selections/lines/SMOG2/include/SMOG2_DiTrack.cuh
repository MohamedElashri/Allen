/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "SelectionAlgorithm.cuh"
#include "TwoTrackLine.cuh"

namespace SMOG2_ditrack_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_svs_t, VertexFit::TrackMVAVertex) dev_svs;
    DEVICE_INPUT(dev_sv_offsets_t, unsigned) dev_sv_offsets;
    MASK_INPUT(dev_event_list_t) dev_event_list;
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

    //SMOG2_DITRACK CUTS
    PROPERTY(minTrackP_t, "minTrackP", "minimum daughters momentum", float) minTrackP;
    PROPERTY(minTrackPt_t, "minTrackPt", "minimum daughters transverse momentum", float) minTrackPt;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "maxVertexChi2 description", float) maxVertexChi2;
    PROPERTY(maxDoca_t, "maxDoca", "max distance of closest approach", float) maxDoca;
    PROPERTY(minPocaZ_t, "minPocaZ", "minimum z for the track poca to the beam line", float) minPocaZ;
    PROPERTY(maxPocaZ_t, "maxPocaZ", "maximum z for the track poca to the beam line", float) maxPocaZ;
    PROPERTY(combCharge_t, "combCharge", "Charge of the combination", int) combCharge;
    PROPERTY(m1_t, "m1", "first daughter mass", float) m1;
    PROPERTY(m2_t, "m2", "second daughter mass", float) m2;
    PROPERTY(mMother_t, "mMother", "resonance mass", float) mMother;
    PROPERTY(massWindow_t, "massWindow", "maximum mass difference wrt mM", float) massWindow;
  };

  struct SMOG2_ditrack_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<SMOG2_ditrack_line_t, Parameters> {
    __device__ static bool select(const Parameters& parameters, std::tuple<const VertexFit::TrackMVAVertex&> input);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};

    Property<minTrackP_t> m_minTrackP {this, 3.f / Gaudi::Units::GeV};
    Property<minTrackPt_t> m_minTrackPt {this, 400.f / Gaudi::Units::MeV};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 25.f};
    Property<minPocaZ_t> m_minPocaZ {this, -500.f / Gaudi::Units::mm};
    Property<maxPocaZ_t> m_maxPocaZ {this, -300.f / Gaudi::Units::mm};
    Property<maxDoca_t> m_maxDoca {this, 0.5f / Gaudi::Units::mm};
    Property<combCharge_t> m_combCharge {this, 0};
    Property<m1_t> m_m1 {this, -1.f / Gaudi::Units::MeV};
    Property<m2_t> m_m2 {this, -1.f / Gaudi::Units::MeV};
    Property<mMother_t> m_mMother {this, -1.f / Gaudi::Units::MeV};
    Property<massWindow_t> m_massWindow {this, -1.f / Gaudi::Units::MeV};
  };
} // namespace SMOG2_ditrack_line

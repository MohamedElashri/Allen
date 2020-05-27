/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "DeviceAlgorithm.cuh"
#include "TwoTrackLine.cuh"

namespace two_track_mva_line {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_number_of_svs_t, unsigned), host_number_of_svs),
    (DEVICE_INPUT(dev_svs_t, VertexFit::TrackMVAVertex), dev_svs),
    (DEVICE_INPUT(dev_sv_offsets_t, unsigned), dev_sv_offsets),
    (DEVICE_OUTPUT(dev_decisions_t, bool), dev_decisions),
    (PROPERTY(minComboPt_t, "minComboPt", "minComboPt description", float), minComboPt),
    (PROPERTY(maxVertexChi2_t, "maxVertexChi2", "maxVertexChi2 description", float), maxVertexChi2),
    (PROPERTY(minMCor_t, "minMCor", "minMCor description", float), minMCor),
    (PROPERTY(minEta_t, "minEta", "minEta description", float), minEta),
    (PROPERTY(maxEta_t, "maxEta", "maxEta description", float), maxEta),
    (PROPERTY(minTrackPt_t, "minTrackPt", "minTrackPt description", float), minTrackPt),
    (PROPERTY(maxNTrksAssoc_t, "maxNTrksAssoc", "maxNTrksAssoc description", int), maxNTrksAssoc), // Placeholder. To be replaced with MVA selection.
    (PROPERTY(minFDChi2_t, "minFDChi2", "minFDChi2 description", float), minFDChi2), // Placeholder. To be replaced with MVA selection.
    (PROPERTY(minTrackIPChi2_t, "minTrackIPChi2", "minTrackIPChi2 description", float), minTrackIPChi2))

  struct two_track_mva_line_t : public DeviceAlgorithm, Parameters, TwoTrackLine<two_track_mva_line_t, Parameters> {
    __device__ bool select(const Parameters&, std::tuple<const VertexFit::TrackMVAVertex&>) const;

  private:
    Property<minComboPt_t> m_minComboPt {this, 2000.0f / Gaudi::Units::MeV};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 25.0f};
    Property<minMCor_t> m_minMCor {this, 1000.0f / Gaudi::Units::MeV};
    Property<minEta_t> m_minEta {this, 2.0f};
    Property<maxEta_t> m_maxEta {this, 5.0f};
    Property<minTrackPt_t> m_minTrackPt {this, 700.f / Gaudi::Units::MeV};
    Property<maxNTrksAssoc_t> m_maxNTrksAssoc {this, 1};
    Property<minFDChi2_t> m_minFDChi2 {this, 0.0f};
    Property<minTrackIPChi2_t> m_minTrackIPChi2 {this, 12.f};
  };
} // namespace two_track_mva_line

/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/Track.h"

// Allen
#include "Logger.h"
#include "ParKalmanDefinitions.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiConsolidated.cuh"

#include <AIDA/IHistogram1D.h>

class GaudiAllenForwardToV2Tracks final : public Gaudi::Functional::Transformer<
                                            std::vector<LHCb::Event::v2::Track>(
                                              const std::vector<unsigned>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<char>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<char>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<float>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<char>&,
                                              const std::vector<unsigned>&,
                                              const std::vector<float>&,
                                              const std::vector<MiniState>&,
                                              const std::vector<ParKalmanFilter::FittedTrack>&),
                                            Gaudi::Functional::Traits::BaseClass_t<GaudiHistoAlg>> {

public:
  /// Standard constructor
  GaudiAllenForwardToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator);

  /// initialization
  StatusCode initialize() override;

  /// Algorithm execution
  std::vector<LHCb::Event::v2::Track> operator()(
    const std::vector<unsigned>& allen_offsets_all_velo_tracks,
    const std::vector<unsigned>& allen_offsets_velo_track_hit_number,
    const std::vector<char>& allen_velo_track_hits,
    const std::vector<unsigned>& allen_atomics_ut,
    const std::vector<unsigned>& allen_ut_track_hit_number,
    const std::vector<char>& allen_ut_track_hits,
    const std::vector<unsigned>& allen_ut_track_velo_indices,
    const std::vector<float>& allen_ut_qop,
    const std::vector<unsigned>& allen_atomics_scifi,
    const std::vector<unsigned>& allen_scifi_track_hit_number,
    const std::vector<char>& allen_scifi_track_hits,
    const std::vector<unsigned>& allen_scifi_track_ut_indices,
    const std::vector<float>& allen_scifi_qop,
    const std::vector<MiniState>& allen_scifi_states,
    const std::vector<ParKalmanFilter::FittedTrack>& allen_kf_tracks) const override;

private:
  const std::array<float, 5> m_default_covarianceValues {4.0, 400.0, 4.e-6, 1.e-4, 0.1};
  Gaudi::Property<std::array<float, 5>> m_covarianceValues {this, "COVARIANCEVALUES", m_default_covarianceValues};

  std::unordered_map<std::string, AIDA::IHistogram1D*> m_histos;
};

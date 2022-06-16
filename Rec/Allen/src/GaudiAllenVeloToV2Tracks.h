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
#include "VeloConsolidated.cuh"

class GaudiAllenVeloToV2Tracks final : public Gaudi::Functional::Transformer<std::vector<LHCb::Event::v2::Track>(
                                         const std::vector<unsigned>&,
                                         const std::vector<unsigned>&,
                                         const std::vector<char>&,
                                         const std::vector<char>&)> {
public:
  /// Standard constructor
  GaudiAllenVeloToV2Tracks(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  std::vector<LHCb::Event::v2::Track> operator()(
    const std::vector<unsigned>& allen_velo_track_atomics,
    const std::vector<unsigned>& allen_velo_track_offsets,
    const std::vector<char>& allen_velo_track_hits,
    const std::vector<char>& allen_velo_kalman_states) const override;

private:
  Gaudi::Property<float> m_ptVelo {this, "ptVelo", 400 * Gaudi::Units::MeV, "Default pT for Velo tracks"};
};

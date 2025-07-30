/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "AlgorithmTypes.cuh"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "FloatOperations.cuh"
#include <cstdint>

namespace pv_beamline_multi_fitter {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_pvtracks_t, PVTrack) dev_pvtracks;
    DEVICE_INPUT(dev_pvtracks_denom_t, float) dev_pvtracks_denom;
    DEVICE_INPUT(dev_zpeaks_t, float) dev_zpeaks;
    DEVICE_INPUT(dev_number_of_zpeaks_t, unsigned) dev_number_of_zpeaks;
    DEVICE_OUTPUT(dev_multi_fit_vertices_t, PV::Vertex) dev_multi_fit_vertices;
    DEVICE_OUTPUT(dev_number_of_multi_fit_vertices_t, unsigned) dev_number_of_multi_fit_vertices;
  };

  __global__ void pv_beamline_multi_fitter(
    Parameters,
    const float SMOG2_pp_separation,
    const unsigned SMOG2_minNumTracksPerVertex,
    const unsigned pp_minNumTracksPerVertex,
    const unsigned maxFitIter,
    const float zmin,
    const float zmax,
    const float maxChi2,
    const float chi2CutExp,
    const float minWeight,
    const float maxDeltaZConverged,
    const float maxVertexRho2);

  struct pv_beamline_multi_fitter_t : public DeviceAlgorithm, Parameters {
    void update(const Constants& constants) const;

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;
    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<unsigned> m_block_dim_y {this, "block_dim_y", 4, "block dimension Y"};
    Allen::Property<float> m_zmin {this, "zmin", BeamlinePVConstants::Common::zmin, "Minimum histogram z"};
    Allen::Property<float> m_zmax {this, "zmax", BeamlinePVConstants::Common::zmax, "Maximum histogram z"};
    Allen::Property<float> m_SMOG2_pp_separation {this,
                                                  "SMOG2_pp_separation",
                                                  BeamlinePVConstants::Common::SMOG2_pp_separation,
                                                  "z separation between the pp and SMOG2 luminous region"};
    Allen::Property<unsigned> m_SMOG2_minNumTracksPerVertex {
      this,
      "SMOG2_minNumTracksPerVertex",
      BeamlinePVConstants::MultiFitter::SMOG2_minNumTracksPerVertex,
      "Min number of tracks to accpet a SMOG2 vertex"};
    Allen::Property<unsigned> m_pp_minNumTracksPerVertex {this,
                                                          "pp_minNumTracksPerVertex",
                                                          BeamlinePVConstants::MultiFitter::pp_minNumTracksPerVertex,
                                                          "Min number of tracks to accpet a pp vertex"};
    Allen::Property<float> m_maxVertexRho2 {this,
                                            "maxVertexRho2",
                                            BeamlinePVConstants::MultiFitter::maxVertexRho2,
                                            "Maximum vertex Rho2"};
    Allen::Property<unsigned> m_maxFitIter {this,
                                            "maxFitIter",
                                            BeamlinePVConstants::MultiFitter::maxFitIter,
                                            "maximum fit iteration"};
    Allen::Property<float> m_chi2CutExp {this,
                                         "chi2CutExp",
                                         BeamlinePVConstants::MultiFitter::chi2CutExp,
                                         "chi2 cut exp"};
    Allen::Property<float> m_minWeight {this,
                                        "minWeight",
                                        BeamlinePVConstants::MultiFitter::minWeight,
                                        "Minimum weight"};
    Allen::Property<float> m_maxChi2 {this, "maxChi2", BeamlinePVConstants::MultiFitter::maxChi2, "Maximum chi2"};
    Allen::Property<float> m_maxDeltaZConverged {this,
                                                 "maxDeltaZConverged",
                                                 BeamlinePVConstants::MultiFitter::maxDeltaZConverged,
                                                 "Max deltaz in fit convergence"};
  };
} // namespace pv_beamline_multi_fitter

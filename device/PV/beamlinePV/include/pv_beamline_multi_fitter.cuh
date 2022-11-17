/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
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
    PROPERTY(block_dim_y_t, "block_dim_y", "block dimension Y", unsigned) block_dim_y;

    PROPERTY(zmin_t, "zmin", "Minimum histogram z", float) zmin;
    PROPERTY(zmax_t, "zmax", "Maximum histogram z", float) zmax;
    PROPERTY(
      SMOG2_pp_separation_t,
      "SMOG2_pp_separation",
      "z separation between the pp and SMOG2 luminous region",
      float)
    SMOG2_pp_separation;
    PROPERTY(
      SMOG2_minNumTracksPerVertex_t,
      "SMOG2_minNumTracksPerVertex",
      "Min number of tracks to accpet a SMOG2 vertex",
      float)
    SMOG2_minNumTracksPerVertex;
    PROPERTY(
      pp_minNumTracksPerVertex_t,
      "pp_minNumTracksPerVertex",
      "Min number of tracks to accpet a SMOG2 vertex",
      float)
    pp_minNumTracksPerVertex;
    PROPERTY(maxVertexRho2_t, "maxVertexRho2", "Maximum vertex Rho2", float) maxVertexRho2;
    PROPERTY(minFitIter_t, "minFitIter", "minimum fit iteration", float) minFitIter;
    PROPERTY(maxFitIter_t, "maxFitIter", "maximum fit iteration", float) maxFitIter;
    PROPERTY(chi2CutExp_t, "chi2CutExp", "chi2 cut exp", float) chi2CutExp;
    PROPERTY(maxChi2_t, "maxChi2", "Maximum chi2", float) maxChi2;
    PROPERTY(minWeight_t, "minWeight", "Minimum weight", float) minWeight;
    PROPERTY(maxDeltaZConverged_t, "maxDeltaZConverged", "Max deltaz in fit convergence", float) maxDeltaZConverged;
  };

  __global__ void pv_beamline_multi_fitter(Parameters, const float* dev_beamline);

  struct pv_beamline_multi_fitter_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_y_t> m_block_dim_y {this, 4};
    Property<zmin_t> m_zmin {this, BeamlinePVConstants::Common::zmin};
    Property<zmax_t> m_zmax {this, BeamlinePVConstants::Common::zmax};
    Property<SMOG2_pp_separation_t> m_SMOG2_pp_separation {this, BeamlinePVConstants::Common::SMOG2_pp_separation};
    Property<SMOG2_minNumTracksPerVertex_t> m_SMOG2_minNumTracksPerVertex {
      this,
      BeamlinePVConstants::MultiFitter::SMOG2_minNumTracksPerVertex};
    Property<pp_minNumTracksPerVertex_t> m_pp_minNumTracksPerVertex {
      this,
      BeamlinePVConstants::MultiFitter::pp_minNumTracksPerVertex};
    Property<maxVertexRho2_t> m_maxVertexRho2 {this, BeamlinePVConstants::MultiFitter::maxVertexRho2};
    Property<minFitIter_t> m_minFitIter {this, BeamlinePVConstants::MultiFitter::minFitIter};
    Property<maxFitIter_t> m_maxFitIter {this, BeamlinePVConstants::MultiFitter::maxFitIter};
    Property<chi2CutExp_t> m_chi2CutExp {this, BeamlinePVConstants::MultiFitter::chi2CutExp};
    Property<minWeight_t> m_minWeight {this, BeamlinePVConstants::MultiFitter::minWeight};
    Property<maxChi2_t> m_maxChi2 {this, BeamlinePVConstants::MultiFitter::maxChi2};
    Property<maxDeltaZConverged_t> m_maxDeltaZConverged {this, BeamlinePVConstants::MultiFitter::maxDeltaZConverged};
  };
} // namespace pv_beamline_multi_fitter

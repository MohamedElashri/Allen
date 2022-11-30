/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdint>
#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "patPV_Definitions.cuh"
#include "AlgorithmTypes.cuh"
#include "FloatOperations.cuh"

namespace pv_beamline_histo {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_pvtracks_t, PVTrack) dev_pvtracks;
    DEVICE_OUTPUT(dev_zhisto_t, float) dev_zhisto;

    PROPERTY(zmin_t, "zmin", "Minimum histogram z", float) zmin;
    PROPERTY(zmax_t, "zmax", "Maximum histogram z", float) zmax;
    PROPERTY(dz_t, "dz", "Histogram bin width", float) dz;
    PROPERTY(Nbins_t, "Nbins", "Number of histogram bins (zmax - zmin)/dz", int) Nbins;
    PROPERTY(order_polynomial_t, "order_polynomial", "order of the polynomial in the PV fit", int) order_polynomial;
    PROPERTY(maxTrackBlChi2_t, "maxTrackBlChi2", "Maximum chi2 for track beamline extrapolation", float) maxTrackBlChi2;
    PROPERTY(
      SMOG2_pp_separation_t,
      "SMOG2_pp_separation",
      "z separation between the pp and SMOG2 luminous region",
      float)
    SMOG2_pp_separation;
    PROPERTY(SMOG2_maxTrackZ0Err_t, "SMOG2_maxTrackZ0Err", "Maximum error for z0 extrapolation", float)
    SMOG2_maxTrackZ0Err;
    PROPERTY(pp_maxTrackZ0Err_t, "pp_maxTrackZ0Err", "Maximum error for z0 extrapolation", float) pp_maxTrackZ0Err;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void pv_beamline_histo(Parameters, float* dev_beamline);

  struct pv_beamline_histo_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};
    Property<zmin_t> m_zmin {this, BeamlinePVConstants::Common::zmin};
    Property<zmax_t> m_zmax {this, BeamlinePVConstants::Common::zmax};
    Property<dz_t> m_dz {this, BeamlinePVConstants::Common::dz};
    Property<Nbins_t> m_Nbins {this, BeamlinePVConstants::Common::Nbins};
    Property<order_polynomial_t> m_order_polynomial {this, BeamlinePVConstants::Histo::order_polynomial};
    Property<maxTrackBlChi2_t> m_maxTrackBlChi2 {this, BeamlinePVConstants::Histo::maxTrackBLChi2};
    Property<SMOG2_pp_separation_t> m_SMOG2_pp_separation {this, BeamlinePVConstants::Common::SMOG2_pp_separation};
    Property<SMOG2_maxTrackZ0Err_t> m_SMOG2_maxTrackZ0Err {this, BeamlinePVConstants::Common::SMOG2_maxTrackZ0Err};
    Property<pp_maxTrackZ0Err_t> m_pp_maxTrackZ0Err {this, BeamlinePVConstants::Common::pp_maxTrackZ0Err};
  };
} // namespace pv_beamline_histo

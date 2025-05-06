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
  };

  __global__ void pv_beamline_histo(
    Parameters,
    const int Nbins,
    const float zmin,
    const float zmax,
    const float maxTrackBlChi2,
    const float dz,
    const float SMOG2_pp_separation,
    const float SMOG2_maxTrackZ0Err,
    const float pp_maxTrackZ0Err,
    const int order_polynomial);

  struct pv_beamline_histo_t : public DeviceAlgorithm, Parameters {
    void update(const Constants& constants) const;

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;
    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};
    Allen::Property<float> m_zmin {this, "zmin", BeamlinePVConstants::Common::zmin, "Minimum histogram z"};
    Allen::Property<float> m_zmax {this, "zmax", BeamlinePVConstants::Common::zmax, "Maximum histogram z"};
    Allen::Property<float> m_dz {this, "dz", BeamlinePVConstants::Common::dz, "Histogram bin width"};
    Allen::Property<int> m_Nbins {this,
                                  "Nbins",
                                  BeamlinePVConstants::Common::Nbins,
                                  "Number of histogram bins (zmax - zmin)/dz"};
    Allen::Property<int> m_order_polynomial {this,
                                             "order_polynomial",
                                             BeamlinePVConstants::Histo::order_polynomial,
                                             "order of the polynomial in the PV fit"};
    Allen::Property<float> m_maxTrackBlChi2 {this,
                                             "maxTrackBlChi2",
                                             BeamlinePVConstants::Histo::maxTrackBLChi2,
                                             "Maximum chi2 for track beamline extrapolation"};
    Allen::Property<float> m_SMOG2_pp_separation {this,
                                                  "SMOG2_pp_separation",
                                                  BeamlinePVConstants::Common::SMOG2_pp_separation,
                                                  "z separation between the pp and SMOG2 luminous region"};
    Allen::Property<float> m_SMOG2_maxTrackZ0Err {this,
                                                  "SMOG2_maxTrackZ0Err",
                                                  BeamlinePVConstants::Common::SMOG2_maxTrackZ0Err,
                                                  "Maximum error for z0 extrapolation"};
    Allen::Property<float> m_pp_maxTrackZ0Err {this,
                                               "pp_maxTrackZ0Err",
                                               BeamlinePVConstants::Common::pp_maxTrackZ0Err,
                                               "Maximum error for z0 extrapolation"};
  };
} // namespace pv_beamline_histo

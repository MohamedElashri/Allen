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

namespace pv_beamline_calculate_denom {
  struct Parameters {
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_pvtracks_t, PVTrack) dev_pvtracks;
    DEVICE_INPUT(dev_zpeaks_t, float) dev_zpeaks;
    DEVICE_INPUT(dev_number_of_zpeaks_t, unsigned) dev_number_of_zpeaks;
    DEVICE_OUTPUT(dev_pvtracks_denom_t, float) dev_pvtracks_denom;
  };

  __global__ void pv_beamline_calculate_denom(Parameters);

  struct pv_beamline_calculate_denom_t : public DeviceAlgorithm, Parameters {
    void update(const Constants& constants) const;

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;
    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
  };
} // namespace pv_beamline_calculate_denom

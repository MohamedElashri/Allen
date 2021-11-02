/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Common.h"
#include "AlgorithmTypes.cuh"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "patPV_Definitions.cuh"
#include "FloatOperations.cuh"
#include "States.cuh"
#include <cstdint>

namespace pv_beamline_extrapolate {
  struct Parameters {
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Velo::Consolidated::States) dev_velo_states_view;
    DEVICE_OUTPUT(dev_pvtracks_t, PVTrack) dev_pvtracks;
    DEVICE_OUTPUT(dev_pvtrack_z_t, float) dev_pvtrack_z;
    DEVICE_OUTPUT(dev_pvtrack_unsorted_z_t, float) dev_pvtrack_unsorted_z;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void pv_beamline_extrapolate(Parameters);

  struct pv_beamline_extrapolate_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace pv_beamline_extrapolate

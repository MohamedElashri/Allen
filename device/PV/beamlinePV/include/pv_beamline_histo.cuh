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
#include "DeviceAlgorithm.cuh"
#include "FloatOperations.cuh"

namespace pv_beamline_histo {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_atomics_velo),
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (DEVICE_INPUT(dev_pvtracks_t, PVTrack), dev_pvtracks),
    (DEVICE_OUTPUT(dev_zhisto_t, float), dev_zhisto),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void pv_beamline_histo(Parameters, float* dev_beamline);

  struct pv_beamline_histo_t : public DeviceAlgorithm, Parameters {
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
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};
  };
} // namespace pv_beamline_histo
/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "FloatOperations.cuh"
#include <cstdint>

namespace pv_beamline_multi_fitter {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned), host_number_of_reconstructed_velo_tracks),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_number_of_events_t, unsigned), dev_number_of_events),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_atomics_velo),
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (DEVICE_INPUT(dev_pvtracks_t, PVTrack), dev_pvtracks),
    (DEVICE_INPUT(dev_pvtracks_denom_t, float), dev_pvtracks_denom),
    (DEVICE_INPUT(dev_zpeaks_t, float), dev_zpeaks),
    (DEVICE_INPUT(dev_number_of_zpeaks_t, unsigned), dev_number_of_zpeaks),
    (DEVICE_INPUT(dev_pvtrack_z_t, float), dev_pvtrack_z),
    (DEVICE_OUTPUT(dev_multi_fit_vertices_t, PV::Vertex), dev_multi_fit_vertices),
    (DEVICE_OUTPUT(dev_number_of_multi_fit_vertices_t, unsigned), dev_number_of_multi_fit_vertices),
    (PROPERTY(block_dim_y_t, "block_dim_y", "block dimension Y", unsigned), block_dim_y))

  __global__ void pv_beamline_multi_fitter(
    Parameters,
    const float* dev_beamline);

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
      cudaStream_t& stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_y_t> m_block_dim_y {this, 4};
  };
} // namespace pv_beamline_multi_fitter

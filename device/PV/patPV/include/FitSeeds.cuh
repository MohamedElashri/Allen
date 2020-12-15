/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <stdint.h>
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "patPV_Definitions.cuh"
#include "VeloEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "PV_Definitions.cuh"

__device__ bool fit_vertex(
  const PatPV::XYZPoint& seedPoint,
  Velo::Consolidated::ConstStates& velo_states,
  PV::Vertex& vtx,
  int number_of_tracks,
  unsigned tracks_offset);

__device__ float get_tukey_weight(float trchi2, int iter);

namespace fit_seeds {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (DEVICE_OUTPUT(dev_vertex_t, PV::Vertex), dev_vertex),
    (DEVICE_OUTPUT(dev_number_vertex_t, int), dev_number_vertex),
    (DEVICE_INPUT(dev_seeds_t, PatPV::XYZPoint), dev_seeds),
    (DEVICE_INPUT(dev_number_seeds_t, unsigned), dev_number_seeds),
    (DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char), dev_velo_kalman_beamline_states),
    (DEVICE_INPUT(dev_atomics_velo_t, unsigned), dev_atomics_velo),
    (DEVICE_INPUT(dev_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void fit_seeds(Parameters);

  struct pv_fit_seeds_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace fit_seeds
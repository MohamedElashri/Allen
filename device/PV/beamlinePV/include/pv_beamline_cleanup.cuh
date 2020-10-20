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

namespace pv_beamline_cleanup {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (DEVICE_INPUT(dev_multi_fit_vertices_t, PV::Vertex), dev_multi_fit_vertices),
    (DEVICE_INPUT(dev_number_of_multi_fit_vertices_t, unsigned), dev_number_of_multi_fit_vertices),
    (DEVICE_OUTPUT(dev_multi_final_vertices_t, PV::Vertex), dev_multi_final_vertices),
    (DEVICE_OUTPUT(dev_number_of_multi_final_vertices_t, unsigned), dev_number_of_multi_final_vertices),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void pv_beamline_cleanup(Parameters);

  struct pv_beamline_cleanup_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };
} // namespace pv_beamline_cleanup

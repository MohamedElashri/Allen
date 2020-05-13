#pragma once

#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "patPV_Definitions.cuh"
#include "FloatOperations.cuh"
#include <cstdint>

namespace pv_beamline_peak {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_zhisto_t, float) dev_zhisto;
    DEVICE_OUTPUT(dev_zpeaks_t, float) dev_zpeaks;
    DEVICE_OUTPUT(dev_number_of_zpeaks_t, uint) dev_number_of_zpeaks;
  };

  __global__ void
  pv_beamline_peak(Parameters, const uint number_of_events);

  template<typename T>
  struct pv_beamline_peak_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(pv_beamline_peak)) function {pv_beamline_peak};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const {
      set_size<dev_zpeaks_t>(arguments, first<host_number_of_selected_events_t>(arguments) * PV::max_number_vertices);
      set_size<dev_number_of_zpeaks_t>(arguments, first<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const {
      const auto grid_dim = dim3(
        (first<host_number_of_selected_events_t>(arguments) + PV::num_threads_pv_beamline_peak_t - 1) /
        PV::num_threads_pv_beamline_peak_t);

      function(grid_dim, PV::num_threads_pv_beamline_peak_t, cuda_stream)(
        Parameters {
          data<dev_zhisto_t>(arguments), data<dev_zpeaks_t>(arguments), data<dev_number_of_zpeaks_t>(arguments)},
        first<host_number_of_selected_events_t>(arguments));
    }
  };
} // namespace pv_beamline_peak
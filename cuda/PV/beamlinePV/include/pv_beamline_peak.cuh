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
  struct Arguments {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_zhisto_t, float) dev_zhisto;
    DEVICE_OUTPUT(dev_zpeaks_t, float) dev_zpeaks;
    DEVICE_OUTPUT(dev_number_of_zpeaks_t, uint) dev_number_of_zpeaks;
  };

  __global__ void pv_beamline_peak(Arguments arguments, const uint number_of_events);

  template<typename T>
  struct pv_beamline_peak_t : public DeviceAlgorithm, Arguments {
    constexpr static auto name {"pv_beamline_peak_t"};
    decltype(global_function(pv_beamline_peak)) function {pv_beamline_peak};

    void set_arguments_size(
      ArgumentRefManager<T> manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_zpeaks_t>(manager, value<host_number_of_selected_events_t>(manager) * PV::max_number_vertices);
      set_size<dev_number_of_zpeaks_t>(manager, value<host_number_of_selected_events_t>(manager));
    }

    void operator()(
      const ArgumentRefManager<T>& manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      const auto grid_dim = dim3(
        (value<host_number_of_selected_events_t>(manager) + PV::num_threads_pv_beamline_peak_t - 1) /
        PV::num_threads_pv_beamline_peak_t);

      function.invoke(grid_dim, PV::num_threads_pv_beamline_peak_t, cuda_stream)(
        Arguments {
          offset<dev_zhisto_t>(manager), offset<dev_zpeaks_t>(manager), offset<dev_number_of_zpeaks_t>(manager)},
        value<host_number_of_selected_events_t>(manager));
    }
  };
} // namespace pv_beamline_peak
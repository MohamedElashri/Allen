#pragma once

#include "VeloDefinitions.cuh"
#include "patPV_Definitions.cuh"
#include <stdint.h>
#include "VeloEventModel.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "VeloConsolidated.cuh"

namespace pv_get_seeds {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, uint);
    DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char) dev_velo_kalman_beamline_states;
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_OUTPUT(dev_seeds_t, PatPV::XYZPoint) dev_seeds;
    DEVICE_OUTPUT(dev_number_seeds_t, uint) dev_number_seeds;
    PROPERTY(max_chi2_merge_t, float, "max_chi2_merge", "max chi2 merge", 25.f) max_chi2_merge;
    PROPERTY(factor_to_increase_errors_t, float, "factor_to_increase_errors", "factor to increase errors", 15.f)
    factor_to_increase_errors;
    PROPERTY(min_cluster_mult_t, int, "min_cluster_mult", "min cluster mult", 4) min_cluster_mult;
    PROPERTY(min_close_tracks_in_cluster_t, int, "min_close_tracks_in_cluster", "min close tracks in cluster", 3)
    min_close_tracks_in_cluster;
    PROPERTY(dz_close_tracks_in_cluster_t, float, "dz_close_tracks_in_cluster", "dz close tracks in cluster [mm]", 5.f)
    dz_close_tracks_in_cluster;
    PROPERTY(high_mult_t, int, "high_mult", "high mult", 10) high_mult;
    PROPERTY(ratio_sig2_high_mult_t, float, "ratio_sig2_high_mult", "ratio sig2 high mult", 1.0f) ratio_sig2_high_mult;
    PROPERTY(ratio_sig2_low_mult_t, float, "ratio_sig2_low_mult", "ratio sig2 low mult", 0.9f) ratio_sig2_low_mult;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __device__ int
  find_clusters(PatPV::vtxCluster* vclus, float* zclusters, int number_of_clusters, const Parameters& parameters);

  __global__ void pv_get_seeds(Parameters);

  template<typename T, char... S>
  struct pv_get_seeds_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(pv_get_seeds)) function {pv_get_seeds};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_seeds_t>(arguments, value<host_number_of_reconstructed_velo_tracks_t>(arguments));
      set_size<dev_number_seeds_t>(arguments, value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_velo_kalman_beamline_states_t>(arguments),
                    begin<dev_atomics_velo_t>(arguments),
                    begin<dev_velo_track_hit_number_t>(arguments),
                    begin<dev_seeds_t>(arguments),
                    begin<dev_number_seeds_t>(arguments),
                    property<max_chi2_merge_t>(),
                    property<factor_to_increase_errors_t>(),
                    property<min_cluster_mult_t>(),
                    property<min_close_tracks_in_cluster_t>(),
                    property<dz_close_tracks_in_cluster_t>(),
                    property<high_mult_t>(),
                    property<ratio_sig2_high_mult_t>(),
                    property<ratio_sig2_low_mult_t>()});

      if (runtime_options.do_check) {
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_number_of_seeds,
          begin<dev_number_seeds_t>(arguments),
          size<dev_number_seeds_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }

  private:
    Property<max_chi2_merge_t> m_chi2 {this};
    Property<factor_to_increase_errors_t> m_ferr {this};
    Property<min_cluster_mult_t> m_mult {this};
    Property<min_close_tracks_in_cluster_t> m_close {this};
    Property<dz_close_tracks_in_cluster_t> m_dz {this};
    Property<high_mult_t> m_himult {this};
    Property<ratio_sig2_high_mult_t> m_ratiohi {this};
    Property<ratio_sig2_low_mult_t> m_ratiolo {this};
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace pv_get_seeds

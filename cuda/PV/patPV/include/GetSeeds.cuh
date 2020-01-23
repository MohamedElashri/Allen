#pragma once

#include "VeloDefinitions.cuh"
#include "patPV_Definitions.cuh"
#include <stdint.h>
#include "VeloEventModel.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "VeloConsolidated.cuh"

__device__ int find_clusters(PatPV::vtxCluster* vclus, float* zclusters, int number_of_clusters);

namespace pv_get_seeds {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, uint);
    DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char) dev_velo_kalman_beamline_states;
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_OUTPUT(dev_seeds_t, PatPV::XYZPoint) dev_seeds;
    DEVICE_OUTPUT(dev_number_seeds_t, uint) dev_number_seeds;
    PROPERTY(max_chi2_merge_t, float) max_chi2_merge;
    PROPERTY(factor_to_increase_errors_t, float) factor_to_increase_errors;
    PROPERTY(min_cluster_mult_t, int) min_cluster_mult;
    PROPERTY(min_close_tracks_in_cluster_t, int) min_close_tracks_in_cluster;
    PROPERTY(dz_close_tracks_in_cluster_t, float) dz_close_tracks_in_cluster;
    PROPERTY(high_mult_t, int) high_mult;
    PROPERTY(ratio_sig2_high_mult_t, float) ratio_sig2_high_mult;
    PROPERTY(ratio_sig2_low_mult_t, float) ratio_sig2_low_mult;
  };

  __global__ void pv_get_seeds(Parameters);

  template<typename T, char... S>
  struct pv_get_seeds_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(pv_get_seeds)) function {pv_get_seeds};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_seeds_t>(arguments, value<host_number_of_reconstructed_velo_tracks_t>(arguments));
      set_size<dev_number_seeds_t>(arguments, value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {begin<dev_velo_kalman_beamline_states_t>(arguments),
                    begin<dev_atomics_velo_t>(arguments),
                    begin<dev_velo_track_hit_number_t>(arguments),
                    begin<dev_seeds_t>(arguments),
                    begin<dev_number_seeds_t>(arguments),
                    get_property_value<max_chi2_merge_t>("max_chi2_merge"),
                    get_property_value<factor_to_increase_errors_t>("factor_to_increase_errors"),
                    get_property_value<min_cluster_mult_t>("min_cluster_mult"),
                    get_property_value<min_close_tracks_in_cluster_t>("min_close_tracks_in_cluster"),
                    get_property_value<dz_close_tracks_in_cluster_t>("dz_close_tracks_in_cluster"),
                    get_property_value<high_mult_t>("high_mult"),
                    get_property_value<ratio_sig2_high_mult_t>("ratio_sig2_high_mult"),
                    get_property_value<ratio_sig2_low_mult_t>("ratio_sig2_low_mult")});

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
    Property<max_chi2_merge_t> m_chi2 {this, "max_chi2_merge", 25.f, "max chi2 merge"};
    Property<factor_to_increase_errors_t> m_ferr {this, "factor_to_increase_errors", 15.f, "factor to increase errors"};
    Property<min_cluster_mult_t> m_mult {this, "min_cluster_mult", 4, "min cluster mult"};
    Property<min_close_tracks_in_cluster_t> m_close {this,
                                                     "min_close_tracks_in_cluster",
                                                     3,
                                                     "min close tracks in cluster"};
    Property<dz_close_tracks_in_cluster_t> m_dz {this,
                                                 "dz_close_tracks_in_cluster",
                                                 5.f,
                                                 "dz close tracks in cluster [mm]"};
    Property<high_mult_t> m_himult {this, "high_mult", 10, "high mult"};
    Property<ratio_sig2_high_mult_t> m_ratiohi {this, "ratio_sig2_high_mult", 1.0f, "ratio sig2 high mult"};
    Property<ratio_sig2_low_mult_t> m_ratiolo {this, "ratio_sig2_low_mult", 0.9f, "ratio sig2 low mult"};
  };
} // namespace pv_get_seeds
#pragma once

#include <cstdint>
#include <cfloat>
#include "ClusteringDefinitions.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "FillCandidates.cuh"
#include "ProcessModules.cuh"
#include "TrackForwarding.cuh"
#include "TrackSeeding.cuh"
#include "WeakTracksAdder.cuh"
#include "GpuAlgorithm.cuh"

namespace velo_search_by_triplet {
  // Arguments
  HOST_INPUT(host_total_number_of_velo_clusters_t, uint)
  DEVICE_INPUT(dev_velo_cluster_container_t, uint)
  DEVICE_INPUT(dev_estimated_input_size_t, uint)
  DEVICE_INPUT(dev_module_cluster_num_t, uint)
  DEVICE_INPUT(dev_h0_candidates_t, short)
  DEVICE_INPUT(dev_h2_candidates_t, short)
  DEVICE_OUTPUT(dev_tracks_t, Velo::TrackHits)
  DEVICE_OUTPUT(dev_tracklets_t, Velo::TrackletHits)
  DEVICE_OUTPUT(dev_tracks_to_follow_t, uint)
  DEVICE_OUTPUT(dev_weak_tracks_t, Velo::TrackletHits)
  DEVICE_OUTPUT(dev_hit_used_t, bool)
  DEVICE_OUTPUT(dev_atomics_velo_t, uint)
  DEVICE_OUTPUT(dev_rel_indices_t, unsigned short)
  DEVICE_OUTPUT(dev_number_of_velo_tracks_t, uint)

  __global__ void velo_search_by_triplet(
    dev_velo_cluster_container_t dev_velo_cluster_container,
    dev_estimated_input_size_t dev_estimated_input_size,
    dev_module_cluster_num_t dev_module_cluster_num,
    dev_tracks_t dev_tracks,
    dev_tracklets_t dev_tracklets,
    dev_tracks_to_follow_t dev_tracks_to_follow,
    dev_weak_tracks_t dev_weak_tracks,
    dev_hit_used_t dev_hit_used,
    dev_atomics_velo_t dev_atomics_velo,
    dev_h0_candidates_t dev_h0_candidates,
    dev_h2_candidates_t dev_h2_candidates,
    dev_rel_indices_t dev_rel_indices,
    dev_number_of_velo_tracks_t dev_number_of_velo_tracks,
    const VeloGeometry* dev_velo_geometry);

  template<typename Arguments>
  struct velo_search_by_triplet_t : public GpuAlgorithm {
    constexpr static auto name {"velo_search_by_triplet_t"};
    decltype(gpu_function(velo_search_by_triplet)) function {velo_search_by_triplet};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_tracks_t>(arguments, host_buffers.host_number_of_selected_events[0] * Velo::Constants::max_tracks);
      set_size<dev_tracklets_t>(
        arguments, host_buffers.host_number_of_selected_events[0] * get_property_value<uint>("ttf_modulo"));
      set_size<dev_tracks_to_follow_t>(
        arguments, host_buffers.host_number_of_selected_events[0] * get_property_value<uint>("ttf_modulo"));
      set_size<dev_weak_tracks_t>(
        arguments, host_buffers.host_number_of_selected_events[0] * get_property_value<uint>("max_weak_tracks"));
      set_size<dev_hit_used_t>(arguments, offset<host_total_number_of_velo_clusters_t>(arguments)[0]);
      set_size<dev_atomics_velo_t>(arguments, host_buffers.host_number_of_selected_events[0] * Velo::num_atomics);
      set_size<dev_number_of_velo_tracks_t>(arguments, host_buffers.host_number_of_selected_events[0]);
      set_size<dev_rel_indices_t>(
        arguments, host_buffers.host_number_of_selected_events[0] * 2 * Velo::Constants::max_numhits_in_module);
    }

    void operator()(
      const ArgumentRefManager<Arguments>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {

      cudaCheck(
        cudaMemsetAsync(offset<dev_atomics_velo_t>(arguments), 0, size<dev_atomics_velo_t>(arguments), cuda_stream));
      cudaCheck(cudaMemsetAsync(offset<dev_hit_used_t>(arguments), 0, size<dev_hit_used_t>(arguments), cuda_stream));
      cudaCheck(cudaMemsetAsync(
        offset<dev_number_of_velo_tracks_t>(arguments), 0, size<dev_number_of_velo_tracks_t>(arguments), cuda_stream));

      function(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
        offset<dev_velo_cluster_container_t>(arguments),
        offset<dev_estimated_input_size_t>(arguments),
        offset<dev_module_cluster_num_t>(arguments),
        offset<dev_tracks_t>(arguments),
        offset<dev_tracklets_t>(arguments),
        offset<dev_tracks_to_follow_t>(arguments),
        offset<dev_weak_tracks_t>(arguments),
        offset<dev_hit_used_t>(arguments),
        offset<dev_atomics_velo_t>(arguments),
        offset<dev_h0_candidates_t>(arguments),
        offset<dev_h2_candidates_t>(arguments),
        offset<dev_rel_indices_t>(arguments),
        offset<dev_number_of_velo_tracks_t>(arguments),
        constants.dev_velo_geometry);
    }

  private:
    Property<float> m_tol {this,
                           "forward_phi_tolerance",
                           Configuration::velo_search_by_triplet::forward_phi_tolerance,
                           0.052f,
                           "tolerance"};
    Property<float> m_chi2 {this, "max_chi2", Configuration::velo_search_by_triplet::max_chi2, 20.0f, "chi2"};
    Property<float> m_scat {this,
                            "max_scatter_forwarding",
                            Configuration::velo_search_by_triplet::max_scatter_forwarding,
                            0.1f,
                            "scatter forwarding"};
    Property<float> m_seed {this,
                            "max_scatter_seeding",
                            Configuration::velo_search_by_triplet::max_scatter_seeding,
                            0.1f,
                            "scatter seeding"};
    Property<uint> m_skip {this,
                           "max_skipped_modules",
                           Configuration::velo_search_by_triplet::max_skipped_modules,
                           1u,
                           "skipped modules"};
    Property<uint> m_max_weak {this,
                               "max_weak_tracks",
                               Configuration::velo_search_by_triplet::max_weak_tracks,
                               500u,
                               "max weak tracks"};
    Property<float> m_ext_base {this,
                                "phi_extrapolation_base",
                                Configuration::velo_search_by_triplet::phi_extrapolation_base,
                                0.03f,
                                "phi extrapolation base"};
    Property<float> m_ext_coef {this,
                                "phi_extrapolation_coef",
                                Configuration::velo_search_by_triplet::phi_extrapolation_coef,
                                0.0002f,
                                "phi extrapolation coefficient"};
    Property<uint> m_ttf_mod {this,
                              "ttf_modulo",
                              Configuration::velo_search_by_triplet::ttf_modulo,
                              2048u,
                              "ttf modulo"};
    Property<int> m_ttf_mask {this,
                              "ttf_modulo_mask",
                              Configuration::velo_search_by_triplet::ttf_modulo_mask,
                              0x7FF,
                              "ttf modulo mask"};
  };
} // namespace velo_search_by_triplet
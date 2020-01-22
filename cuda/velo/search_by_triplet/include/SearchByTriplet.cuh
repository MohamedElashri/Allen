#pragma once

#include <cstdint>
#include <cfloat>
#include "ClusteringDefinitions.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "ProcessModules.cuh"
#include "TrackForwarding.cuh"
#include "TrackSeeding.cuh"
#include "DeviceAlgorithm.cuh"

namespace velo_search_by_triplet {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_total_number_of_velo_clusters_t, uint);
    DEVICE_INPUT(dev_sorted_velo_cluster_container_t, uint) dev_sorted_velo_cluster_container;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, uint) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_module_cluster_num_t, uint) dev_module_cluster_num;
    DEVICE_INPUT(dev_h0_candidates_t, short) dev_h0_candidates;
    DEVICE_INPUT(dev_h2_candidates_t, short) dev_h2_candidates;
    DEVICE_INPUT(dev_hit_phi_t, float) dev_hit_phi;
    DEVICE_OUTPUT(dev_tracks_t, Velo::TrackHits) dev_tracks;
    DEVICE_OUTPUT(dev_tracklets_t, Velo::TrackletHits) dev_tracklets;
    DEVICE_OUTPUT(dev_tracks_to_follow_t, uint) dev_tracks_to_follow;
    DEVICE_OUTPUT(dev_three_hit_tracks_t, Velo::TrackletHits) dev_three_hit_tracks;
    DEVICE_OUTPUT(dev_hit_used_t, bool) dev_hit_used;
    DEVICE_OUTPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_OUTPUT(dev_rel_indices_t, unsigned short) dev_rel_indices;
    DEVICE_OUTPUT(dev_number_of_velo_tracks_t, uint) dev_number_of_velo_tracks;
    PROPERTY(forward_phi_tolerance_t, float) forward_phi_tolerance;
    PROPERTY(max_chi2_t, float) max_chi2;
    PROPERTY(max_scatter_forwarding_t, float) max_scatter_forwarding;
    PROPERTY(max_scatter_seeding_t, float) max_scatter_seeding;
    PROPERTY(max_skipped_modules_t, uint) max_skipped_modules;
    PROPERTY(max_weak_tracks_t, uint) max_weak_tracks;
  };

  __global__ void velo_search_by_triplet(Parameters, const VeloGeometry*);

  template<typename T, char... S>
  struct velo_search_by_triplet_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(velo_search_by_triplet)) function {velo_search_by_triplet};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_tracks_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Velo::Constants::max_tracks);
      set_size<dev_tracklets_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * get_property_value<uint>("ttf_modulo"));
      set_size<dev_tracks_to_follow_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * get_property_value<uint>("ttf_modulo"));
      set_size<dev_three_hit_tracks_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * get_property_value<uint>("max_weak_tracks"));
      set_size<dev_hit_used_t>(arguments, value<host_total_number_of_velo_clusters_t>(arguments));
      set_size<dev_atomics_velo_t>(arguments, value<host_number_of_selected_events_t>(arguments) * Velo::num_atomics);
      set_size<dev_number_of_velo_tracks_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_rel_indices_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * 2 * Velo::Constants::max_numhits_in_module);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      cudaCheck(
        cudaMemsetAsync(begin<dev_atomics_velo_t>(arguments), 0, size<dev_atomics_velo_t>(arguments), cuda_stream));
      cudaCheck(cudaMemsetAsync(begin<dev_hit_used_t>(arguments), 0, size<dev_hit_used_t>(arguments), cuda_stream));
      cudaCheck(cudaMemsetAsync(
        begin<dev_number_of_velo_tracks_t>(arguments), 0, size<dev_number_of_velo_tracks_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {begin<dev_sorted_velo_cluster_container_t>(arguments),
                    begin<dev_offsets_estimated_input_size_t>(arguments),
                    begin<dev_module_cluster_num_t>(arguments),
                    begin<dev_h0_candidates_t>(arguments),
                    begin<dev_h2_candidates_t>(arguments),
                    begin<dev_hit_phi_t>(arguments),
                    begin<dev_tracks_t>(arguments),
                    begin<dev_tracklets_t>(arguments),
                    begin<dev_tracks_to_follow_t>(arguments),
                    begin<dev_three_hit_tracks_t>(arguments),
                    begin<dev_hit_used_t>(arguments),
                    begin<dev_atomics_velo_t>(arguments),
                    begin<dev_rel_indices_t>(arguments),
                    begin<dev_number_of_velo_tracks_t>(arguments),
                    get_property_value<forward_phi_tolerance_t>("forward_phi_tolerance"),
                    get_property_value<max_chi2_t>("max_chi2"),
                    get_property_value<max_scatter_forwarding_t>("max_scatter_forwarding"),
                    get_property_value<max_scatter_seeding_t>("max_scatter_seeding"),
                    get_property_value<max_skipped_modules_t>("max_skipped_modules"),
                    get_property_value<max_weak_tracks_t>("max_weak_tracks"),
                  },
        constants.dev_velo_geometry);
    }

  private:
    Property<forward_phi_tolerance_t> m_tol {this,
                           "forward_phi_tolerance",
                           0.052f,
                           "tolerance"};
    Property<max_chi2_t> m_chi2 {this, "max_chi2", 20.0f, "chi2"};
    Property<max_scatter_forwarding_t> m_scat {this,
                            "max_scatter_forwarding",
                            0.1f,
                            "scatter forwarding"};
    Property<max_scatter_seeding_t> m_seed {this,
                            "max_scatter_seeding",
                            Configuration::velo_search_by_triplet::max_scatter_seeding,
                            0.1f,
                            "scatter seeding"};
    Property<max_skipped_modules_t> m_skip {this,
                           "max_skipped_modules",
                           1u,
                           "skipped modules"};
    Property<max_weak_tracks_t> m_max_weak {this,
                               "max_weak_tracks",
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
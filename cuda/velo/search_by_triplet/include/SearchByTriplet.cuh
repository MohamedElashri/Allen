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

    // Forward tolerance in phi
    PROPERTY(forward_phi_tolerance_t, float, "forward_phi_tolerance", "tolerance of phi", 0.052f) forward_phi_tolerance;

    // Max scatter for forming triplets (seeding) and forwarding
    PROPERTY(max_scatter_forwarding_t, float, "max_scatter_forwarding", "scatter forwarding", 0.1f)
    max_scatter_forwarding;
    PROPERTY(max_scatter_seeding_t, float, "max_scatter_seeding", "scatter seeding", 0.1f) max_scatter_seeding;

    // Maximum number of skipped modules allowed for a track
    // before storing it
    PROPERTY(max_skipped_modules_t, uint, "max_skipped_modules", "skipped modules", 1u) max_skipped_modules;

    // Maximum number of tracks to follow at a time
    PROPERTY(max_weak_tracks_t, uint, "max_weak_tracks", "max weak tracks", 500u) max_weak_tracks;

    // Maximum number of tracks to follow at a time
    PROPERTY(ttf_modulo_t, uint, "ttf_modulo", "ttf modulo", 2048u) ttf_modulo;
    PROPERTY(ttf_modulo_mask_t, int, "ttf_modulo_mask", "ttf modulo mask", 0x7FF) ttf_modulo_mask;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {32, 1, 1});
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
        arguments, value<host_number_of_selected_events_t>(arguments) * property<ttf_modulo_t>());
      set_size<dev_tracks_to_follow_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * property<ttf_modulo_t>());
      set_size<dev_three_hit_tracks_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * property<max_weak_tracks_t>());
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

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
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
                    property<forward_phi_tolerance_t>(),
                    property<max_scatter_forwarding_t>(),
                    property<max_scatter_seeding_t>(),
                    property<max_skipped_modules_t>(),
                    property<max_weak_tracks_t>(),
                    property<ttf_modulo_t>(),
                    property<ttf_modulo_mask_t>()},
        constants.dev_velo_geometry);
    }

<<<<<<< HEAD
  private:
    Property<forward_phi_tolerance_t> m_tol {this};
    Property<max_scatter_forwarding_t> m_scat {this};
    Property<max_scatter_seeding_t> m_seed {this};
    Property<max_skipped_modules_t> m_skip {this};
    Property<max_weak_tracks_t> m_max_weak {this};
    Property<ttf_modulo_t> m_ttf_mod {this};
    Property<ttf_modulo_mask_t> m_ttf_mask {this};
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace velo_search_by_triplet
=======
ALGORITHM(search_by_triplet,
          velo_search_by_triplet_t,
          ARGUMENTS(
            dev_velo_cluster_container,
            dev_estimated_input_size,
            dev_module_cluster_num,
            dev_tracks,
            dev_tracklets,
            dev_tracks_to_follow,
            dev_weak_tracks,
            dev_hit_used,
            dev_atomics_velo,
            dev_h0_candidates,
            dev_h2_candidates,
            dev_rel_indices),
          Allen::Property<float> m_tol {this,
                                 "forward_phi_tolerance",
                                 Configuration::velo_search_by_triplet_t::forward_phi_tolerance,
                                 0.052f,
                                 "tolerance"};
          Allen::Property<float> m_chi2 {this, "max_chi2", Configuration::velo_search_by_triplet_t::max_chi2, 20.0f, "chi2"};
          Allen::Property<float> m_scat {this,
                                  "max_scatter_forwarding",
                                  Configuration::velo_search_by_triplet_t::max_scatter_forwarding,
                                  0.1f,
                                  "scatter forwarding"};
          Allen::Property<float> m_seed {this,
                                  "max_scatter_seeding",
                                  Configuration::velo_search_by_triplet_t::max_scatter_seeding,
                                  0.1f,
                                  "scatter seeding"};
          Allen::Property<uint> m_skip {this,
                                 "max_skipped_modules",
                                 Configuration::velo_search_by_triplet_t::max_skipped_modules,
                                 1u,
                                 "skipped modules"};
          Allen::Property<uint> m_max_weak {this,
                                     "max_weak_tracks",
                                     Configuration::velo_search_by_triplet_t::max_weak_tracks,
                                     500u,
                                     "max weak tracks"};
          Allen::Property<float> m_ext_base {this,
                                      "phi_extrapolation_base",
                                      Configuration::velo_search_by_triplet_t::phi_extrapolation_base,
                                      0.03f,
                                      "phi extrapolation base"};
          Allen::Property<float> m_ext_coef {this,
                                      "phi_extrapolation_coef",
                                      Configuration::velo_search_by_triplet_t::phi_extrapolation_coef,
                                      0.0002f,
                                      "phi extrapolation coefficient"};
          Allen::Property<uint>
            m_ttf_mod {this, "ttf_modulo", Configuration::velo_search_by_triplet_t::ttf_modulo, 2048u, "ttf modulo"};
          Allen::Property<int> m_ttf_mask {this,
                                    "ttf_modulo_mask",
                                    Configuration::velo_search_by_triplet_t::ttf_modulo_mask,
                                    0x7FF,
                                    "ttf modulo mask"};)
>>>>>>> dovombru_Gaudi_Allen_integration

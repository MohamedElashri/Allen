/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "VeloDefinitions.cuh"
#include "patPV_Definitions.cuh"
#include <stdint.h>
#include "VeloEventModel.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "VeloConsolidated.cuh"

namespace pv_get_seeds {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned), host_number_of_reconstructed_velo_tracks),
    (DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char), dev_velo_kalman_beamline_states),
    (DEVICE_INPUT(dev_atomics_velo_t, unsigned), dev_atomics_velo),
    (DEVICE_INPUT(dev_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (DEVICE_OUTPUT(dev_seeds_t, PatPV::XYZPoint), dev_seeds),
    (DEVICE_OUTPUT(dev_number_seeds_t, unsigned), dev_number_seeds),
    (PROPERTY(max_chi2_merge_t, "max_chi2_merge", "max chi2 merge", float), max_chi2_merge),
    (PROPERTY(factor_to_increase_errors_t, "factor_to_increase_errors", "factor to increase errors", float), factor_to_increase_errors),
    (PROPERTY(min_cluster_mult_t, "min_cluster_mult", "min cluster mult", int), min_cluster_mult),
    (PROPERTY(min_close_tracks_in_cluster_t, "min_close_tracks_in_cluster", "min close tracks in cluster", int), min_close_tracks_in_cluster),
    (PROPERTY(dz_close_tracks_in_cluster_t, "dz_close_tracks_in_cluster", "dz close tracks in cluster [mm]", float), dz_close_tracks_in_cluster),
    (PROPERTY(high_mult_t, "high_mult", "high mult", int), high_mult),
    (PROPERTY(ratio_sig2_high_mult_t, "ratio_sig2_high_mult", "ratio sig2 high mult", float), ratio_sig2_high_mult),
    (PROPERTY(ratio_sig2_low_mult_t, "ratio_sig2_low_mult", "ratio sig2 low mult", float), ratio_sig2_low_mult),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __device__ int
  find_clusters(PatPV::vtxCluster* vclus, float* zclusters, int number_of_clusters, const Parameters& parameters);

  __global__ void pv_get_seeds(Parameters);

  struct pv_get_seeds_t : public DeviceAlgorithm, Parameters {
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
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<max_chi2_merge_t> m_chi2 {this, 25.f};
    Property<factor_to_increase_errors_t> m_ferr {this, 15.f};
    Property<min_cluster_mult_t> m_mult {this, 4};
    Property<min_close_tracks_in_cluster_t> m_close {this, 3};
    Property<dz_close_tracks_in_cluster_t> m_dz {this, 5.f};
    Property<high_mult_t> m_himult {this, 10};
    Property<ratio_sig2_high_mult_t> m_ratiohi {this, 1.0f};
    Property<ratio_sig2_low_mult_t> m_ratiolo {this, 0.9f};
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace pv_get_seeds

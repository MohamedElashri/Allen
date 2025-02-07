/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "SciFiEventModel.cuh"
#include "SciFiDefinitions.cuh"
#include "AlgorithmTypes.cuh"
#include "hybrid_seeding_case.cuh"
#include "hybrid_seeding_helpers.cuh"
/**
 * @brief Seeding in SciFI 1st statge with x_z layers
 * @detail first implementation of seeding starting with x_z layers to fit under HLT1 timing budget.
 */

namespace seed_confirmTracks {

#if defined(TARGET_DEVICE_CUDA)
#if __CUDA_ARCH__ >= 800 // Ampere
  __device__ static constexpr unsigned int maxNHits = 600;
#else // Volta, Turing
  __device__ static constexpr unsigned int maxNHits = 300;
#endif
#else // CPU, HIP
  __device__ static constexpr unsigned int maxNHits = 300;
#endif

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, uint) host_number_of_events;

    // event number and hits input
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_count_t, uint) dev_scifi_hit_count;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;

    // XZ inputs
    DEVICE_INPUT(dev_seeding_tracksXZ_t, SciFi::Seeding::TrackXZ) dev_seeding_tracksXZ;
    DEVICE_INPUT(dev_seeding_number_of_tracksXZ_part0_t, unsigned) dev_seeding_number_of_tracksXZ_part0;
    DEVICE_INPUT(dev_seeding_number_of_tracksXZ_part1_t, unsigned) dev_seeding_number_of_tracksXZ_part1;

    DEVICE_OUTPUT(dev_hits_working_mem_t, float) dev_hits_working_mem;
    DEVICE_OUTPUT(dev_count_hits_working_mem_t, unsigned) dev_count_hits_working_mem;

    // Outputs
    DEVICE_OUTPUT(dev_seeding_tracks_t, SciFi::Seeding::Track) dev_seeding_tracks;
    DEVICE_OUTPUT(dev_offsets_seeding_tracks_t, unsigned) dev_offsets_seeding_tracks;
    HOST_OUTPUT(host_seeding_number_of_tracks_t, unsigned) host_seeding_number_of_tracks;
  };

  __device__ unsigned findHit(const float tolRem, float predPos, int startPos, int nHits, float* coords);
  template<bool use_hough_search>
  __global__ void
  seed_confirmTracks(Parameters, const int tuning_nhits, const float tuning_tol_chi2, const float tuning_tol);
  __device__ void fitYZ(seed_uv::multiHitCombination& multiHitComb);

  struct seed_confirmTracks_t : public DeviceAlgorithm, Parameters {
    void update(const Constants& constants) const;

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<int> m_tuning_nhits {this, "tuning_nhits", 10, "tuning_nhits"};
    Allen::Property<float> m_tuning_tol_chi2 {this, "tuning_tol_chi2", 100., "tuning_tol_chi2"};
    Allen::Property<float> m_tuning_tol {this, "tuning_tol", 2., "tuning_tol"};
    Allen::Property<bool> m_use_hough_search {this, "use_hough_search", false, "use_hough_search"};
  };

} // namespace seed_confirmTracks

#pragma once

#include "VeloEventModel.cuh"
#include "SciFiEventModel.cuh"
#include "UTEventModel.cuh"
#include "UTDefinitions.cuh"
#include "SciFiDefinitions.cuh"
#include "Handler.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsMuon.cuh"
#include "ArgumentsVertex.cuh"
#include "LookingForwardConstants.cuh"

__global__ void __launch_bounds__(256)
  prefix_sum_reduce(uint* dev_main_array, uint* dev_auxiliary_array, const uint array_size);

__global__ void __launch_bounds__(1024)
  prefix_sum_single_block(uint* dev_total_sum, uint* dev_array, const uint array_size);

__global__ void __launch_bounds__(1024) copy_and_prefix_sum_single_block(
  uint* dev_total_sum,
  uint* dev_input_array,
  uint* dev_output_array,
  const uint array_size);

__global__ void __launch_bounds__(1024) copy_square_and_prefix_sum_single_block(
  uint* dev_total_sum,
  uint* dev_input_array,
  uint* dev_output_array,
  const uint array_size);

__global__ void __launch_bounds__(512)
  prefix_sum_scan(uint* dev_main_array, uint* dev_auxiliary_array, const uint array_size);

__global__ void copy_velo_track_hit_number(
  const Velo::TrackHits* dev_tracks,
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number);

__global__ void copy_ut_track_hit_number(
  const UT::TrackHits* dev_veloUT_tracks,
  uint* dev_atomics_veloUT,
  uint* dev_ut_track_hit_number);

__global__ void copy_scifi_track_hit_number(
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_tracks,
  uint* dev_n_scifi_tracks,
  uint* dev_scifi_track_hit_number);

ALGORITHM(copy_and_prefix_sum_single_block, copy_and_prefix_sum_single_block_velo_t, ARGUMENTS(dev_atomics_velo))

ALGORITHM(
  copy_velo_track_hit_number,
  copy_velo_track_hit_number_t,
  ARGUMENTS(dev_tracks, dev_atomics_velo, dev_velo_track_hit_number))

ALGORITHM(copy_and_prefix_sum_single_block, copy_and_prefix_sum_single_block_ut_t, ARGUMENTS(dev_atomics_ut))

ALGORITHM(
  copy_ut_track_hit_number,
  copy_ut_track_hit_number_t,
  ARGUMENTS(dev_ut_tracks, dev_atomics_ut, dev_ut_track_hit_number))

ALGORITHM(copy_and_prefix_sum_single_block, copy_and_prefix_sum_single_block_scifi_t, ARGUMENTS(dev_atomics_scifi))

ALGORITHM(
  copy_scifi_track_hit_number,
  copy_scifi_track_hit_number_t,
  ARGUMENTS(dev_atomics_ut, dev_scifi_tracks, dev_atomics_scifi, dev_scifi_track_hit_number))

ALGORITHM(
  copy_square_and_prefix_sum_single_block,
  copy_and_prefix_sum_single_block_sv_t,
  ARGUMENTS(dev_atomics_scifi, dev_sv_offsets))

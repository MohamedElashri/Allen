/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

__device__ void lf_triplet_seeding_impl(
  const int l0_size,
  const int l1_size,
  const int l2_size,
  const float z0,
  const float z1,
  const float z2,
  const unsigned ut_total_number_of_tracks,
  const float qop,
  const float ut_tx,
  const float velo_tx,
  const float x_at_z_magnet,
  const float* shared_xs,
  short* shared_indices,
  unsigned* shared_number_of_elements,
  int* scifi_lf_found_triplets,
  int8_t* scifi_lf_number_of_found_triplets,
  const unsigned triplet_seed);

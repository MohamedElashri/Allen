/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

// This
#include "DownstreamV2ComputeOffsets.cuh"

// UT
#include "UTEventModel.cuh"

// Primitives
#include "PrefixSum.cuh"

INSTANTIATE_ALGORITHM(downstream_v2_compute_offsets::downstream_v2_compute_offsets_t);

void downstream_v2_compute_offsets::downstream_v2_compute_offsets_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Basics
  const auto number_of_tracks = first<host_number_of_downstream_tracks_t>(arguments);

  // Set sizes
  set_size<dev_downstream_track_hit_offsets_t>(arguments, number_of_tracks + 1);
  set_size<host_number_of_downstream_hits_t>(arguments, 1);
}

void downstream_v2_compute_offsets::downstream_v2_compute_offsets_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  {
    const auto max_size = size<dev_downstream_track_hit_offsets_t>(arguments);

    constexpr unsigned MaxSize = 2048;
    const auto nblocks = (max_size + MaxSize - 1) / MaxSize;

    global_function(downstream_v2_compute_hit_offsets<MaxSize>)(dim3(nblocks), dim3(256), context)(arguments, max_size);
  }
  Allen::synchronize(context);

  // Debug
  if (m_verbosity.value() >= logger::debug) {
    print<dev_downstream_track_hit_offsets_t>(arguments);
    print<host_number_of_downstream_hits_t>(arguments);
  }
}

template<unsigned N>
__global__ void downstream_v2_compute_offsets::downstream_v2_compute_hit_offsets(
  Parameters parameters,
  const unsigned num_tracks)
{
  const auto offset = N * blockIdx.x;
  const auto size = std::min(num_tracks - offset, N);

  for (unsigned i = threadIdx.x; i < size; i += blockDim.x) {
    const auto idx = offset + i;
    parameters.dev_downstream_track_hit_offsets[idx] = idx * 4;

    if (idx + 1 == num_tracks) {
      parameters.host_number_of_downstream_hits[0] = idx * 4;
    }
  }
}
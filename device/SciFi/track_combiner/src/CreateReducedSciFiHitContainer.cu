/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "CreateReducedSciFiHitContainer.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(create_reduced_scifi_hit_container::create_reduced_scifi_hit_container_t)

__global__ void
count_unused(create_reduced_scifi_hit_container::Parameters parameters, unsigned* counts, unsigned n_counts)
{
  for (unsigned i = blockIdx.x * blockDim.x + threadIdx.x; i < n_counts; i += gridDim.x * blockDim.x) {
    counts[i] = __popc(~parameters.dev_used_scifi_hits[i]);
  }
}

__global__ void make_zone_offsets(create_reduced_scifi_hit_container::Parameters parameters, unsigned* counts)
{
  const unsigned n_zones = parameters.dev_number_of_events[0] * SciFi::Constants::n_zones;
  for (unsigned i = blockIdx.x * blockDim.x + threadIdx.x; i < n_zones + 1; i += gridDim.x * blockDim.x) {
    int index_input = parameters.dev_scifi_hit_offsets_input[i];
    auto mask = (1 << (index_input % 32)) - 1;
    parameters.dev_scifi_hit_offsets[i] =
      counts[index_input / 32] + __popc((~parameters.dev_used_scifi_hits[index_input / 32]) & mask);
  }
}

__global__ void create_scifi_hit_container(create_reduced_scifi_hit_container::Parameters parameters, unsigned* counts)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const auto n_input_hits = parameters.dev_scifi_hit_offsets_input[number_of_events * SciFi::Constants::n_zones];
  const auto n_output_hits = parameters.dev_scifi_hit_offsets[number_of_events * SciFi::Constants::n_zones];
  SciFi::ConstHits hits_input {parameters.dev_scifi_hits_input, n_input_hits};
  SciFi::Hits hits_output {parameters.dev_scifi_hits, n_output_hits};

  for (unsigned i = blockIdx.x * blockDim.x + threadIdx.x; i < n_input_hits; i += gridDim.x * blockDim.x) {
    int index_input = i;
    if (!(parameters.dev_used_scifi_hits[index_input / 32] & (1 << (index_input % 32)))) { // if unused
      auto mask = (1 << (index_input % 32)) - 1;
      int index_output = counts[index_input / 32] + __popc((~parameters.dev_used_scifi_hits[index_input / 32]) & mask);

      hits_output.x0(index_output) = hits_input.x0(index_input);
      hits_output.z0(index_output) = hits_input.z0(index_input);
      hits_output.channel(index_output) = hits_input.channel(index_input);
      hits_output.endPointY(index_output) = hits_input.endPointY(index_input);
      hits_output.assembled_datatype(index_output) = hits_input.assembled_datatype(index_input);
    }
  }
}

void create_reduced_scifi_hit_container::create_reduced_scifi_hit_container_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_scifi_hit_offsets_t>(arguments, size<dev_scifi_hit_offsets_input_t>(arguments));
  set_size<host_number_of_scifi_hits_t>(arguments, 1);
}

void create_reduced_scifi_hit_container::create_reduced_scifi_hit_container_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  auto counts =
    arguments.template make_buffer<Allen::Store::Scope::Device, unsigned>(size<dev_used_scifi_hits_t>(arguments));

  global_function(count_unused)(DIV_CEIL(counts.size(), m_block_dim_x), dim3(m_block_dim_x), context)(
    arguments, counts.data(), counts.size());
  PrefixSum::prefix_sum(*this, arguments, context, counts.data(), counts.size() - 1);

  global_function(make_zone_offsets)(
    DIV_CEIL(size<dev_scifi_hit_offsets_t>(arguments), m_block_dim_x), dim3(m_block_dim_x), context)(
    arguments, counts.data());

  unsigned array_size = size<dev_scifi_hit_offsets_t>(arguments) - 1;
  Allen::copy<host_number_of_scifi_hits_t, dev_scifi_hit_offsets_t>(arguments, context, 1, 0, array_size);

  // Resize dev_scifi_hits_t to hold all hits
  resize<dev_scifi_hits_t>(
    arguments, first<host_number_of_scifi_hits_t>(arguments) * SciFi::Hits::number_of_arrays * sizeof(uint32_t));

  // Populate dev_scifi_hits_t
  global_function(create_scifi_hit_container)(size<dev_event_list_t>(arguments), dim3(m_block_dim_x), context)(
    arguments, counts.data());
}

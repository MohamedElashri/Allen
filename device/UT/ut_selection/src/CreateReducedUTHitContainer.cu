/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "CreateReducedUTHitContainer.cuh"

INSTANTIATE_ALGORITHM(create_reduced_ut_hits_container::create_reduced_ut_hits_container_t)

__global__ void create_ut_hit_container(create_reduced_ut_hits_container::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const unsigned total_number_of_hits_input =
    parameters.dev_ut_hit_offsets_input[number_of_events * UT::Constants::n_groups];
  const UT::HitOffsets hit_offsets_input {parameters.dev_ut_hit_offsets_input, event_number};
  UT::ConstHits hits_input {parameters.dev_ut_hits_input, total_number_of_hits_input};
  UT::Hits hits_output {parameters.dev_ut_hits,
                        parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups]};

  const auto event_offset_input = hit_offsets_input.event_offset();
  for (unsigned i = threadIdx.x; i < hit_offsets_input.event_number_of_hits(); i += blockDim.x) {
    const auto index_input = event_offset_input + i;
    if (
      (parameters.dev_used_ut_hits_offsets[index_input + 1] - parameters.dev_used_ut_hits_offsets[index_input]) == 0) {
      const auto index_output = index_input - parameters.dev_used_ut_hits_offsets[index_input];
      hits_output.yBegin(index_output) = hits_input.yBegin(index_input);
      hits_output.yEnd(index_output) = hits_input.yEnd(index_input);
      hits_output.zAtYEq0(index_output) = hits_input.zAtYEq0(index_input);
      hits_output.xAtYEq0(index_output) = hits_input.xAtYEq0(index_input);
      hits_output.dxDy(index_output) = hits_input.dxDy(index_input);
      hits_output.weight(index_output) = hits_input.weight(index_input);
      hits_output.id(index_output) = hits_input.id(index_input);
    }
  }
}

void create_reduced_ut_hits_container::create_reduced_ut_hits_container_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_ut_hit_offsets_t>(arguments, size<dev_ut_hit_offsets_input_t>(arguments));
  set_size<host_number_of_ut_hits_t>(arguments, 1);
}

void create_reduced_ut_hits_container::create_reduced_ut_hits_container_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  // Only happen when UT hit container is empty
  if (size<dev_used_ut_hits_offsets_t>(arguments) == 0 || size<dev_ut_hits_input_t>(arguments) == 0) {
    data<host_number_of_ut_hits_t>(arguments)[0] = 0;
    Allen::memset_async<dev_ut_hit_offsets_t>(arguments, 0, context);
    return;
  }
  // Calculate dev_ut_hit_offsets_t
  auto host_used_ut_hits_offsets = make_host_buffer<dev_used_ut_hits_offsets_t>(arguments, context);
  auto host_ut_hit_offsets_input = make_host_buffer<dev_ut_hit_offsets_input_t>(arguments, context);
  auto host_ut_hit_offsets = make_host_buffer<unsigned>(arguments, size<dev_ut_hit_offsets_t>(arguments));
  for (unsigned i = 0; i < host_ut_hit_offsets_input.size(); ++i) {
    auto expected_number_of_hits = host_ut_hit_offsets_input[i];
    auto unused_number_of_hits = expected_number_of_hits - host_used_ut_hits_offsets[expected_number_of_hits];
    host_ut_hit_offsets[i] = unused_number_of_hits;
  }
  Allen::memcpy_async(
    data<dev_ut_hit_offsets_t>(arguments),
    host_ut_hit_offsets.data(),
    host_ut_hit_offsets.size_bytes(),
    Allen::memcpyHostToDevice,
    context);

  // Calculate number of ut hits of the new container
  data<host_number_of_ut_hits_t>(arguments)[0] = host_ut_hit_offsets[host_ut_hit_offsets.size() - 1];

  // Resize dev_ut_hits_t to hold all hits
  resize<dev_ut_hits_t>(arguments, first<host_number_of_ut_hits_t>(arguments) * UT::Hits::element_size);

  // Populate dev_ut_hits_t
  global_function(create_ut_hit_container)(size<dev_event_list_t>(arguments), dim3(m_block_dim_x), context)(arguments);
}

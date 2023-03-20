/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "CreateReducedSciFiHitContainer.cuh"

INSTANTIATE_ALGORITHM(create_reduced_scifi_hit_container::create_reduced_scifi_hit_container_t)

__global__ void create_scifi_hit_container(create_reduced_scifi_hit_container::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  SciFi::ConstHits hits_input {
    parameters.dev_scifi_hits_input,
    parameters.dev_scifi_hit_offsets_input[number_of_events * SciFi::Constants::n_mat_groups_and_mats]};
  SciFi::ConstHitCount hit_count_input {parameters.dev_scifi_hit_offsets_input, event_number};

  SciFi::Hits hits_output {
    parameters.dev_scifi_hits,
    parameters.dev_scifi_hit_offsets[number_of_events * SciFi::Constants::n_mat_groups_and_mats]};

  const auto event_offset_input = hit_count_input.event_offset();
  for (unsigned i = threadIdx.x; i < hit_count_input.event_number_of_hits(); i += blockDim.x) {
    const auto index_input = event_offset_input + i;
    if (
      (parameters.dev_used_scifi_hits_offsets[index_input + 1] - parameters.dev_used_scifi_hits_offsets[index_input]) ==
      0) {
      const auto index_output = index_input - parameters.dev_used_scifi_hits_offsets[index_input];
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
  // Calculate dev_scifi_hit_offsets_t
  // Use dev_scifi_hit_offsets_input_t as the expected number of hits.
  // Use host_used_scifi_hits_offsets to determine how many hits are used (count only the unused)
  auto host_scifi_hit_offsets_input = make_host_buffer<dev_scifi_hit_offsets_input_t>(arguments, context);
  auto host_scifi_hit_offsets = make_host_buffer<unsigned>(arguments, size<dev_scifi_hit_offsets_t>(arguments));
  for (unsigned i = 0; i < host_scifi_hit_offsets_input.size(); ++i) {
    auto expected_number_of_hits = host_scifi_hit_offsets_input[i];
    auto unused_number_of_hits =
      expected_number_of_hits - data<host_used_scifi_hits_offsets_t>(arguments)[expected_number_of_hits];
    host_scifi_hit_offsets[i] = unused_number_of_hits;
  }
  Allen::memcpy_async(
    data<dev_scifi_hit_offsets_t>(arguments),
    host_scifi_hit_offsets.data(),
    host_scifi_hit_offsets.size_bytes(),
    Allen::memcpyHostToDevice,
    context);

  // Calculate number of scifi hits of the new container
  data<host_number_of_scifi_hits_t>(arguments)[0] = host_scifi_hit_offsets[host_scifi_hit_offsets.size() - 1];

  // Resize dev_scifi_hits_t to hold all hits
  resize<dev_scifi_hits_t>(
    arguments, first<host_number_of_scifi_hits_t>(arguments) * SciFi::Hits::number_of_arrays * sizeof(uint32_t));

  // Populate dev_scifi_hits_t
  global_function(create_scifi_hit_container)(size<dev_event_list_t>(arguments), property<block_dim_x_t>(), context)(
    arguments);
}

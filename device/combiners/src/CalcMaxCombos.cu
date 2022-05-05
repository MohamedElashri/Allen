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
#include "CalcMaxCombos.cuh"

INSTANTIATE_ALGORITHM(CalcMaxCombos::calc_max_combos_t)

void CalcMaxCombos::calc_max_combos_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  const auto dev_input_agg = input_aggregate<dev_input_agg_t>(arguments);
  set_size<dev_max_combos_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_input_containers_t>(arguments, dev_input_agg.size_of_aggregate());
}

void CalcMaxCombos::calc_max_combos_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  const auto dev_input_agg = input_aggregate<dev_input_agg_t>(arguments);
  Allen::memset_async<dev_max_combos_t>(arguments, 0, context);
  Allen::aggregate::store_contiguous_async<dev_input_containers_t, dev_input_agg_t>(arguments, context);
  global_function(calc_max_combos)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, dev_input_agg.size_of_aggregate());
}

__global__ void CalcMaxCombos::calc_max_combos(
  CalcMaxCombos::Parameters parameters,
  const unsigned number_of_input_containers)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const auto mec1 = parameters.dev_input_containers[0];
  unsigned n_input1 = 0;
  const auto basic_mec1 = Allen::dyn_cast<const Allen::Views::Physics::MultiEventBasicParticles*>(mec1);
  if (basic_mec1) {
    const auto particles = basic_mec1->container(event_number);
    n_input1 = particles.size();
  }
  else {
    const auto comp_mec1 = Allen::dyn_cast<const Allen::Views::Physics::MultiEventCompositeParticles*>(mec1);
    if (comp_mec1) {
      const auto particles = comp_mec1->container(event_number);
      n_input1 = particles.size();
    }
  }

  if (number_of_input_containers == 1) {
    parameters.dev_max_combos[event_number] = n_input1 * (n_input1 - 1) / 2;
    return;
  }

  const auto mec2 = parameters.dev_input_containers[1];
  unsigned n_input2 = 0;
  const auto basic_mec2 = Allen::dyn_cast<const Allen::Views::Physics::MultiEventBasicParticles*>(mec2);
  if (basic_mec2) {
    const auto particles = basic_mec2->container(event_number);
    n_input2 = particles.size();
  }
  else {
    const auto comp_mec2 = Allen::dyn_cast<const Allen::Views::Physics::MultiEventCompositeParticles*>(mec2);
    if (comp_mec2) {
      const auto particles = comp_mec2->container(event_number);
      n_input2 = particles.size();
    }
  }

  parameters.dev_max_combos[event_number] = n_input1 * n_input2;
  return;
}
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

#include "DownstreamCompositeSelector.cuh"

INSTANTIATE_ALGORITHM(downstream_composite_selector::downstream_composite_selector_t)

void downstream_composite_selector::downstream_composite_selector_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_downstream_mva_l0_t>(arguments, first<host_number_of_downstream_secondary_vertices_t>(arguments));
  set_size<dev_downstream_mva_ks_t>(arguments, first<host_number_of_downstream_secondary_vertices_t>(arguments));
  set_size<dev_downstream_mva_detached_l0_t>(
    arguments, first<host_number_of_downstream_secondary_vertices_t>(arguments));
  set_size<dev_downstream_mva_detached_ks_t>(
    arguments, first<host_number_of_downstream_secondary_vertices_t>(arguments));
}

void downstream_composite_selector::downstream_composite_selector_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_downstream_mva_l0_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_mva_ks_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_mva_detached_l0_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_mva_detached_ks_t>(arguments, 0, context);

  global_function(downstream_composite_selector)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    lambda_selector.getDevicePointer(),
    ks_selector.getDevicePointer(),
    lambda_detached_selector.getDevicePointer(),
    ks_detached_selector.getDevicePointer());

  // const auto host_downstream_mva_l0 = make_host_buffer<dev_downstream_mva_l0_t>(arguments, context);
}

__global__ void downstream_composite_selector::downstream_composite_selector(
  downstream_composite_selector::Parameters parameters,
  const PromptSelector::DeviceType* dev_downstream_lambda_selector,
  const PromptSelector::DeviceType* dev_downstream_kshort_selector,
  const DetachedSelector::DeviceType* dev_downstream_detached_lambda_selector,
  const DetachedSelector::DeviceType* dev_downstream_detached_kshort_selector)
{
  // Basic
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Fetch input
  const auto downstream_composites = parameters.dev_multi_event_composites_view->container(event_number);
  const auto num_composites = downstream_composites.size();

  // Output
  auto downstream_kshort_selector = parameters.dev_downstream_mva_ks + downstream_composites.offset();
  auto downstream_lambda_selector = parameters.dev_downstream_mva_l0 + downstream_composites.offset();
  auto downstream_detached_kshort_selector = parameters.dev_downstream_mva_detached_ks + downstream_composites.offset();
  auto downstream_detached_lambda_selector = parameters.dev_downstream_mva_detached_l0 + downstream_composites.offset();

  for (unsigned composite_idx = threadIdx.x; composite_idx < num_composites; composite_idx += blockDim.x) {
    // Fetch composite info
    const auto downstream_composite = downstream_composites.particle(composite_idx);
    const auto downstream_vertex = downstream_composite.vertex();

    // Fetch daughters
    const auto dA = static_cast<const Allen::Views::Physics::BasicParticle*>(downstream_composite.child(0));
    const auto dB = static_cast<const Allen::Views::Physics::BasicParticle*>(downstream_composite.child(1));

    // Daughters info
    const auto dA_ip = dA->ownpv_ip();
    const auto dB_ip = dB->ownpv_ip();
    // const auto dA_p = dA->state().p();
    // const auto dB_p = dB->state().p();
    const auto dA_pt = dA->state().pt();
    const auto dB_pt = dB->state().pt();

    // NN inputs
    const auto fd = downstream_composite.fd();
    const auto doca = downstream_vertex.downstream_doca();
    const auto max_ip = max(dA_ip, dB_ip);
    const auto min_ip = min(dA_ip, dB_ip);
    const auto max_pt = max(dA_pt, dB_pt);
    const auto min_pt = min(dA_pt, dB_pt);
    const auto pt = downstream_vertex.pt();
    const auto dira = downstream_composite.dira();
    const auto ip = downstream_composite.ownpv_ip();
    const auto tx = downstream_vertex.px() / downstream_vertex.pz();
    const auto ty = downstream_vertex.py() / downstream_vertex.pz();
    const auto eta_simple = asinhf(1.f / hypotf(tx, ty));
    const auto dira_angle = acosf(dira > 1.f ? 1.f : dira);

    // Compute scores
    float inputs_lambda[PromptSelector::DeviceType::nInput] = {
      doca, logf(min_ip), logf(max_ip), logf(min_pt), logf(max_pt), logf(min_pt + max_pt), fd, eta_simple};
    downstream_lambda_selector[composite_idx] = dev_downstream_lambda_selector->evaluate(inputs_lambda);

    float inputs_detached_lambda[DetachedSelector::DeviceType::nInput] = {
      fd, eta_simple, dira_angle, logf(ip), logf(pt), logf(min_ip), logf(max_ip)};
    downstream_detached_lambda_selector[composite_idx] =
      dev_downstream_detached_lambda_selector->evaluate(inputs_detached_lambda);

    float inputs_kshort[PromptSelector::DeviceType::nInput] = {
      doca, logf(min_ip), logf(max_ip), logf(min_pt), logf(max_pt), logf(min_pt + max_pt), fd, eta_simple};
    downstream_kshort_selector[composite_idx] = dev_downstream_kshort_selector->evaluate(inputs_kshort);

    float inputs_detached_kshort[DetachedSelector::DeviceType::nInput] = {
      fd, eta_simple, dira_angle, logf(ip), logf(pt), logf(min_ip), logf(max_ip)};
    downstream_detached_kshort_selector[composite_idx] =
      dev_downstream_detached_kshort_selector->evaluate(inputs_detached_kshort);
  }
  __syncthreads();
}

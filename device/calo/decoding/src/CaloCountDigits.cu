/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <MEPTools.h>
#include <CaloCountDigits.cuh>
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(calo_count_digits::calo_count_digits_t)

__global__ void calo_count_digits::calo_count_digits(
  calo_count_digits::Parameters parameters,
  unsigned const n_events,
  const char* raw_ecal_geometry)
{
  // ECal
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);

  for (unsigned event_index = threadIdx.x; event_index < n_events; event_index += blockDim.x) {
    auto event_number = parameters.dev_event_list[event_index];
    parameters.dev_digits_offsets[event_number] = ecal_geometry.max_index;
  }
}

void calo_count_digits::calo_count_digits_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_digits_offsets_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_total_sum_holder_t>(arguments, 1);
}

void calo_count_digits::calo_count_digits_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_digits_offsets_t>(arguments, 0, context);

  global_function(calo_count_digits)(dim3(1), dim3(m_block_dim_x), context)(
    arguments, size<dev_event_list_t>(arguments), constants.dev_ecal_geometry);

  PrefixSum::prefix_sum<dev_digits_offsets_t, host_total_sum_holder_t>(*this, arguments, context);
}

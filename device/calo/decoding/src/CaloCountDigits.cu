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
#include <CaloDecodeKernels.cuh>

__device__ void
offsets(mask_t const* event_list, unsigned const n_events, unsigned* number_of_digits, CaloGeometry const& geometry)
{
  for (unsigned idx = threadIdx.x; idx < n_events; idx += blockDim.x) {
    auto event_number = event_list[idx];
    number_of_digits[event_number] = geometry.max_index;
  }
}

__global__ void calo_count_digits::calo_count_digits(
  calo_count_digits::Parameters parameters,
  unsigned const n_events,
  const char* raw_ecal_geometry)
{
  // ECal
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  offsets(parameters.dev_event_list, n_events, parameters.dev_ecal_num_digits, ecal_geometry);
}

void calo_count_digits::calo_count_digits_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ecal_num_digits_t>(arguments, first<host_number_of_events_t>(arguments));
}

void calo_count_digits::calo_count_digits_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_ecal_num_digits_t>(arguments, 0, context);

  global_function(calo_count_digits)(dim3(1), dim3(property<block_dim_x_t>().get()), context)(
    arguments, size<dev_event_list_t>(arguments), constants.dev_ecal_geometry);
}

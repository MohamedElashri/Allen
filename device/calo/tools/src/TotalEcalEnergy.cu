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
#include "TotalEcalEnergy.cuh"

INSTANTIATE_ALGORITHM(total_ecal_energy::total_ecal_energy_t)

void total_ecal_energy::total_ecal_energy_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_total_ecal_e_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_ecal_digits_e_t>(arguments, first<host_ecal_number_of_digits_t>(arguments));
}

void total_ecal_energy::total_ecal_energy_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  Allen::Context const& context) const
{
  Allen::memset_async<dev_total_ecal_e_t>(arguments, 0, context);
  Allen::memset_async<dev_ecal_digits_e_t>(arguments, 0, context);

  global_function(sum_ecal_energy)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_x_t>(), context)(
    arguments, constants.dev_ecal_geometry);
}

__global__ void total_ecal_energy::sum_ecal_energy(
  total_ecal_energy::Parameters parameters,
  const char* raw_ecal_geometry)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  const unsigned digits_offset = parameters.dev_ecal_digits_offsets[event_number];
  const unsigned n_digits = parameters.dev_ecal_digits_offsets[event_number + 1] - digits_offset;
  auto const* digits = parameters.dev_ecal_digits + digits_offset;
  float* event_ecal_digits_e = parameters.dev_ecal_digits_e + digits_offset;

  for (unsigned digit_index = threadIdx.x; digit_index < n_digits; digit_index += blockDim.x) {
    event_ecal_digits_e[digit_index] = ecal_geometry.getE(digit_index, digits[digit_index].adc);
  }

  __syncthreads();

  if (threadIdx.x == 0) {
    float e_sum = 0.f;
    for (unsigned digit_index = 0; digit_index < n_digits; digit_index++)
      e_sum += event_ecal_digits_e[digit_index];
    parameters.dev_total_ecal_e[event_number] = e_sum;
  }
}
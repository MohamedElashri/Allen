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
#include "SumReduction.cuh"

INSTANTIATE_ALGORITHM(total_ecal_energy::total_ecal_energy_t)

void total_ecal_energy::total_ecal_energy_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_total_ecal_e_t>(arguments, size<dev_event_list_t>(arguments));
}

void total_ecal_energy::total_ecal_energy_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  Allen::Context const& context) const
{
  Allen::memset_async<dev_total_ecal_e_t>(arguments, 0, context);

  auto dev_ecal_digits_e =
    arguments.template make_buffer<Allen::Store::Scope::Device, float>(first<host_ecal_number_of_digits_t>(arguments));

  global_function(get_ecal_energy)(dim3(size<dev_event_list_t>(arguments)), dim3(m_block_dim_x), context)(
    arguments, constants.dev_ecal_geometry, dev_ecal_digits_e.data());

  SumReduction::sum_reduction(
    *this,
    context,
    dev_ecal_digits_e.data(),
    data<dev_ecal_digits_offsets_t>(arguments),
    size<dev_event_list_t>(arguments),
    data<dev_total_ecal_e_t>(arguments));
}

__global__ void total_ecal_energy::get_ecal_energy(
  total_ecal_energy::Parameters parameters,
  const char* raw_ecal_geometry,
  float* dev_ecal_digits_e)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  const unsigned digits_offset = parameters.dev_ecal_digits_offsets[event_number];
  const unsigned n_digits = parameters.dev_ecal_digits_offsets[event_number + 1] - digits_offset;
  auto const* digits = parameters.dev_ecal_digits + digits_offset;
  float* event_ecal_digits_e = dev_ecal_digits_e + digits_offset;

  for (unsigned digit_index = threadIdx.x; digit_index < n_digits; digit_index += blockDim.x) {
    const auto digit = digits[digit_index];
    if (digit.is_valid() && digit.adc > 0) {
      event_ecal_digits_e[digit_index] = ecal_geometry.getE(digit_index, digit.adc);
    }
  }
}

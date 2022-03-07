/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <CalculateNumberOfRetinaClustersPerSensor.cuh>

INSTANTIATE_ALGORITHM(calculate_number_of_retinaclusters_each_sensor::calculate_number_of_retinaclusters_each_sensor_t)

template<bool mep_layout>
__global__ void calculate_number_of_retinaclusters_each_sensor_kernel(
  calculate_number_of_retinaclusters_each_sensor::Parameters parameters)
{
  const auto event_number = parameters.dev_event_list[blockIdx.x];
  unsigned* each_sensor_size =
    parameters.dev_each_sensor_size + event_number * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module;

  // Read raw event
  const auto velo_raw_event = Velo::RawEvent<mep_layout> {
    parameters.dev_velo_retina_raw_input, parameters.dev_velo_retina_raw_input_offsets, parameters.dev_velo_retina_raw_input_sizes, event_number};

  unsigned number_of_raw_banks = velo_raw_event.number_of_raw_banks();
  for (unsigned raw_bank_number = threadIdx.x; raw_bank_number < number_of_raw_banks; raw_bank_number += blockDim.x) {
    const auto raw_bank = velo_raw_event.raw_bank(raw_bank_number);
    each_sensor_size[raw_bank.sensor_index] = raw_bank.count;
  }
}

void calculate_number_of_retinaclusters_each_sensor::calculate_number_of_retinaclusters_each_sensor_t::
  set_arguments_size(
    ArgumentReferences<Parameters> arguments,
    const RuntimeOptions&,
    const Constants&,
    const HostBuffers&) const
{
  set_size<dev_each_sensor_size_t>(
    arguments,
    first<host_number_of_events_t>(arguments) * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module);
}

void calculate_number_of_retinaclusters_each_sensor::calculate_number_of_retinaclusters_each_sensor_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_each_sensor_size_t>(arguments, 0, context);

  global_function(
    runtime_options.mep_layout ? calculate_number_of_retinaclusters_each_sensor_kernel<true> :
                                 calculate_number_of_retinaclusters_each_sensor_kernel<false>)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);
}

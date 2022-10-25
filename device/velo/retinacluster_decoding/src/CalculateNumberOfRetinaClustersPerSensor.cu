/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <iostream>
#include <iomanip>
#include <MEPTools.h>
#include <CalculateNumberOfRetinaClustersPerSensor.cuh>

INSTANTIATE_ALGORITHM(
  calculate_number_of_retinaclusters_each_sensor_pair::calculate_number_of_retinaclusters_each_sensor_pair_t)

template<int decoding_version, bool mep_layout>
__global__ void calculate_number_of_retinaclusters_each_sensor_pair_kernel(
  calculate_number_of_retinaclusters_each_sensor_pair::Parameters parameters,
  const unsigned event_start)
{
  const auto event_number = parameters.dev_event_list[blockIdx.x];
  unsigned* each_sensor_pair_size = nullptr;

  if constexpr (decoding_version == 2 || decoding_version == 3) {
    each_sensor_pair_size = parameters.dev_each_sensor_pair_size +
                            event_number * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module;
  }
  else {
    each_sensor_pair_size = parameters.dev_each_sensor_pair_size +
                            event_number * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module / 2;
  }

  // Read raw event
  const auto velo_raw_event =
    Velo::RawEvent<decoding_version, mep_layout> {parameters.dev_velo_retina_raw_input,
                                                  parameters.dev_velo_retina_raw_input_offsets,
                                                  parameters.dev_velo_retina_raw_input_sizes,
                                                  parameters.dev_velo_retina_raw_input_types,
                                                  event_number + event_start};

  unsigned number_of_raw_banks = velo_raw_event.number_of_raw_banks();
  for (unsigned raw_bank_number = threadIdx.x; raw_bank_number < number_of_raw_banks; raw_bank_number += blockDim.x) {
    const auto raw_bank = velo_raw_event.raw_bank(raw_bank_number);
    if (raw_bank.type == LHCb::RawBank::VPRetinaCluster) {
      if constexpr (decoding_version == 2 || decoding_version == 3) {
        each_sensor_pair_size[raw_bank.sourceID] = raw_bank.count;
      }
      else {
        each_sensor_pair_size[raw_bank.sensor_pair()] = raw_bank.size / 4;
      }
    }
    if (blockIdx.x == 0) {
      parameters.dev_retina_bank_index[raw_bank.sensor_pair()] = raw_bank_number;
    }
  }
}

void calculate_number_of_retinaclusters_each_sensor_pair::calculate_number_of_retinaclusters_each_sensor_pair_t::
  set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const
{
  const auto bank_version = first<host_raw_bank_version_t>(arguments);
  unsigned size = Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module;
  if (bank_version != 2 && bank_version != 3) {
    size /= 2;
  }
  set_size<dev_each_sensor_pair_size_t>(arguments, first<host_number_of_events_t>(arguments) * size);
  set_size<dev_retina_bank_index_t>(arguments, size); // divide by 2 for sensor pair
}

void calculate_number_of_retinaclusters_each_sensor_pair::calculate_number_of_retinaclusters_each_sensor_pair_t::
operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_each_sensor_pair_size_t>(arguments, 0, context);
  const auto bank_version = first<host_raw_bank_version_t>(arguments);

  if (bank_version < 0) {
    Allen::memset_async<dev_retina_bank_index_t>(arguments, 0, context);
    return; // no VP banks present in data
  }

  auto kernel_fn = (bank_version == 2) ?
                     (runtime_options.mep_layout ?
                        global_function(calculate_number_of_retinaclusters_each_sensor_pair_kernel<2, true>) :
                        global_function(calculate_number_of_retinaclusters_each_sensor_pair_kernel<2, false>)) :
                     (bank_version == 3) ?
                     (runtime_options.mep_layout ?
                        global_function(calculate_number_of_retinaclusters_each_sensor_pair_kernel<3, true>) :
                        global_function(calculate_number_of_retinaclusters_each_sensor_pair_kernel<3, false>)) :
                     (runtime_options.mep_layout ?
                        global_function(calculate_number_of_retinaclusters_each_sensor_pair_kernel<4, true>) :
                        global_function(calculate_number_of_retinaclusters_each_sensor_pair_kernel<4, false>));

  kernel_fn(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, std::get<0>(runtime_options.event_interval));
}

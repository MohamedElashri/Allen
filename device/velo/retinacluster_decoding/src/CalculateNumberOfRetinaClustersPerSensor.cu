/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <CalculateNumberOfRetinaClustersPerSensor.cuh>

// __global__ void calculate_number_of_retinaclusters_each_sensor::calculate_number_of_retinaclusters_each_sensor(calculate_number_of_retinaclusters_each_sensor::Parameters parameters)
// {
//   const auto event_number = blockIdx.x;
//   const auto selected_event_number = parameters.dev_event_list[event_number];
// 
//   const char* raw_input = parameters.dev_velo_retina_raw_input + parameters.dev_velo_retina_raw_input_offsets[selected_event_number];
//   uint* each_sensor_size = parameters.dev_each_sensor_size + event_number * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module;
// 
//   // Read raw event
//   const auto raw_event = VeloRawEvent(raw_input);
// 
//   for (uint raw_bank_number = threadIdx.x; raw_bank_number < raw_event.number_of_raw_banks;
//        raw_bank_number += blockDim.x) {
//     // Read raw bank
//     const auto raw_bank = VeloRawBank(raw_event.payload + raw_event.raw_bank_offset[raw_bank_number]);
//     each_sensor_size[raw_bank.sensor_index] = raw_bank.count;
//   }
// 
// }
// __global__ void calculate_number_of_retinaclusters_each_sensor::calculate_number_of_retinaclusters_each_sensor_mep(calculate_number_of_retinaclusters_each_sensor::Parameters parameters)
// {
//   const uint event_number = blockIdx.x;
//   const uint selected_event_number = parameters.dev_event_list[event_number];
// 
//   uint* each_sensor_size = parameters.dev_each_sensor_size + event_number * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module;
// 
//   // Read raw event
//   auto const number_of_raw_banks = parameters.dev_velo_retina_raw_input_offsets[0];
// 
//   for (uint raw_bank_number = threadIdx.x; raw_bank_number < number_of_raw_banks; raw_bank_number += blockDim.x) {
// 
//     // Create raw bank from MEP layout
//     const auto raw_bank = MEP::raw_bank<VeloRawBank>(
//       parameters.dev_velo_retina_raw_input, parameters.dev_velo_retina_raw_input_offsets, selected_event_number, raw_bank_number);
//     each_sensor_size[raw_bank.sensor_index] = raw_bank.count;
//   }
// }

template<bool mep_layout>
__global__ void calculate_number_of_retinaclusters_each_sensor_kernel(calculate_number_of_retinaclusters_each_sensor::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const uint selected_event_number = parameters.dev_event_list[event_number];
//   unsigned* estimated_input_size = parameters.dev_estimated_input_size + event_number * Velo::Constants::n_module_pairs;
  uint* each_sensor_size = parameters.dev_each_sensor_size + event_number * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module;
  
//   unsigned* event_candidate_num = parameters.dev_module_candidate_num + event_number;
//   uint32_t* cluster_candidates = parameters.dev_cluster_candidates + parameters.dev_candidates_offsets[event_number];

  // Read raw event
  unsigned number_of_raw_banks;
  if constexpr (mep_layout) {
    number_of_raw_banks = parameters.dev_velo_retina_raw_input_offsets[0];
  }
  else {
    const char* raw_input = parameters.dev_velo_retina_raw_input + parameters.dev_velo_retina_raw_input_offsets[selected_event_number];
    const auto raw_event = VeloRawEvent(raw_input);
    number_of_raw_banks = raw_event.number_of_raw_banks;
  }

  for (unsigned raw_bank_number = threadIdx.y; raw_bank_number < number_of_raw_banks; raw_bank_number += blockDim.y) {
    VeloRawBank raw_bank;
    if constexpr (mep_layout) {
      raw_bank = MEP::raw_bank<VeloRawBank>(parameters.dev_velo_retina_raw_input, parameters.dev_velo_retina_raw_input_offsets, selected_event_number, raw_bank_number);
    }
    else {
      const char* raw_input = parameters.dev_velo_retina_raw_input + parameters.dev_velo_retina_raw_input_offsets[selected_event_number];
      const auto raw_event = VeloRawEvent(raw_input);
      raw_bank = VeloRawBank(raw_event.payload + raw_event.raw_bank_offset[raw_bank_number]);
    }

    each_sensor_size[raw_bank.sensor_index] = raw_bank.count;
  }
}

void calculate_number_of_retinaclusters_each_sensor::calculate_number_of_retinaclusters_each_sensor_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_each_sensor_size_t>(
    arguments, first<host_number_of_events_t>(arguments) * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module);
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
    runtime_options.mep_layout ? calculate_number_of_retinaclusters_each_sensor_kernel<true> : calculate_number_of_retinaclusters_each_sensor_kernel<false>)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);
}

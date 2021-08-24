#include <MEPTools.h>
#include <CalculateNumberOfRetinaClustersPerSensor.cuh>

void calculate_number_of_retinaclusters_each_sensor::calculate_number_of_retinaclusters_each_sensor_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  if (logger::verbosity() >= logger::debug) {
    debug_cout << "# of events = " << first<host_number_of_selected_events_t>(arguments) << std::endl;
      }

  set_size<dev_each_sensor_size_t>(
    arguments, first<host_number_of_selected_events_t>(arguments) * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module);
}

void calculate_number_of_retinaclusters_each_sensor::calculate_number_of_retinaclusters_each_sensor_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  initialize<dev_each_sensor_size_t>(arguments, 0, cuda_stream);

  if (runtime_options.mep_layout) {
    global_function(calculate_number_of_retinaclusters_each_sensor_mep)(dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(arguments);
  }
  else {
    global_function(calculate_number_of_retinaclusters_each_sensor)(
      dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(arguments);
  }
}

__global__ void calculate_number_of_retinaclusters_each_sensor::calculate_number_of_retinaclusters_each_sensor(calculate_number_of_retinaclusters_each_sensor::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const auto selected_event_number = parameters.dev_event_list[event_number];

  const char* raw_input = parameters.dev_velo_retina_raw_input + parameters.dev_velo_retina_raw_input_offsets[selected_event_number];
  uint* each_sensor_size = parameters.dev_each_sensor_size + event_number * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module;

  // Read raw event
  const auto raw_event = VeloRawEvent(raw_input);

  for (uint raw_bank_number = threadIdx.x; raw_bank_number < raw_event.number_of_raw_banks;
       raw_bank_number += blockDim.x) {
    // Read raw bank
    const auto raw_bank = VeloRawBank(raw_event.payload + raw_event.raw_bank_offset[raw_bank_number]);
    each_sensor_size[raw_bank.sensor_index] = raw_bank.count;
  }

}
__global__ void calculate_number_of_retinaclusters_each_sensor::calculate_number_of_retinaclusters_each_sensor_mep(calculate_number_of_retinaclusters_each_sensor::Parameters parameters)
{
  const uint event_number = blockIdx.x;
  const uint selected_event_number = parameters.dev_event_list[event_number];

  uint* each_sensor_size = parameters.dev_each_sensor_size + event_number * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module;

  // Read raw event
  auto const number_of_raw_banks = parameters.dev_velo_retina_raw_input_offsets[0];

  for (uint raw_bank_number = threadIdx.x; raw_bank_number < number_of_raw_banks; raw_bank_number += blockDim.x) {

    // Create raw bank from MEP layout
    const auto raw_bank = MEP::raw_bank<VeloRawBank>(
      parameters.dev_velo_retina_raw_input, parameters.dev_velo_retina_raw_input_offsets, selected_event_number, raw_bank_number);
    each_sensor_size[raw_bank.sensor_index] = raw_bank.count;
  }
}

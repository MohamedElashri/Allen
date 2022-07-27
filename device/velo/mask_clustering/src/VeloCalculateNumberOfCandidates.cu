/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <VeloCalculateNumberOfCandidates.cuh>

INSTANTIATE_ALGORITHM(velo_calculate_number_of_candidates::velo_calculate_number_of_candidates_t)

template<int decoding_version, bool mep_layout>
__global__ void velo_calculate_number_of_candidates_kernel(
  velo_calculate_number_of_candidates::Parameters parameters,
  const unsigned number_of_events)
{
  for (auto event_index = blockIdx.x * blockDim.x + threadIdx.x; event_index < number_of_events;
       event_index += blockDim.x * gridDim.x) {
    const auto event_number = parameters.dev_event_list[event_index];

    const auto velo_raw_event = Velo::RawEvent<decoding_version, mep_layout> {parameters.dev_velo_raw_input,
                                                                              parameters.dev_velo_raw_input_offsets,
                                                                              parameters.dev_velo_raw_input_sizes,
                                                                              parameters.dev_velo_raw_input_types,
                                                                              event_number};
    unsigned number_of_candidates = 0;
    for (unsigned raw_bank_number = 0; raw_bank_number < velo_raw_event.number_of_raw_banks(); ++raw_bank_number) {
      const auto raw_bank = velo_raw_event.raw_bank(raw_bank_number);
      if (raw_bank.type == LHCb::RawBank::VP || raw_bank.type == LHCb::RawBank::Velo) {
        if constexpr (decoding_version == 2 || decoding_version == 3) {
          number_of_candidates += raw_bank.count;
        }
        else {
          number_of_candidates += raw_bank.size / 4;
        }
      }
      if (blockIdx.x == 0) {
        if constexpr (decoding_version > 3) {
          parameters.dev_velo_bank_index[raw_bank.sensor_index0()] = raw_bank_number;
          parameters.dev_velo_bank_index[raw_bank.sensor_index1()] = raw_bank_number;
        }
        else {
          parameters.dev_velo_bank_index[raw_bank.sensor_pair()] = raw_bank_number;
        }
      }
    }
    // The maximum number of candidates is two times the number of SPs
    parameters.dev_number_of_candidates[event_number] = 2 * number_of_candidates;
  }
}

void velo_calculate_number_of_candidates::velo_calculate_number_of_candidates_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_number_of_candidates_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_velo_bank_index_t>(arguments, Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module);
}

void velo_calculate_number_of_candidates::velo_calculate_number_of_candidates_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_number_of_candidates_t>(arguments, 0, context);
  unsigned int const bank_version = first<host_raw_bank_version_t>(arguments);

  // Enough blocks to cover all events
  const auto grid_size =
    dim3((size<dev_event_list_t>(arguments) + property<block_dim_x_t>() - 1) / property<block_dim_x_t>());

  auto kernel_fn =
    (bank_version == 2) ?
      (runtime_options.mep_layout ? global_function(velo_calculate_number_of_candidates_kernel<2, true>) :
                                    global_function(velo_calculate_number_of_candidates_kernel<2, false>)) :
      (bank_version == 3) ?
      (runtime_options.mep_layout ? global_function(velo_calculate_number_of_candidates_kernel<3, true>) :
                                    global_function(velo_calculate_number_of_candidates_kernel<3, false>)) :
      (runtime_options.mep_layout ? global_function(velo_calculate_number_of_candidates_kernel<4, true>) :
                                    global_function(velo_calculate_number_of_candidates_kernel<4, false>));

  kernel_fn(grid_size, dim3(property<block_dim_x_t>().get()), context)(arguments, size<dev_event_list_t>(arguments));
}

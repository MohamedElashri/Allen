/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <UTDecodingGetBankOffsets.cuh>
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(ut_decoding_get_bank_offsets::ut_decoding_get_bank_offsets_t)

void ut_decoding_get_bank_offsets::ut_decoding_get_bank_offsets_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_ut_banks_offsets_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_total_number_of_ut_banks_t>(arguments, 1);
}

void ut_decoding_get_bank_offsets::ut_decoding_get_bank_offsets_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  auto const bank_version = first<host_raw_bank_version_t>(arguments);

  // Protect no UT sequence
  if (bank_version < 0) {
    Allen::memset_async<dev_ut_banks_offsets_t>(arguments, 0, context);
    Allen::memset_async<host_total_number_of_ut_banks_t>(arguments, 0, context);
    return;
  }

  // Basics
  const auto event_start = std::get<0>(runtime_options.event_interval);

  // Fill bank numbers
  auto global_func = runtime_options.mep_layout ? global_function(ut_decoding_get_number_of_banks<true>) :
                                                  global_function(ut_decoding_get_number_of_banks<false>);

  Allen::memset_async<dev_ut_banks_offsets_t>(arguments, 0, context);

  global_func(dim3(1), m_block_dim, context)(arguments, event_start, size<dev_event_list_t>(arguments));

  // Compute bank offsets
  PrefixSum::prefix_sum<dev_ut_banks_offsets_t, host_total_number_of_ut_banks_t>(*this, arguments, context);

  if (m_verbosity >= logger::debug) {
    print<dev_ut_banks_offsets_t>(arguments);
    print<host_total_number_of_ut_banks_t>(arguments);
  }
}

//
// Get number of banks
//
template<bool mep>
__global__ void ut_decoding_get_bank_offsets::ut_decoding_get_number_of_banks(
  Parameters parameters,
  unsigned event_start,
  unsigned event_list_size)
{
  for (unsigned i = threadIdx.x; i < event_list_size; i += blockDim.x) {
    // Basics
    const auto event_number = parameters.dev_event_list[i];

    // Fetch raw data
    const UTRawEvent<mep> raw_event {parameters.dev_ut_raw_input,
                                     parameters.dev_ut_raw_input_offsets,
                                     parameters.dev_ut_raw_input_sizes,
                                     parameters.dev_ut_raw_input_types,
                                     event_number + event_start};

    // Fill offsets
    parameters.dev_ut_banks_offsets[event_number] = raw_event.number_of_raw_banks();
  }
}

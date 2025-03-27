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
#include <UTDecodingGetHitOffsets.cuh>
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(ut_decoding_get_hit_offsets::ut_decoding_get_hit_offsets_t)

void ut_decoding_get_hit_offsets::ut_decoding_get_hit_offsets_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Bank dependent info
  const auto num_banks = first<host_total_number_of_ut_banks_t>(arguments);
  auto const bank_version = first<host_raw_bank_version_t>(arguments);
  const auto num_lanes_per_bank = (bank_version == 4) ? UT::Decoding::v5::n_lanes : 1u;
  const auto num_lanes = num_lanes_per_bank * num_banks;

  set_size<dev_ut_lanes_hit_offsets_t>(arguments, num_lanes + 1);
  set_size<host_total_number_of_ut_hits_t>(arguments, 1);
}

void ut_decoding_get_hit_offsets::ut_decoding_get_hit_offsets_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  const auto num_banks = first<host_total_number_of_ut_banks_t>(arguments);

  // If there's not any valid UT bank, skipt it
  if (num_banks == 0) {
    Allen::memset_async<dev_ut_lanes_hit_offsets_t>(arguments, 0, context);
    Allen::memset_async<host_total_number_of_ut_hits_t>(arguments, 0, context);
    return;
  }

  // Basics
  const auto event_start = std::get<0>(runtime_options.event_interval);

  // Bank dependent info
  auto const bank_version = first<host_raw_bank_version_t>(arguments);

  Allen::memset_async<dev_ut_lanes_hit_offsets_t>(arguments, 0, context);

  // Fill number of hits
  auto global_func = bank_version == 4 ?
                       (runtime_options.mep_layout ? global_function(ut_decoding_get_number_of_hits<4, true>) :
                                                     global_function(ut_decoding_get_number_of_hits<4, false>)) :
                       (runtime_options.mep_layout ? global_function(ut_decoding_get_number_of_hits<3, true>) :
                                                     global_function(ut_decoding_get_number_of_hits<3, false>));
  global_func(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(arguments, event_start);
  PrefixSum::prefix_sum<dev_ut_lanes_hit_offsets_t, host_total_number_of_ut_hits_t>(*this, arguments, context);

  // Debuging
  if (m_verbosity >= logger::debug) {
    print<dev_ut_lanes_hit_offsets_t>(arguments);
    print<host_total_number_of_ut_hits_t>(arguments);
  }
}

template<unsigned version, bool mep>
__global__ void ut_decoding_get_hit_offsets::ut_decoding_get_number_of_hits(
  Parameters parameters,
  const unsigned event_start)
{
  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];

  // Read raw data
  const UTRawEvent<mep> raw_event {parameters.dev_ut_raw_input,
                                   parameters.dev_ut_raw_input_offsets,
                                   parameters.dev_ut_raw_input_sizes,
                                   parameters.dev_ut_raw_input_types,
                                   event_number + event_start};

  // Offsets
  const auto bank_offset = parameters.dev_ut_banks_offsets[event_number];
  const auto num_banks = parameters.dev_ut_banks_offsets[event_number + 1] - bank_offset;

  // Start
  for (unsigned bank_idx = threadIdx.x; bank_idx < num_banks; bank_idx += blockDim.x) {
    // Fetch bank
    UTRawBank<version> bank = raw_event.template raw_bank<version>(bank_idx);

    // Ignore error banks
    if (!UT::Decoding::allowed_rawbank_type(bank.type)) continue;

    // Fill results
    if constexpr (version == 4) {
      const auto hit_offset = (bank_offset + bank_idx) * UT::Decoding::v5::n_lanes;
      parameters.dev_ut_lanes_hit_offsets[hit_offset + 0] = bank.number_of_hits[0];
      parameters.dev_ut_lanes_hit_offsets[hit_offset + 1] = bank.number_of_hits[1];
      parameters.dev_ut_lanes_hit_offsets[hit_offset + 2] = bank.number_of_hits[2];
      parameters.dev_ut_lanes_hit_offsets[hit_offset + 3] = bank.number_of_hits[3];
      parameters.dev_ut_lanes_hit_offsets[hit_offset + 4] = bank.number_of_hits[4];
      parameters.dev_ut_lanes_hit_offsets[hit_offset + 5] = bank.number_of_hits[5];
    }
    else {
      parameters.dev_ut_lanes_hit_offsets[bank_offset + bank_idx] = bank.number_of_hits[0];
    }
  }
}

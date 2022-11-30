/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "HostDataProvider.h"

INSTANTIATE_ALGORITHM(host_data_provider::host_data_provider_t)

void host_data_provider::host_data_provider_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants&) const
{
  auto bno = runtime_options.input_provider->banks(m_bank_type.get_value(), runtime_options.slice_index);
  // A number of spans for the blocks equal to the number of blocks
  set_size<host_raw_banks_t>(arguments, bno.fragments.size());

  // A single span for the offsets
  set_size<host_raw_offsets_t>(arguments, 1);

  // A single span for the sizes
  set_size<host_raw_sizes_t>(arguments, 1);

  // A single span for the types
  set_size<host_raw_types_t>(arguments, 1);

  // A single number for the version
  set_size<host_raw_bank_version_t>(arguments, 1);
}

void host_data_provider::host_data_provider_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context&) const
{
  auto bno = runtime_options.input_provider->banks(m_bank_type.get_value(), runtime_options.slice_index);

  if (logger::verbosity() >= logger::debug && property<empty_t>() && bno.version != -1) {
    debug_cout << "Empty banks configured but data is there\n";
  }

  // memcpy the offsets span directly
  auto const& offsets = bno.offsets;
  ::memcpy(data<host_raw_offsets_t>(arguments), &offsets, sizeof(offsets));

  // memcpy the sizes span directly
  auto const& sizes = bno.sizes;
  ::memcpy(data<host_raw_sizes_t>(arguments), &sizes, sizeof(sizes));

  // memcpy the sizes span directly
  auto const& types = bno.types;
  ::memcpy(data<host_raw_types_t>(arguments), &types, sizeof(types));

  // Copy the spans for the blocks
  auto const& blocks = bno.fragments;
  ::memcpy(
    data<host_raw_banks_t>(arguments),
    blocks.data(),
    blocks.size() * sizeof(typename std::remove_reference_t<decltype(blocks)>::value_type));

  // Copy the bank version
  auto version = bno.version;
  ::memcpy(data<host_raw_bank_version_t>(arguments), &version, sizeof(version));
}

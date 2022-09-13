/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "DataProvider.h"

INSTANTIATE_ALGORITHM(data_provider::data_provider_t)

void data_provider::data_provider_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const HostBuffers&) const
{
  auto bno = runtime_options.input_provider->banks(m_bank_type.get_value(), runtime_options.slice_index);
  set_size<dev_raw_banks_t>(arguments, bno.fragments_mem_size);
  set_size<dev_raw_sizes_t>(arguments, bno.sizes.size());
  set_size<dev_raw_types_t>(arguments, bno.types.size());
  set_size<dev_raw_offsets_t>(arguments, bno.offsets.size());
  set_size<host_raw_bank_version_t>(arguments, 1);
}

void data_provider::data_provider_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  auto bno = runtime_options.input_provider->banks(m_bank_type.get_value(), runtime_options.slice_index);
  auto version = bno.version;

  if (property<empty_t>() && bno.version != -1) {
    if (logger::verbosity() >= logger::debug) {
      debug_cout << "Empty banks configured but data is there\n";
    }
    version = -1;
  }

  // Copy data to device
  Allen::data_to_device<dev_raw_banks_t, dev_raw_offsets_t, dev_raw_sizes_t, dev_raw_types_t>(arguments, bno, context);

  // Copy the bank version
  ::memcpy(data<host_raw_bank_version_t>(arguments), &version, sizeof(version));
}

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
#include "DataProvider.h"

INSTANTIATE_ALGORITHM(data_provider::data_provider_t)

void data_provider::data_provider_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants&) const
{
  auto bno = runtime_options.input_provider->banks(m_bank_type.value(), runtime_options.slice_index);
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
  const Allen::Context& context) const
{
  auto bno = runtime_options.input_provider->banks(m_bank_type.value(), runtime_options.slice_index);
  auto version = bno.version;

  if (m_empty.value() && bno.version != -1) {
    if (logger::verbosity() >= logger::debug) {
      debug_cout << "Empty banks configured but data is there\n";
    }
    version = -1;
  }

  // Copy data to device
  if (version != -1)
    Allen::data_to_device<dev_raw_banks_t, dev_raw_offsets_t, dev_raw_sizes_t, dev_raw_types_t>(
      arguments, bno, context);

  // Copy the bank version
  ::memcpy(data<host_raw_bank_version_t>(arguments), &version, sizeof(version));
}

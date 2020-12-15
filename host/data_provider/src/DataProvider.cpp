/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "DataProvider.h"

void data_provider::data_provider_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const HostBuffers&) const
{
  auto bno = runtime_options.input_provider->banks(m_bank_type.get_value(), runtime_options.slice_index);
  set_size<dev_raw_banks_t>(arguments, std::get<1>(bno));
  set_size<dev_raw_offsets_t>(arguments, std::get<2>(bno).size());
}

void data_provider::data_provider_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  auto bno = runtime_options.input_provider->banks(m_bank_type.get_value(), runtime_options.slice_index);

  // Copy data to device
  data_to_device<dev_raw_banks_t, dev_raw_offsets_t>(arguments, bno, context);
}

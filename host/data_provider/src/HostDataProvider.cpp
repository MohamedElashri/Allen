/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "HostDataProvider.h"

void host_data_provider::host_data_provider_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const HostBuffers&) const
{
  auto bno = runtime_options.input_provider->banks(m_bank_type.get_value(), runtime_options.slice_index);
  // A number of spans for the blocks equal to the number of blocks
  set_size<host_raw_banks_t>(arguments, std::get<0>(bno).size());

  // A single span for the offsets
  set_size<host_raw_offsets_t>(arguments, 1);

  // A single number for the version
  set_size<host_raw_bank_version_t>(arguments, 1);
}

void host_data_provider::host_data_provider_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context&) const
{
  auto bno = runtime_options.input_provider->banks(m_bank_type.get_value(), runtime_options.slice_index);

  // memcpy the offsets span directly
  auto const& offsets = std::get<2>(bno);
  ::memcpy(data<host_raw_offsets_t>(arguments), &offsets, sizeof(offsets));

  // Copy the spans for the blocks
  auto const& blocks = std::get<0>(bno);
  ::memcpy(
    data<host_raw_banks_t>(arguments),
    blocks.data(),
    blocks.size() * sizeof(typename std::remove_reference_t<decltype(blocks)>::value_type));

  // Copy the bank version
  auto version = std::get<3>(bno);
  ::memcpy(data<host_raw_bank_version_t>(arguments), &version, sizeof(version));
}

template<>
Allen::TypeErasedAlgorithm Allen::instantiate_algorithm_impl(
  host_data_provider::host_data_provider_t*,
  const std::string& name)
{
  auto alg = host_data_provider::host_data_provider_t {};
  alg.set_name(name);

  return TypeErasedAlgorithm {
    alg,
    [](const std::any& instance) {
      return std::any_cast<host_data_provider::host_data_provider_t>(instance).name();
    },
    [](
      const std::any& instance,
      std::any arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) {
      std::any_cast<host_data_provider::host_data_provider_t>(instance).set_arguments_size(
        std::any_cast<ArgumentReferences<host_data_provider::Parameters>>(arguments), runtime_options, constants, host_buffers);
    }};
}

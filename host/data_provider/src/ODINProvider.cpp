/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ODINProvider.h"

#include <Event/ODIN.h>
#include <ODINBank.cuh>

INSTANTIATE_ALGORITHM(odin_provider::odin_provider_t)

void odin_provider::odin_provider_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{

  // Device copy of the ODIN banks that is always in v7 format
  set_size<dev_odin_data_t>(arguments, first<host_number_of_events_t>(arguments));

  // Host copy of the ODIN banks that is always in v7 format
  set_size<host_odin_data_t>(arguments, first<host_number_of_events_t>(arguments));

  // A single number for the version
  set_size<host_raw_bank_version_t>(arguments, 1);

  set_size<dev_event_mask_t>(arguments, first<host_number_of_events_t>(arguments));
}

void odin_provider::odin_provider_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  using namespace std::string_literals;

  auto bno = runtime_options.input_provider->banks(BankTypes::ODIN, runtime_options.slice_index);
  const unsigned event_start = std::get<0>(runtime_options.event_interval);

  auto const& blocks = bno.fragments;
  auto const* sizes = bno.sizes.data();
  auto const* offsets = bno.offsets.data();
  auto const version = bno.version;
  auto const mep_layout = first<host_mep_layout_t>(arguments);

  if (version < 6 || version > 7) {
    throw StrException {"Unsupported ODIN version: "s + std::to_string(version)};
  }

  for (unsigned event = 0; event < first<host_number_of_events_t>(arguments); ++event) {
    // blocks[0].data works because there is only ever a single ODIN bank
    auto const event_odin = mep_layout ? odin_bank<true>(blocks[0].data(), offsets, sizes, event + event_start) :
                                         odin_bank<false>(blocks[0].data(), offsets, sizes, event + event_start);
    auto* output = data<host_odin_data_t>(arguments) + event;
    if (version == 6) {
      *output = LHCb::ODIN::from_version<6>({event_odin.data, event_odin.size}).data;
    }
    else {
      std::copy_n(event_odin.data, event_odin.size, output->data());
    }
  }

  // Create the event mask, to be consumed by other algorithms
  auto event_mask_odin = runtime_options.input_provider->event_mask(runtime_options.slice_index);
  auto buffer = make_host_buffer<unsigned>(arguments, first<host_number_of_events_t>(arguments));
  unsigned size_of_list = 0;
  for (unsigned event_number = 0; event_number < first<host_number_of_events_t>(arguments); ++event_number) {
    if (event_mask_odin[event_number + event_start] == 1) {
      buffer[size_of_list++] = event_number;
    }
  }
  // This copy needs to be synchronous, as it needs to happen before the buffer is deallocated
  Allen::copy(get<dev_event_mask_t>(arguments), buffer.get(), context, Allen::memcpyHostToDevice, size_of_list);
  reduce_size<dev_event_mask_t>(arguments, size_of_list);

  // Copy data to device
  Allen::copy_async<dev_odin_data_t, host_odin_data_t>(arguments, context);

  // Copy the bank version
  ::memcpy(data<host_raw_bank_version_t>(arguments), &version, sizeof(version));
}

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
  set_size<dev_odin_t>(arguments, first<host_number_of_events_t>(arguments));

  // Host copy of the ODIN banks that is always in v7 format
  set_size<host_odin_t>(arguments, first<host_number_of_events_t>(arguments));

  // A single number for the version
  set_size<host_raw_bank_version_t>(arguments, 1);
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

  auto const& blocks = bno.fragments;
  auto const* sizes = bno.sizes.data();
  auto const* offsets = bno.offsets.data();
  auto const version = bno.version;
  auto const mep_layout = first<host_mep_layout_t>(arguments);

  if (version == 6) {
    // Loop over events and create a new v7 ODIN from the v6 in the
    // input data.
    for (unsigned event = 0; event < first<host_number_of_events_t>(arguments); ++event) {
      auto const event_odin = mep_layout ? odin_data_mep_t::bank(blocks[0].data(), offsets, sizes, event) :
                                           odin_data_t::bank(blocks[0].data(), offsets, sizes, event);
      LHCb::ODIN* output_odin = data<host_odin_t>(arguments) + event;
      *output_odin  = LHCb::ODIN::from_version<6>({event_odin.data, event_odin.size});
    }
  }
  else {
    throw StrException {"Unsupported ODIN version: "s + std::to_string(version)};
  }

  // Copy data to device
  Allen::copy_async<dev_odin_t, host_odin_t>(arguments, context);

  // Copy the bank version
  ::memcpy(data<host_raw_bank_version_t>(arguments), &version, sizeof(version));
}

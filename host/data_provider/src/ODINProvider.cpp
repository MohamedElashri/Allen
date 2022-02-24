/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ODINProvider.h"

#include <Event/ODIN.h>
#include <ODINBank.cuh>

INSTANTIATE_ALGORITHM(odin_provider::odin_provider_t)

void odin_provider::odin_provider_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const HostBuffers&) const
{
  auto bno = runtime_options.input_provider->banks(BankTypes::ODIN, runtime_options.slice_index);

  [[maybe_unused]] auto const& blocks = bno.fragments;
  assert(blocks.size() == 1);

  // Device copy of the ODIN banks that is always in v7 format
  set_size<dev_raw_banks_t>(arguments, bno.fragments_mem_size);
  set_size<dev_raw_offsets_t>(arguments, bno.offsets.size());

  // Host copy of the ODIN banks that is always in v7 format
  set_size<host_raw_banks_t>(arguments, bno.fragments_mem_size);

  // A single span for the offsets
  set_size<host_raw_offsets_t>(arguments, 1);

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
  auto const* offsets = bno.offsets.data();
  auto const version = bno.version;
  auto const mep_layout = first<host_mep_layout_t>(arguments);

  if (version == 6) {
    // Copy everyhing that is not the fragment data in case of Allen layout
    if (!mep_layout) {
      std::memcpy(data<host_raw_banks_t>(arguments), blocks[0].data(), bno.fragments_mem_size);
    }

    // Loop over events and create a new v7 ODIN from the v6 in the
    // input data. Then copy its data words to the
    // host_raw_banks. Finally point the BanksAndOffsets to the new
    // copy so it gets copied to the device. The size of ODIN v6 and
    // v7 is the same (10 words), so the offsets needn't be touched.
    for (unsigned event = 0; event < first<host_number_of_events_t>(arguments); ++event) {
      auto const* event_odin = mep_layout ? odin_data_mep_t::data(blocks[0].data(), offsets, event) :
                                            odin_data_t::data(blocks[0].data(), offsets, event);
      LHCb::ODIN const odin = LHCb::ODIN::from_version<6>({event_odin, 10});
      auto* output_odin = const_cast<unsigned*>(
        mep_layout ? odin_data_mep_t::data(data<host_raw_banks_t>(arguments), offsets, event) :
                     odin_data_t::data(data<host_raw_banks_t>(arguments), offsets, event));
      std::memcpy(output_odin, odin.data.data(), odin.data.size() * sizeof(decltype(odin.data)::value_type));
    }
    bno.fragments[0] = {data<host_raw_banks_t>(arguments), bno.fragments_mem_size};
  }
  else if (version == 7) {
    // Straight copy of ODIN data to pupulate the host raw data
    std::memcpy(data<host_raw_banks_t>(arguments), blocks[0].data(), bno.fragments_mem_size);
  }
  else {
    throw StrException {"Unsupported ODIN version: "s + std::to_string(version)};
  }

  // Copy data to device
  data_to_device<dev_raw_banks_t, dev_raw_offsets_t>(arguments, bno, context);

  // memcpy the offsets span directly
  ::memcpy(data<host_raw_offsets_t>(arguments), &bno.offsets, sizeof(bno.offsets));

  // Copy the bank version
  ::memcpy(data<host_raw_bank_version_t>(arguments), &version, sizeof(version));
}

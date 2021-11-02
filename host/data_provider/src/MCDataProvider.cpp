/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "MCDataProvider.h"

INSTANTIATE_ALGORITHM(mc_data_provider::mc_data_provider_t)

void mc_data_provider::mc_data_provider_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<host_mc_events_t>(arguments, 1);
}

void mc_data_provider::mc_data_provider_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context&) const
{
  MCEvents* mc_events = const_cast<MCEvents*>(&runtime_options.mc_events);
  // MCEvents* mc_events = &m_mc_events;

  for (unsigned event_number = 0; event_number < first<host_number_of_events_t>(arguments); ++event_number) {
    // get # of raw banks
    const MCRawEvent mc_track_event(
      data<host_mc_particle_banks_t>(arguments)[0].data() + first<host_mc_particle_offsets_t>(arguments)[event_number]);
    auto const number_of_mc_track_raw_banks = mc_track_event.number_of_raw_banks();
    const MCRawEvent mc_pv_event(
      data<host_mc_pv_banks_t>(arguments)[0].data() + first<host_mc_pv_offsets_t>(arguments)[event_number]);
    auto const number_of_mc_pv_raw_banks = mc_pv_event.number_of_raw_banks();

    // Fill raw bank content into std::vector<char>
    std::vector<char> mc_track_info_vec;
    for (unsigned i = 0; i < number_of_mc_track_raw_banks; ++i) {
      const auto raw_bank = mc_track_event.get_mc_raw_bank(i);
      const char* payload = raw_bank.data();
      const char* last = raw_bank.last();
      const unsigned size = last - payload;
      std::move(payload, payload + size, std::back_inserter(mc_track_info_vec));
    }
    std::vector<char> mc_pv_info_vec;
    for (unsigned i = 0; i < number_of_mc_pv_raw_banks; ++i) {
      const auto raw_bank = mc_pv_event.get_mc_raw_bank(i);
      const char* payload = raw_bank.data();
      const char* last = raw_bank.last();
      const unsigned size = last - payload;
      std::move(payload, payload + size, std::back_inserter(mc_pv_info_vec));
    }
    // Fill MC Events
    mc_events->emplace_back(mc_track_info_vec, mc_pv_info_vec, false);
  }

  data<host_mc_events_t>(arguments)[0] = mc_events;
}

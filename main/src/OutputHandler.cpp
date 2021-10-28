/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <iostream>

#include <cstdio>
#include <cstring>
#include <unistd.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <read_mdf.hpp>
#include <write_mdf.hpp>
#include <mdf_header.hpp>

#include <InputProvider.h>
#include <OutputHandler.h>

std::tuple<bool, size_t> OutputHandler::output_selected_events(
  size_t const slice_index,
  size_t const event_offset,
  gsl::span<bool const> const selected_events_bool,
  gsl::span<uint32_t const> const dec_reports,
  gsl::span<uint32_t const> const sel_reports,
  gsl::span<unsigned const> const sel_report_offsets)
{
  auto const header_size = LHCb::MDFHeader::sizeOf(Allen::mdf_header_version);

  // m_sizes will contain the total size of all banks in the event
  std::vector<unsigned> selected_events;
  selected_events.reserve(selected_events_bool.size());
  for (unsigned i = 0; i < selected_events_bool.size(); ++i) {
    if (selected_events_bool[i]) {
      selected_events.push_back(i);
    }
  }

  std::fill_n(m_sizes.begin(), selected_events.size(), 0);
  m_input_provider->event_sizes(slice_index, selected_events, m_sizes);
  auto event_ids = m_input_provider->event_ids(slice_index);

  // size of a RawBank header
  const int bank_header_size = 4 * sizeof(short);
  // size of the DecReport RawBank
  const unsigned dec_report_size = (m_nlines + 2) * sizeof(uint32_t);

  for (size_t i = 0; i < static_cast<size_t>(selected_events.size()); ++i) {

    // size of the SelReport RawBank
    auto const event_number = selected_events[i];
    const unsigned sel_report_size =
      (sel_report_offsets[event_number + 1] - sel_report_offsets[event_number]) * sizeof(uint32_t);

    // add DecReport and SelReport sizes to the total size (including RawBank headers)
    size_t buffer_size = m_sizes[i] + header_size + bank_header_size + dec_report_size;
    if (sel_report_size > 0) {
      buffer_size += bank_header_size + sel_report_size;
    }
    auto [buffer_id, buffer_span] = buffer(buffer_size);

    // In case output was cancelled
    if (buffer_span.empty()) continue;

    // Add the header
    auto* header = reinterpret_cast<LHCb::MDFHeader*>(buffer_span.data());
    // Set header version first so the subsequent call to setSize can
    // use it
    header->setHeaderVersion(Allen::mdf_header_version);
    // MDFHeader::setSize adds the header size internally, so pass
    // only the payload size here
    header->setSize(buffer_size - header_size);
    header->setChecksum(0);
    // No compression here, handled at write time
    header->setCompression(0);
    header->setSubheaderLength(header_size - sizeof(LHCb::MDFHeader));
    header->setDataType(LHCb::MDFHeader::BODY_TYPE_BANKS);
    header->setSpare(0);
    // Fixed triggermask for now
    // FIXME update when routing bits are implemented
    header->subHeader().H1->setTriggerMask(m_trigger_mask.data());
    // Set run number
    // FIXME: get orbit and bunch number from ODIN
    header->subHeader().H1->setRunNumber(static_cast<unsigned int>(std::get<0>(event_ids[event_number])));

    m_input_provider->copy_banks(
      slice_index, event_number, {buffer_span.data() + header_size, static_cast<events_size>(m_sizes[i])});

    // add the dec report
    Allen::add_raw_bank(
      LHCb::RawBank::HltDecReports,
      2u,
      1 << 13,
      {reinterpret_cast<char const*>(dec_reports.data()) + dec_report_size * (event_number - event_offset),
       static_cast<events_size>(dec_report_size)},
      buffer_span.data() + header_size + m_sizes[i]);

    // add the sel report
    if (sel_report_size > 0) {
      Allen::add_raw_bank(
        LHCb::RawBank::HltSelReports,
        11u,
        1 << 13,
        {reinterpret_cast<char const*>(sel_reports.data()) + sel_report_offsets[event_number] * sizeof(uint32_t),
         static_cast<events_size>(sel_report_size)},
        buffer_span.data() + header_size + m_sizes[i] + bank_header_size + dec_report_size);
    }

    auto s = write_buffer(buffer_id);
    if (!s) return {s, i};
  }
  return {true, selected_events.size()};
}

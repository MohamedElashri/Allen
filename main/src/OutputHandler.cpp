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
#include <RawBanksDefinitions.cuh>
#include <LineInfo.cuh>

bool OutputHandler::output_selected_events(
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
  const unsigned dec_report_size = (m_number_of_hlt1_lines + 2) * sizeof(uint32_t);

  for (size_t i = 0; i < static_cast<size_t>(selected_events.size()); ++i) {

    // size of the SelReport RawBank
    const unsigned sel_report_size = (sel_report_offsets[i + 1] - sel_report_offsets[i]) * sizeof(uint32_t);

    // add DecReport and SelReport sizes to the total size (including two RawBank headers)
    auto [buffer_id, buffer_span] =
      buffer(m_sizes[i] + header_size + 2 * bank_header_size + dec_report_size + sel_report_size);

    // Add the header
    auto* header = reinterpret_cast<LHCb::MDFHeader*>(buffer_span.data());
    // Set header version first so the subsequent call to setSize can
    // use it
    header->setHeaderVersion(Allen::mdf_header_version);
    // MDFHeader::setSize adds the header size internally, so pass
    // only the payload size here
    header->setSize(m_sizes[i] + 2 * bank_header_size + dec_report_size + sel_report_size);
    // No checksumming
    // FIXME: make configurable
    header->setChecksum(0);
    // No compression
    // FIXME: make configurable
    header->setCompression(0);
    header->setSubheaderLength(header_size - sizeof(LHCb::MDFHeader));
    header->setDataType(LHCb::MDFHeader::BODY_TYPE_BANKS);
    header->setSpare(0);
    // Fixed triggermask for now
    // FIXME update when routing bits are implemented
    header->subHeader().H1->setTriggerMask(m_trigger_mask.data());
    // Set run number
    // FIXME: get orbit and bunch number from ODIN
    header->subHeader().H1->setRunNumber(static_cast<unsigned int>(std::get<0>(event_ids[selected_events[i]])));

    m_input_provider->copy_banks(
      slice_index, selected_events[i], {buffer_span.data() + header_size, static_cast<events_size>(m_sizes[i])});

    // add the dec report
    add_raw_bank(
      LHCb::RawBank::HltDecReports,
      2u,
      1 << 13,
      {reinterpret_cast<char const*>(dec_reports.data()) + dec_report_size * (selected_events[i] - event_offset),
       static_cast<events_size>(dec_report_size)},
      buffer_span.data() + header_size + m_sizes[i]);

    // add the sel report
    add_raw_bank(
      LHCb::RawBank::HltSelReports,
      2u,
      1 << 13,
      {reinterpret_cast<char const*>(sel_reports.data()) + sel_report_offsets[i] * sizeof(uint32_t), sel_report_size},
      buffer_span.data() + header_size + m_sizes[i] + bank_header_size + dec_report_size);

    auto s = write_buffer(buffer_id);
    if (!s) return s;
  }
  return true;
}

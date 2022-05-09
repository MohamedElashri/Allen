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
#include <raw_helpers.hpp>

#include <InputProvider.h>
#include <OutputHandler.h>

std::tuple<bool, size_t> OutputHandler::output_selected_events(
  size_t const slice_index,
  size_t const start_event,
  gsl::span<bool const> const selected_events_bool,
  gsl::span<uint32_t const> const dec_reports,
  gsl::span<uint32_t const> const sel_reports,
  gsl::span<unsigned const> const sel_report_offsets)
{
  auto const header_size = LHCb::MDFHeader::sizeOf(Allen::mdf_header_version);
  // size of a RawBank header
  const int bank_header_size = 4 * sizeof(short);
  // size of the DecReport RawBank
  const unsigned dec_report_size = (m_nlines + 2) * sizeof(uint32_t);

  // m_sizes will contain the total size of all banks in the event
  std::vector<unsigned> selected_events;
  selected_events.reserve(selected_events_bool.size());
  for (unsigned i = 0; i < selected_events_bool.size(); ++i) {
    if (selected_events_bool[i]) {
      // selected_events is passed to the InputProvider to get the
      // event sizes. The InputProvider doesn't know about slice
      // splitting, so we have to offset by start_event here.
      selected_events.push_back(i + start_event);
    }
  }

  auto const n_events = static_cast<size_t>(selected_events.size());
  if (n_events == 0) return {true, 0};

  std::fill_n(m_sizes.begin(), selected_events.size(), 0);
  m_input_provider->event_sizes(slice_index, selected_events, m_sizes);
  auto event_ids = m_input_provider->event_ids(slice_index);

  bool output_success = true;
  bool n_output = 0;
  size_t n_batches = n_events / m_output_batch_size + (n_events % m_output_batch_size != 0);

  for (size_t i_batch = 0; i_batch < n_batches && output_success; ++i_batch) {

    size_t batch_buffer_size = 0;
    size_t output_event_offset = 0;
    size_t batch_size = std::min(i_batch + m_output_batch_size, n_events);

    for (size_t i = 0; i < batch_size; ++i) {

      // The event number is constructed to index into a batch. The 0th
      // event of a batch is start_event in a slice, so we subtract
      // start_event that was added to selected_events to have a direct
      // index into the batch again.
      auto const event_number = selected_events[i] - start_event;

      // size of the SelReport RawBank
      // need the index into the batch here
      const unsigned sel_report_size =
        (sel_report_offsets[event_number + 1] - sel_report_offsets[event_number]) * sizeof(uint32_t);

      // add DecReport and SelReport sizes to the total size (including RawBank headers)
      // m_sizes is indexed in the same way as selected_events
      size_t event_size = m_sizes[i] + header_size + bank_header_size + dec_report_size;
      if (sel_report_size > 0) {
        event_size += bank_header_size + sel_report_size;
      }
      batch_buffer_size += event_size;
    }

    auto [buffer_id, batch_span] = buffer(batch_buffer_size, n_events);

    // In case output was cancelled
    if (batch_span.empty()) return {false, 0};

    for (size_t i = 0; i < batch_size; ++i) {

      // The event number is constructed to index into a batch. The 0th
      // event of a batch is start_event in a slice, so we subtract
      // start_event that was added to selected_events to have a direct
      // index into the batch again.
      auto const event_number = selected_events[i] - start_event;

      // size of the SelReport RawBank
      // need the index into the batch here
      const unsigned sel_report_size =
        (sel_report_offsets[event_number + 1] - sel_report_offsets[event_number]) * sizeof(uint32_t);

      // add DecReport and SelReport sizes to the total size (including RawBank headers)
      // m_sizes is indexed in the same way as selected_events
      size_t event_size = m_sizes[i] + header_size + bank_header_size + dec_report_size;
      if (sel_report_size > 0) {
        event_size += bank_header_size + sel_report_size;
      }

      // The memory range in the output buffer for this event
      auto event_span = batch_span.subspan(output_event_offset, event_size);

      // Add the header
      auto* header = reinterpret_cast<LHCb::MDFHeader*>(event_span.data());
      // Set header version first so the subsequent call to setSize can
      // use it
      header->setHeaderVersion(Allen::mdf_header_version);
      // MDFHeader::setSize adds the header size internally, so pass
      // only the payload size here
      header->setSize(event_size - header_size);

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
      // The batch is offset by start_event with respect to the slice, so we add start_event
      header->subHeader().H1->setRunNumber(
        static_cast<unsigned int>(std::get<0>(event_ids[event_number + start_event])));

      // The batch is offset by start_event with respect to the slice, so we add start_event
      m_input_provider->copy_banks(
        slice_index,
        event_number + start_event,
        {event_span.data() + header_size, static_cast<events_size>(m_sizes[i])});

      // add the dec report
      Allen::add_raw_bank(
        LHCb::RawBank::HltDecReports,
        2u,
        1 << 13,
        {reinterpret_cast<char const*>(dec_reports.data()) + dec_report_size * event_number,
         static_cast<events_size>(dec_report_size)},
        event_span.data() + header_size + m_sizes[i]);

      // add the sel report
      if (sel_report_size > 0) {
        Allen::add_raw_bank(
          LHCb::RawBank::HltSelReports,
          11u,
          1 << 13,
          {reinterpret_cast<char const*>(sel_reports.data()) + sel_report_offsets[event_number] * sizeof(uint32_t),
           static_cast<events_size>(sel_report_size)},
          event_span.data() + header_size + m_sizes[i] + bank_header_size + dec_report_size);
      }

      if (m_checksum) {
        auto const skip = 4 * sizeof(int);
        auto c = LHCb::hash32Checksum(event_span.data() + skip, event_span.size() - skip);
        header->setChecksum(c);
      }
      else {
        header->setChecksum(0);
      }

      output_event_offset += event_size;
    }

    auto output_success = write_buffer(buffer_id);
    n_output += output_success ? batch_size : 0;
  }

  return {output_success, n_output};
}

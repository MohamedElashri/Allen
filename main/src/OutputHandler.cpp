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

bool OutputHandler::output_selected_events(
  size_t const slice_index,
  size_t const event_offset,
  gsl::span<unsigned int> const selected_events,
  uint32_t const* const dec_reports)
{
  auto const header_size = LHCb::MDFHeader::sizeOf(Allen::mdf_header_version);

  // m_sizes will contain the total size of all banks in the event
  std::fill_n(m_sizes.begin(), selected_events.size(), 0);
  m_input_provider->event_sizes(slice_index, selected_events, m_sizes);
  auto const& event_ids = m_input_provider->event_ids(slice_index);

  // size of the DecReport RawBank and its header
  const int bank_header_size = 4 * sizeof(short);
  const int n_hlt1_lines = Hlt1::Hlt1Lines::End;
  const int dec_report_size = (n_hlt1_lines + 2) * sizeof(uint32_t);

  for (size_t i = 0; i < selected_events.size(); ++i) {

    auto [buffer_id, buffer_span] = buffer(m_sizes[i] + header_size + bank_header_size + dec_report_size);

    // Add the header
    auto* header = reinterpret_cast<LHCb::MDFHeader*>(buffer_span.data());
    // Set header version first so the subsequent call to setSize can
    // use it
    header->setHeaderVersion(Allen::mdf_header_version);
    // MDFHeader::setSize adds the header size internally, so pass
    // only the payload size here
    header->setSize(m_sizes[i] + dec_report_size);
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

    m_input_provider->copy_banks(slice_index, selected_events[i], {buffer_span.data() + header_size, m_sizes[i]});

    // add the dec report
    add_raw_bank(
      LHCb::RawBank::HltDecReports,
      2u,
      1 << 13,
      {reinterpret_cast<char const*>(dec_reports) + dec_report_size * (selected_events[i] - event_offset),
       dec_report_size},
      buffer_span.data() + header_size + m_sizes[i]);

    auto s = write_buffer(buffer_id);
    if (!s) return s;
  }
  return true;
}

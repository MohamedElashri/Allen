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

void OutputHandler::output_selected_events(size_t const slice_index, gsl::span<unsigned int> const selected_events)
{
  auto const header_size = LHCb::MDFHeader::sizeOf(Allen::mdf_header_version);
  std::fill_n(m_sizes.begin(), selected_events.size(), header_size);
  m_input_provider->event_sizes(slice_index, selected_events, m_sizes);

  unsigned int offset = 0;
  m_offsets[0] = header_size;
  for (size_t i = 0; i < selected_events.size(); ++i) {
    offset += m_sizes[i];
    m_offsets[i + 1] = offset + header_size;
  }

  auto [buffer_id, buffer_span] = buffer(offset);

  m_input_provider->copy_banks(slice_index, selected_events, buffer_span, m_offsets);

  write_buffer(buffer_id);
}

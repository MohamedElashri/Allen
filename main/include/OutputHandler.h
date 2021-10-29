/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <vector>

#include <zmq/zmq.hpp>
#include <gsl/span>

#include "InputProvider.h"
#include "BankTypes.h"
#include "Timer.h"

class OutputHandler {
public:
  OutputHandler(IInputProvider const* input_provider, std::string connection, size_t n_lines, bool checksum) :
    m_input_provider {input_provider}, m_connection {std::move(connection)},
    m_sizes(input_provider->events_per_slice()), m_nlines {n_lines}, m_checksum(checksum)
  {}

  virtual ~OutputHandler() {}

  std::string const& connection() const { return m_connection; }

  std::tuple<bool, size_t> output_selected_events(
    size_t const slice_index,
    size_t const event_offset,
    gsl::span<bool const> const selected_events,
    gsl::span<uint32_t const> const dec_reports,
    gsl::span<uint32_t const> const sel_reports,
    gsl::span<unsigned const> const sel_report_offsets);

  virtual zmq::socket_t* client_socket() { return nullptr; }

  virtual void handle() {}

  virtual bool start() { return true; }

  virtual bool stop() { return true; }

  virtual void cancel() {}

  bool do_checksum() const { return m_checksum; }

protected:
  virtual std::tuple<size_t, gsl::span<char>> buffer(size_t buffer_size) = 0;

  virtual bool write_buffer(size_t id) = 0;

  IInputProvider const* m_input_provider = nullptr;
  std::string m_connection;
  std::vector<size_t> m_sizes;
  std::array<uint32_t, 4> m_trigger_mask = {~0u, ~0u, ~0u, ~0u};
  size_t m_nlines = 0;
  bool m_checksum = false;
};

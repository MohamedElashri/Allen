#pragma once
#include <vector>

#include <Logger.h>
#include <BankTypes.h>
#include <Timer.h>

#include <zmq/zmq.hpp>

struct IInputProvider;

class OutputHandler {
public:
  OutputHandler(IInputProvider const* input_provider, size_t eps, const unsigned number_of_hlt1_lines) :
    m_input_provider {input_provider}, m_sizes(eps), m_number_of_hlt1_lines(number_of_hlt1_lines)
  {}

  virtual ~OutputHandler() {}

  bool output_selected_events(
    size_t const slice_index,
    size_t const event_offset,
    gsl::span<bool const> const selected_events,
    gsl::span<uint32_t const> const dec_reports,
    gsl::span<uint32_t const> const sel_reports,
    gsl::span<unsigned const> const sel_report_offsets);

  virtual zmq::socket_t* client_socket() { return nullptr; }

  virtual void handle() {}

protected:
  virtual std::tuple<size_t, gsl::span<char>> buffer(size_t buffer_size) = 0;

  virtual bool write_buffer(size_t id) = 0;

  IInputProvider const* m_input_provider = nullptr;
  std::vector<size_t> m_sizes;
  std::array<uint32_t, 4> m_trigger_mask = {~0u, ~0u, ~0u, ~0u};
  unsigned m_number_of_hlt1_lines;
};

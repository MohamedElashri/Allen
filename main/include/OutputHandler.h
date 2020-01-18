
#pragma once
#include <vector>

#include <Logger.h>
#include <BankTypes.h>
#include <Timer.h>

struct IInputProvider;

class OutputHandler {
public:
  OutputHandler(IInputProvider const* input_provider, size_t const events_per_slice, std::string connection) :
    m_eps {events_per_slice}, m_connection {connection}, m_input_provider {input_provider}, m_sizes(events_per_slice)
  {}

  virtual ~OutputHandler() {}

  bool output_selected_events(
    size_t const slice_index,
    size_t const event_offset,
    gsl::span<unsigned int const> const selected_events,
    gsl::span<uint32_t const> const dec_reports);

protected:
  virtual std::tuple<size_t, gsl::span<char>> buffer(size_t buffer_size) = 0;

  virtual bool write_buffer(size_t id) = 0;

  size_t const m_eps;
  std::string const m_connection;

  IInputProvider const* m_input_provider = nullptr;
  std::vector<size_t> m_sizes;
  std::array<uint32_t, 4> m_trigger_mask = {~0u, ~0u, ~0u, ~0u};
};

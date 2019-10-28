#pragma once

#include <Logger.h>
#include <BankTypes.h>
#include <Timer.h>
#include <mdf_header.hpp>
#include <read_mdf.hpp>
#include <read_mep.hpp>
#include <raw_bank.hpp>

namespace Allen {
  constexpr int mdf_header_version = 3;
}

class OutputHandler {
public:

  OutputHandler(IInputProvider* input_provider, size_t const events_per_slice, std::string connection)
    : m_eps{events_per_slice}, m_connection{connection}, m_input_provider{input_provider}
  {

  }

  virtual ~OutputHandler() {}

  void output_selected_events(size_t const slice_index, gsl::span<unsigned int> const selected_events);

protected:

  virtual std::tuple<size_t, gsl::span<char>> buffer(size_t buffer_size) = 0;

  virtual bool write_buffer(size_t id) = 0;

  size_t const m_eps;
  std::string const m_connection;

  IInputProvider* m_input_provider = nullptr;
  std::vector<size_t> m_sizes;
  std::vector<unsigned int> m_offsets;

};

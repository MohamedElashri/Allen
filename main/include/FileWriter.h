#pragma once

#include <read_mdf.hpp>
#include <OutputHandler.h>

class FileWriter final : public OutputHandler {
public:

  FileWriter(IInputProvider* input_provider, size_t const events_per_slice, std::string filename)
    : OutputHandler{input_provider, events_per_slice, filename}
  {
    m_output = MDF::open(m_connection, O_CREAT | O_WRONLY);
    if (!m_output.good) {
      throw std::runtime_error {"Failed to open output file"};
    }
  }

protected:

  std::tuple<size_t, gsl::span<char>> buffer(size_t buffer_size) override {
    m_buffer.resize(buffer_size);
    return {0, gsl::span{&m_buffer[0], buffer_size}};
  }

  virtual bool write_buffer(size_t) {
    return m_output.write(m_buffer.data(), m_buffer.size());
  }

private:

  // Storage for the currently open output file
  Allen::IO m_output;

  std::vector<char> m_buffer;

};

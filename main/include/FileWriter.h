#pragma once

#include <read_mdf.hpp>
#include "raw_helpers.hpp"
#include <OutputHandler.h>

class FileWriter final : public OutputHandler {
public:
  FileWriter(
    IInputProvider const* input_provider,
    size_t const events_per_slice,
    std::string filename,
    bool checksum = true) :
    OutputHandler {input_provider, events_per_slice, filename},
    m_checksum {checksum}
  {
    m_output = MDF::open(m_connection, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR);
    if (!m_output.good) {
      throw std::runtime_error {"Failed to open output file"};
    }
  }

  ~FileWriter()
  {
    if (m_output.good) {
      m_output.close();
    }
  }

protected:
  std::tuple<size_t, gsl::span<char>> buffer(size_t buffer_size) override
  {
    m_buffer.resize(buffer_size);
    return {0, gsl::span {&m_buffer[0], buffer_size}};
  }

  virtual bool write_buffer(size_t) override
  {
    if (m_checksum) {
      auto* header = reinterpret_cast<LHCb::MDFHeader*>(&m_buffer[0]);
      auto const skip = 4 * sizeof(int);
      auto c = LHCb::genChecksum(1, m_buffer.data() + skip, m_buffer.size() - skip);
      header->setChecksum(c);
    }

    return m_output.write(m_buffer.data(), m_buffer.size());
  }

private:
  // do checksum on write
  bool const m_checksum;

  // Storage for the currently open output file
  Allen::IO m_output;

  // data buffer
  std::vector<char> m_buffer;
};

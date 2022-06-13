/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <read_mdf.hpp>
#include <OutputHandler.h>

class FileWriter final : public OutputHandler {
public:
  FileWriter(
    IInputProvider const* input_provider,
    std::string filename,
    size_t const output_batch_size,
    size_t const n_lines,
    bool checksum = true) :
    OutputHandler {input_provider, filename, 1u, output_batch_size, n_lines, checksum},
    m_filename {std::move(filename)}
  {
    m_output = MDF::open(m_filename, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR);
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
  gsl::span<char> buffer(size_t, size_t buffer_size, size_t) override
  {
    m_buffer.resize(buffer_size);
    return gsl::span {&m_buffer[0], static_cast<events_size>(buffer_size)};
  }

  virtual bool write_buffer(size_t) override { return m_output.write(m_buffer.data(), m_buffer.size()); }

private:
  // Output filename
  std::string const m_filename;
  // Storage for the currently open output file

  Allen::IO m_output;

  // data buffer
  std::vector<char> m_buffer;
};

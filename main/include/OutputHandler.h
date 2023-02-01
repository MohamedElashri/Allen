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

#ifndef STANDALONE
#include <GaudiKernel/Service.h>
#include <Gaudi/Accumulators.h>
#endif

namespace Allen::Store {
  class PersistentStore;
}

namespace LHCb {
  class MDFHeader;
}

struct OutputSizes {
  std::vector<size_t> input;
  std::vector<size_t> hlt;
  std::vector<size_t> tae;

  void resize(size_t s)
  {
    for (auto* sizes : {&input, &hlt, &tae}) {
      sizes->resize(s);
    }
  }

  void fill_zero()
  {
    for (auto* sizes : {&input, &hlt, &tae}) {
      std::fill_n(sizes->begin(), sizes->size(), 0);
    }
  }
};

class OutputHandler {
public:
  OutputHandler() {}

  OutputHandler(
    IInputProvider const* input_provider,
    std::string const connection,
    size_t const n_threads,
    size_t const output_batch_size,
    size_t const n_lines,
    bool const checksum)
  {
    init(input_provider, std::move(connection), n_threads, output_batch_size, n_lines, checksum);
  }

  virtual ~OutputHandler() {}

  std::string const& connection() const { return m_connection; }

  std::tuple<bool, size_t> output_selected_events(
    size_t const thread_id,
    size_t const slice_index,
    size_t const event_offset,
    Allen::Store::PersistentStore const& store);

  virtual zmq::socket_t* client_socket() const { return nullptr; }

  virtual void handle() {}

  virtual void cancel() {}

  virtual void output_done() {}

  bool do_checksum() const { return m_checksum; }

  size_t n_threads() const { return m_nthreads; }

protected:
  void init(
    IInputProvider const* input_provider,
    std::string const connection,
    size_t const n_threads,
    size_t const output_batch_size,
    size_t const n_lines,
    bool const checksum)
  {
    m_input_provider = input_provider;
    m_connection = std::move(connection);
    m_sizes.resize(n_threads);
    for (auto& sizes : m_sizes) {
      sizes.resize(input_provider->events_per_slice());
    }
    m_output_batch_size = output_batch_size;
    m_nlines = n_lines;
    m_checksum = checksum;
    m_nthreads = n_threads;

#ifndef STANDALONE
    auto* svc = dynamic_cast<Service*>(this);
    if (svc != nullptr) {
      m_noutput = std::make_unique<Gaudi::Accumulators::Counter<>>(svc, "NOutput");
      m_ntae = std::make_unique<Gaudi::Accumulators::Counter<>>(svc, "NTAEOutput");
      m_nbatches = std::make_unique<Gaudi::Accumulators::AveragingCounter<>>(svc, "NBatches");
      m_batch_size = std::make_unique<Gaudi::Accumulators::AveragingCounter<>>(svc, "BatchSize");
    }
#endif
  }

  virtual gsl::span<char> buffer(size_t thread_id, size_t buffer_size, size_t n_events) = 0;

  virtual bool write_buffer(size_t thread_id) = 0;

private:
  OutputSizes& event_sizes(
    size_t const thread_id,
    size_t const slice_index,
    Allen::Store::PersistentStore const& store,
    std::vector<unsigned> const& selected_events,
    unsigned const start_event);

  LHCb::MDFHeader*
  add_mdf_header(gsl::span<char> event_span, unsigned const run_number, gsl::span<unsigned const> routing_bits);

  size_t add_banks(
    Allen::Store::PersistentStore const& store,
    unsigned const slice_index,
    unsigned const start_event,
    unsigned const event_number,
    unsigned const input_size,
    gsl::span<char> event_span);

  void add_checksum(LHCb::MDFHeader* header, gsl::span<char> event_span);

  std::tuple<bool, size_t> output_single_events(
    size_t const thread_id,
    size_t const slice_index,
    size_t const event_offset,
    Allen::Store::PersistentStore const& store);

  std::tuple<bool, size_t> output_tae_events(
    size_t const thread_id,
    size_t const slice_index,
    size_t const event_offset,
    Allen::Store::PersistentStore const& store);

  IInputProvider const* m_input_provider = nullptr;
  std::string m_connection;

  std::vector<OutputSizes> m_sizes;
  std::array<uint32_t, 4> m_trigger_mask = {~0u, ~0u, ~0u, ~0u};
  size_t m_output_batch_size = 10;
  size_t m_nlines = 0;
  bool m_checksum = false;
  size_t m_nthreads = 1;

#ifndef STANDALONE
  std::unique_ptr<Gaudi::Accumulators::Counter<>> m_noutput;
  std::unique_ptr<Gaudi::Accumulators::AveragingCounter<>> m_batch_size;
  std::unique_ptr<Gaudi::Accumulators::AveragingCounter<>> m_nbatches;
  std::unique_ptr<Gaudi::Accumulators::Counter<>> m_ntae;
#endif
};

/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <map>
#include <queue>
#include <vector>
#include <gsl/gsl>
#include <Store.cuh>
#include <InputReader.h>

#ifndef ALLEN_STANDALONE
#include <GaudiKernel/Service.h>
#include <Gaudi/Accumulators.h>
#endif

struct HostBuffersManager {
  enum class BufferStatus { Empty, Filling, Filled, Processing, Processed, Written };

  HostBuffersManager(size_t nBuffers, size_t host_memory_size, const ConfigurationReader::Params& configuration);

  Allen::Store::PersistentStore* get_persistent_store(size_t i) const { return m_persistent_stores.at(i); }

  size_t assignBufferToFill();
  size_t assignBufferToProcess();

  void returnBufferFilled(size_t);
  void returnBufferUnfilled(size_t);
  void returnBufferProcessed(size_t);
  void returnBufferWritten(size_t);

  void writeSingleEventPassthrough(const size_t b);

  void printStatus() const;
  bool buffersEmpty() const { return (empty_buffers.size() == m_persistent_stores.size()); }

#ifndef ALLEN_STANDALONE
  void activateMonitoring(Service* svc);
#endif

private:
  std::vector<BufferStatus> buffer_statuses;
  std::vector<Allen::Store::PersistentStore*> m_persistent_stores;

  std::queue<size_t> empty_buffers;
  std::queue<size_t> filled_buffers;
  size_t m_host_memory_size;

  unsigned m_tck {0u};
  unsigned m_task_id {0u};
  unsigned m_passthrough_rbs {0u};

  const std::string m_passthrough_line = "Hlt1PassthroughLargeEvent";
  const unsigned m_passthrough_key = 0xe7682884;

#ifndef ALLEN_STANDALONE
  std::unique_ptr<Gaudi::Accumulators::Counter<>> m_nsplit;
  std::unique_ptr<Gaudi::Accumulators::Counter<>> m_npassthrough;
#endif
};

/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <map>
#include <queue>
#include <vector>
#include <gsl/gsl>
#include <Store.cuh>

// Forward definition of Stream, to avoid
// inability to compile kernel calls (due to <<< >>>
// operators) from main.cpp
//
// Note: main.cu wouldn't work due to nvcc not
//       supporting properly tbb (or the other way around).
struct HostBuffers;

struct HostBuffersManager {
  enum class BufferStatus { Empty, Filling, Filled, Processing, Processed, Written };

  HostBuffersManager(size_t nBuffers, size_t host_memory_size) { init(nBuffers, host_memory_size); }

  HostBuffers* getBuffers(size_t i) const { return (i < host_buffers.size() ? host_buffers.at(i) : 0); }
  Allen::Store::PersistentStore* get_persistent_store(size_t i) const { return m_persistent_stores.at(i); }

  size_t assignBufferToFill();
  size_t assignBufferToProcess();

  void returnBufferFilled(size_t);
  void returnBufferUnfilled(size_t);
  void returnBufferProcessed(size_t);
  void returnBufferWritten(size_t);

  void writeSingleEventPassthrough(const size_t b);

  std::tuple<
    gsl::span<bool>,
    gsl::span<uint32_t>,
    gsl::span<uint32_t>,
    gsl::span<uint32_t>,
    gsl::span<unsigned>,
    gsl::span<uint32_t>,
    gsl::span<unsigned>>
  getBufferOutputData(size_t b);

  void printStatus() const;
  bool buffersEmpty() const { return (empty_buffers.size() == host_buffers.size()); }

private:
  void init(size_t nBuffers, size_t host_memory_size);

  std::vector<HostBuffers*> host_buffers;
  std::vector<BufferStatus> buffer_statuses;
  std::vector<Allen::Store::PersistentStore*> m_persistent_stores;

  std::queue<size_t> empty_buffers;
  std::queue<size_t> filled_buffers;
  size_t m_host_memory_size;
};

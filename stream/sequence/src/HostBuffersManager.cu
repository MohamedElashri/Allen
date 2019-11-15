#include "HostBuffersManager.cuh"
#include "HostBuffers.cuh"

#include <iostream>

void HostBuffersManager::init(size_t nBuffers) {
  host_buffers.reserve(nBuffers);
  for(size_t i=0; i<nBuffers; ++i) {
    host_buffers.push_back(new HostBuffers());
    host_buffers.back()->reserve(max_events, check);
    buffer_statuses.push_back(BufferStatus::Empty);
    empty_buffers.push(i);
  }
}

size_t HostBuffersManager::assignBufferToFill() {
  if(empty_buffers.empty()) {
    std::cout << "No empty buffers available" << std::endl;
    std::cout << "Adding new buffers" << std::endl;
    host_buffers.push_back(new HostBuffers());
    host_buffers.back()->reserve(max_events, check);
    buffer_statuses.push_back(BufferStatus::Filling);
    return host_buffers.size()-1;
  }

  auto b = empty_buffers.front();
  empty_buffers.pop();

  buffer_statuses[b] = BufferStatus::Filling;
  return b;
}

size_t HostBuffersManager::assignBufferToProcess() {
  //FIXME required until nvcc supports C++17
  //ideally, this fuction would return a std::optional<size_t>
  if(filled_buffers.empty()) return SIZE_MAX;

  auto b = filled_buffers.front();
  filled_buffers.pop();

  buffer_statuses[b] = BufferStatus::Processing;
  return b;
}

void HostBuffersManager::returnBufferFilled(size_t b) {
  buffer_statuses[b] = BufferStatus::Filled;
  filled_buffers.push(b);
}

void HostBuffersManager::returnBufferProcessed(size_t b) {
  buffer_statuses[b] = BufferStatus::Empty;
  empty_buffers.push(b);
}

void HostBuffersManager::printStatus() const {
  std::cout << host_buffers.size() << " buffers; " << empty_buffers.size() << " empty; " << filled_buffers.size() << " filled." << std::endl;
}

#include <string>

#include <cuda_runtime.h>
#include <Common.h>
#include <Consumers.h>

namespace {
  using std::string;
  using std::to_string;
}

Consumers::Beamline::Beamline(float*& dev_beamline)
  : m_dev_beamline{dev_beamline} {
}

void Consumers::Beamline::consume(std::vector<char> const& data) {
  if (data.size() != m_size) {
    throw StrException{string{"sizes don't match: "} + to_string(m_size) + " " + to_string(data.size())};
  }
  if (!m_dev_beamline.get()) {
    // Allocate space
    char* p = nullptr;
    cudaCheck(cudaMalloc((void**) &m_dev_beamline.get(), data.size()));
  }
  cudaCheck(cudaMemcpy(m_dev_beamline.get(), data.data(), data.size(), cudaMemcpyHostToDevice));
}

#include <string>

#include <cuda_runtime.h>
#include <Common.h>
#include <Consumers.h>

namespace {
  using std::string;
  using std::to_string;
}

Consumers::UTTable::UTTable(PrUTMagnetTool*& tool)
  : m_tool{tool} {}

void Consumers::UTTable::consume(std::vector<char> const& data) {
  if (!m_tool) {
    cudaCheck(cudaMalloc((void**) &m_tool.get(), data.size()));
    m_size = data.size();
  }
  if (m_size != data.size()) {
    throw StrException{string{"sizes don't match: "} + to_string(m_size)
                              + " " + to_string(data.size())};
  }
  cudaCheck(cudaMemcpy(m_tool.get(), data.data(), data.size(), cudaMemcpyHostToDevice));
}

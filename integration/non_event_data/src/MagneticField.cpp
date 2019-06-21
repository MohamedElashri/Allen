#include <string>

#include <cuda_runtime.h>
#include <Common.h>
#include <Consumers.h>

namespace {
  using std::string;
  using std::to_string;
} // namespace

Consumers::MagneticField::MagneticField(float*& dev_magnet_polarity) : m_dev_magnet_polarity {dev_magnet_polarity} {}

void Consumers::MagneticField::consume(std::vector<char> const& data)
{
  if (data.size() != m_size) {
    throw StrException {string {"sizes don't match: "} + to_string(m_size) + " " + to_string(data.size())};
  }
  if (!m_dev_magnet_polarity.get()) {
    // Allocate space
    char* p = nullptr;
    cudaCheck(cudaMalloc((void**) &m_dev_magnet_polarity.get(), data.size()));
  }
  cudaCheck(cudaMemcpy(m_dev_magnet_polarity, data.data(), data.size(), cudaMemcpyHostToDevice));
}

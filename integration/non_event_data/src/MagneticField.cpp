#include <string>

#include <CudaCommon.h>
#include <Common.h>
#include <Consumers.h>

namespace {
  using std::string;
  using std::to_string;
} // namespace

Consumers::MagneticField::MagneticField(gsl::span<float>& dev_magnet_polarity) :
  m_dev_magnet_polarity {dev_magnet_polarity}
{}

void Consumers::MagneticField::consume(std::vector<char> const& data)
{
  if (m_dev_magnet_polarity.get().empty()) {
    // Allocate space
    float* p = nullptr;
    cudaCheck(cudaMalloc((void**) &p, data.size()));
    m_dev_magnet_polarity.get() = {p, static_cast<gsl::span<char>::index_type>(data.size() / sizeof(float))};
  }
  else if (data.size() != static_cast<size_t>(m_dev_magnet_polarity.get().size())) {
    throw StrException {string {"sizes don't match: "} + to_string(m_dev_magnet_polarity.get().size()) + " " +
                        to_string(data.size() / sizeof(float))};
  }

  cudaCheck(cudaMemcpy(m_dev_magnet_polarity.get().data(), data.data(), data.size(), cudaMemcpyHostToDevice));
}

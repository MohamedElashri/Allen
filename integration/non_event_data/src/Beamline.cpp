/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <string>

#include <BackendCommon.h>
#include <Common.h>
#include <Consumers.h>

namespace {
  using std::string;
  using std::to_string;
} // namespace

Consumers::Beamline::Beamline(gsl::span<float>& dev_beamline) : m_dev_beamline {dev_beamline} {}

void Consumers::Beamline::consume(std::vector<char> const& data)
{
  // Version "0" of the beamline has floats in it: the x and y
  // position. A version number was absent, so we use the fact
  // that we got 8 bytes. This is ugly but at this point it's better
  // to stay backwards compatible.

  // Version 1 has a version number (unsigned int) followed by 3
  // floats for (x, y, z) position and 6 floats representing a
  // triangular covariance matrix. We don't copy the version number to
  // stay backwards compatible.

  assert(data.size() >= 8u);
  auto const version = data.size() == 8u ? 0u : reinterpret_cast<unsigned const*>(data.data())[0];
  auto const data_size = version == 0u ? data.size() : data.size() - sizeof(unsigned);

  if (m_dev_beamline.get().empty()) {
    // Allocate space
    float* p = nullptr;
    Allen::malloc((void**) &p, data_size);
    m_dev_beamline.get() = {p, static_cast<span_size_t<char>>(data_size / sizeof(float))};
  }
  else if (data_size != static_cast<size_t>(sizeof(float) * m_dev_beamline.get().size())) {
    throw StrException {string {"Number of floats doesn't match: "} + to_string(m_dev_beamline.get().size()) + " " +
                        to_string(data_size / sizeof(float))};
  }

  char const* data_start = version == 0u ? data.data() : data.data() + sizeof(unsigned);
  Allen::memcpy(m_dev_beamline.get().data(), data_start, data_size, Allen::memcpyHostToDevice);
}

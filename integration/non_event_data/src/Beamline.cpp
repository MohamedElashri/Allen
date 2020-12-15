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
  if (m_dev_beamline.get().empty()) {
    // Allocate space
    float* p = nullptr;
    Allen::malloc((void**) &p, data.size());
    m_dev_beamline.get() = {p, static_cast<span_size_t<char>>(data.size() / sizeof(float))};
  }
  else if (data.size() != static_cast<size_t>(sizeof(float) * m_dev_beamline.get().size())) {
    throw StrException {string {"sizes don't match: "} + to_string(m_dev_beamline.get().size()) + " " +
                        to_string(data.size() / sizeof(float))};
  }

  Allen::memcpy(m_dev_beamline.get().data(), data.data(), data.size(), Allen::memcpyHostToDevice);
}

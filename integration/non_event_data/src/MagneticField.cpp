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
#include <string>

#include <BackendCommon.h>
#include <Common.h>
#include <Consumers.h>

namespace {
  using std::string;
  using std::to_string;
} // namespace

Consumers::MagneticField::MagneticField(
  gsl::span<float>& dev_magnet_polarity,
  std::array<float, 1>& host_magnet_polarity) :
  m_dev_magnet_polarity {dev_magnet_polarity},
  m_host_magnet_polarity {host_magnet_polarity}
{}

void Consumers::MagneticField::consume(std::vector<char> const& data)
{
  auto& dev_magnet_polarity = m_dev_magnet_polarity.get();
  auto& host_magnet_polarity = m_host_magnet_polarity.get();
  if (dev_magnet_polarity.empty()) {
    // Allocate space
    float* p = nullptr;
    Allen::malloc((void**) &p, data.size());
    dev_magnet_polarity = {p, static_cast<span_size_t<char>>(data.size() / sizeof(float))};
  }
  else if (data.size() != static_cast<size_t>(sizeof(float) * dev_magnet_polarity.size())) {
    throw StrException {string {"sizes don't match: "} + to_string(dev_magnet_polarity.size()) + " " +
                        to_string(data.size() / sizeof(float))};
  }
  std::memcpy(host_magnet_polarity.data(), data.data(), data.size());
  Allen::memcpy(dev_magnet_polarity.data(), data.data(), data.size(), Allen::memcpyHostToDevice);
}

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
#include "VeloDefinitions.cuh"
#include "ClusteringDefinitions.cuh"

namespace {
  using std::string;
  using std::to_string;
  using std::vector;
} // namespace

Consumers::VPGeometry::VPGeometry(Constants& constants) : m_constants {constants} {}

void Consumers::VPGeometry::initialize(vector<char> const&)
{
  Allen::malloc((void**) &m_constants.get().dev_velo_geometry, sizeof(VeloGeometry));
}

void Consumers::VPGeometry::consume(vector<char> const& data)
{
  auto& dev_velo_geometry = m_constants.get().dev_velo_geometry;
  if (dev_velo_geometry == nullptr) {
    initialize(data);
  }
  // FIXME need to check the size of data is as expected

  VeloGeometry host_velo_geometry {data};
  Allen::memcpy(dev_velo_geometry, &host_velo_geometry, sizeof(VeloGeometry), Allen::memcpyHostToDevice);
}

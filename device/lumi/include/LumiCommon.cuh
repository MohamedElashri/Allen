/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <LumiDefinitions.cuh>

inline __device__ void
fillLumiInfo(Lumi::LumiInfo& info, const unsigned offset, const unsigned size, const unsigned value)
{
  info.size = size;
  info.offset = offset;
  info.value = value;
}

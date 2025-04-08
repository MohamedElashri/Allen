/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"

struct Plume_ {

  int32_t ovr_th[2] = {
    0u,
    0u}; // overthreshold bits feb0=ovr_th[0] and feb1=ovr_th[1], first left bit of the 32 bit word is ch.0

  std::array<float, 128> ADC_counts; // N=128 objects of type float for N ADC counts, [0]=channel0.
};

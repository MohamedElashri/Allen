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

  struct bit_field {
    unsigned x : 12;
  };

  int32_t ovr_th[2] = {
    0u,
    0u}; // overthreshold bits feb0=ovr_th[0] and feb1=ovr_th[1], first left bit of the 32 bit word is ch.0

  bit_field ADC_counts[64]; // N=64 objects of type bitset 12 (12 bit word) for N ADC counts. From 0 to 31 Feb0, from 32
                            // to 63 Feb1; [0]=ch.0
};

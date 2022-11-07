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

  int64_t ovr_th = 0; // overthreshold bits in a 64 bit word

  bit_field ADC_counts[64]; // N=64 objects of type bitset 12 (12 bit word) for N ADC counts
};

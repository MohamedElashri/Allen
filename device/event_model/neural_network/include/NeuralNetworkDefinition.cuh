/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#pragma once

#include "BackendCommon.h"

namespace Allen::NeuralNetwork {
  namespace Model {
    template<unsigned num_input, unsigned num_node>
    struct SingleLayerFCNN_t {
      constexpr static unsigned nInput = num_input;
      constexpr static unsigned nNode = num_node;
      // Data preprocessing
      float mean[nInput];
      float std[nInput];
      // Model data
      float weights1[nNode][nInput];
      float bias1[nNode];
      float weights2[nNode];
      float bias2;
    };

    using ForwardGhostKiller = SingleLayerFCNN_t<7, 32>;
    using MatchingGhostKiller = SingleLayerFCNN_t<7, 32>;
    using MatchingWithUTGhostKiller = SingleLayerFCNN_t<11, 32>;
  } // namespace Model

} // namespace Allen::NeuralNetwork

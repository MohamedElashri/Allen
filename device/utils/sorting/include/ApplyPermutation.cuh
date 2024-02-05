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
/*!
 *  \brief     apply_permutation sorting tool.
 *  \author    Daniel Hugo Campora Perez
 *  \author    Dorothea vom Bruch
 *  \date      2018
 */

#pragma once

#include "BackendCommon.h"
#include <cassert>

/**
 * @brief Apply permutation from prev container to new container
 */
template<class T>
__host__ __device__ void apply_permutation(
  unsigned* permutation,
  const unsigned hit_start,
  const unsigned number_of_hits,
  T* prev_container,
  T* new_container)
{
  // Apply permutation across all hits
  FOR_STATEMENT(unsigned, i, number_of_hits)
  {
    const auto hit_index_global = permutation[hit_start + i];
    new_container[hit_start + i] = prev_container[hit_index_global];
  }
}

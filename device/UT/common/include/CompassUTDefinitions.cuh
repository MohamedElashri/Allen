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
#pragma once

#include "UTDefinitions.cuh"
#include "SystemOfUnits.h"
#include "BackendCommon.h"

namespace CompassUT {

  constexpr unsigned num_sectors = 5;
  constexpr unsigned num_elems = num_sectors * 2;

} // namespace CompassUT

//=========================================================================
// Point to correct position for windows pointers
//=========================================================================
struct TrackCandidates {
  const short* m_base_pointer;

  __device__ TrackCandidates(const short* base_pointer) : m_base_pointer(base_pointer) {}

  __device__ inline short get_from(const int layer, const int sector, const int element) const
  {
    return m_base_pointer
      [sector * UT::Constants::n_layers * UT::Constants::num_thr_compassut + layer * UT::Constants::num_thr_compassut +
       element];
  }

  __device__ inline short get_size(const int layer, const int sector, const int element) const
  {
    return m_base_pointer
      [(sector + (CompassUT::num_elems / 2)) * UT::Constants::n_layers * UT::Constants::num_thr_compassut +
       layer * UT::Constants::num_thr_compassut + element];
  }
};

//=========================================================================
// Save the best q/p, chi2 and number of hits
//=========================================================================
struct BestParams {
  float qp;
  float chi2UT;
  int n_hits;
  float x, z, tx;

  __device__ BestParams()
  {
    qp = 0.0f;
    chi2UT = UT::Constants::maxPseudoChi2;
    n_hits = 0;
    x = -10000;
    tx = -10000;
    z = -10000;
  }
};

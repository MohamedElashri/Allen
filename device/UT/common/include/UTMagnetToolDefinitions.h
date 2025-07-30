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

/**
 * Constants mainly taken from PrVeloUT.h from Rec
 */
struct UTMagnetTool {
  static const int N_dxLay_vals = 124;
  static const int N_bdl_vals = 3751;

  // const float m_averageDist2mom = 0.0;
  float dxLayTable[N_dxLay_vals];
  float bdlTable[N_bdl_vals];

  UTMagnetTool() {}
  UTMagnetTool(const float* _dxLayTable, const float* _bdlTable)
  {
    for (int i = 0; i < N_dxLay_vals; ++i) {
      dxLayTable[i] = _dxLayTable[i];
    }
    for (int i = 0; i < N_bdl_vals; ++i) {
      bdlTable[i] = _bdlTable[i];
    }
  }
};

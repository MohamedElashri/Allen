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

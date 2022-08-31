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
#include "hybrid_seeding_helpers.cuh"

/*
  Defines all the numbers which make up a Case
*/

namespace hybrid_seeding {
  class Case {
  public:
    // The three parameters that truely define a case, apart from tolerances
    unsigned int iFirst;
    unsigned int iMiddle;
    unsigned int iLast;
    unsigned int iRem[3];
    // Topology
    float t1_z;
    float t2_z;

    float dz[6];
    float dz2[6];

    float invZf;
    // Corrections
    float twoHitScale;
    float txCorr;
    float xRefCorr;
    float invZlZf;
    // Kinematics
    float invPTerms_1; // should be configurable
    float invPTerms_2; // should be configurable
    // Two-hit
    //    float alphaCorr_0;//should be configurable
    //    float alphaCorr_1;//should be configurable
    float tol2Hit;
    float alphaCorr;
    // Three hit
    float delSeedCorr;
    float delSeedCorr2;
    float threeHit0; // Should be configurable
    float threeHit1; // Should be configurable

    // Remaining
    float tolRem; // should be configurable

    // Fit x
    float startingFitMatrix[6];
    float scoreOffset;

    __device__ Case(
      unsigned int _iFirst,
      unsigned int _iMiddle,
      unsigned int _iLast,
      unsigned int _iremainT1,
      unsigned int _iremainT2,
      unsigned int _iremainT3,
      float _pMin,
      float _scoreOffset)
    {
      iFirst = _iFirst;
      iMiddle = _iMiddle;
      iLast = _iLast;
      iRem[0] = _iremainT1;
      iRem[1] = _iremainT2;
      iRem[2] = _iremainT3;
      float pMin = _pMin;
      // Topological information
      // FIXME: this should access the geometry & options of first/last layers
      t1_z = seed_xz::geomInfo::z[iFirst];
      t2_z = seed_xz::geomInfo::z[iMiddle];
      float t3_z = seed_xz::geomInfo::z[iLast];
      float t1_rem_z = seed_xz::geomInfo::z[iRem[0]];
      float t2_rem_z = seed_xz::geomInfo::z[iRem[1]];
      float t3_rem_z = seed_xz::geomInfo::z[iRem[2]];
      invZf = 1.f / (t1_z);
      invZlZf = 1.f / (t3_z - t1_z);
      dz[0] = t1_z - hybrid_seeding::z_ref;
      dz[1] = t3_z - hybrid_seeding::z_ref;
      dz[2] = t2_z - hybrid_seeding::z_ref;
      dz[3] = t1_rem_z - hybrid_seeding::z_ref;
      dz[4] = t2_rem_z - hybrid_seeding::z_ref;
      dz[5] = t3_rem_z - hybrid_seeding::z_ref;

      for (auto i = 0; i < 6; i++)
        dz2[i] = dz[i] * dz[i] * (1.f + hybrid_seeding::dRatio * dz[i]);

      // Corrections
      txCorr = dz[0] + dz[1] + hybrid_seeding::dRatio * (dz[1] * dz[1] + dz[0] * dz[0] + dz[0] * dz[1]);
      xRefCorr = dz[0] * (dz[0] - txCorr + hybrid_seeding::dRatio * dz[0] * dz[0]);
      // Kinematics
      invPTerms_1 = 1.6322e-07f;  // FIXME
      invPTerms_2 = -5.0217e-12f; // FIXME
      float alphaCorr_0 = 2.180e06f;
      float alphaCorr_1 = -1073.f;
      // Two-hit calculations
      float kDelta = t1_z / (t3_z - t1_z);                                  //---LoH: x0 = kDelta * DeltaInf
      float delta = invPTerms_1 * invPTerms_1 + (4.f * invPTerms_2 / pMin); //--LoH: discriminant of the polynomial
      tol2Hit = (1.f / kDelta) * (-invPTerms_1 + std::sqrt(delta)) / 2.f / invPTerms_2;
      alphaCorr = (alphaCorr_0 / kDelta) / (pMin - alphaCorr_1);
      twoHitScale = (t3_z + alphaCorr) / t1_z;
      // Three-hit calculations
      delSeedCorr = 1.f / ((((t2_z - t1_z) * invZlZf) * (dz2[1] - dz2[0])) + (dz2[0] - dz2[2]));
      threeHit0 = 1.82e-06f / delSeedCorr;
      threeHit1 = 2.49e-02f / delSeedCorr;

      // Remaining
      tolRem = 0.5f;

      // Fit matrix caching
      startingFitMatrix[0] = 3.f;
      startingFitMatrix[1] = dz[0] + dz[2] + dz[1];
      startingFitMatrix[2] = dz2[0] + dz2[2] + dz2[1];
      startingFitMatrix[3] = dz[0] * dz[0] + dz[2] * dz[2] + dz[1] * dz[1];
      startingFitMatrix[4] = dz[0] * dz2[0] + dz[2] * dz2[2] + dz[1] * dz2[1];
      startingFitMatrix[5] = dz2[0] * dz2[0] + dz2[2] * dz2[2] + dz2[1] * dz2[1];
      scoreOffset = _scoreOffset;
    };
  };
} // namespace hybrid_seeding

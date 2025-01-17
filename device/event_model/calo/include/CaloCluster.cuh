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

#include <climits>
#include <BackendCommon.h>
#include "CaloConstants.cuh"
#include "CaloGeometry.cuh"
#include "JetDefinitions.cuh"

struct CaloSeedCluster {
  uint16_t id = 0;
  int16_t adc = 0;
  float x = 0.f;
  float y = 0.f;
  float e = 0.f;

  __device__ __host__ CaloSeedCluster() {}

  __device__ __host__
  CaloSeedCluster(const uint16_t& cellid, const int16_t& a, const float& rX, const float& rY, const float& energy) :
    id {cellid},
    adc {a}, x {rX}, y {rY}, e {energy}
  {}
};

struct CaloCluster {
  float e = 0.f;
  float et = 0.f;
  float x = 0.f;
  float y = 0.f;
  uint16_t center_id = USHRT_MAX;
  uint16_t digits[Calo::Constants::max_neighbours] =
    {USHRT_MAX, USHRT_MAX, USHRT_MAX, USHRT_MAX, USHRT_MAX, USHRT_MAX, USHRT_MAX, USHRT_MAX, USHRT_MAX};
  float CaloNeutralE19 = -1.f;
  bool isTrackMatched = false;
  bool isBremMatched = false;

  __device__ __host__ CaloCluster() {}

  __device__ __host__
  CaloCluster(const CaloGeometry& calo, const CaloSeedCluster& seed, const bool& isTM, const bool& isBM) :
    e {calo.getE(seed.id, seed.adc)},
    x {seed.x}, y {seed.y}, center_id {seed.id}, isTrackMatched {isTM}, isBremMatched {isBM}
  {}

  // Construct a CALO cluster from jet data.
  __device__ __host__ CaloCluster(const Jets::Jet& jet) :
    e {jet.pt * coshf(jet.eta)}, et {jet.pt}, x {jet.pt > 0.f ? (jet.pt * sinf(jet.phi)) / (jet.pt * sinhf(jet.eta)) *
                                                                  Calo::Constants::z :
                                                                0.f},
    y {jet.pt > 0.f ? (jet.pt * cosf(jet.phi)) / (jet.pt * sinhf(jet.eta)) * Calo::Constants::z : 0.f}
  {}

  __device__ __host__ void SetE(float newE) { this->e = newE; }

  __device__ __host__ void CalcEt()
  {
    // Computes cluster Et
    const float& z = Calo::Constants::z;
    float sintheta = (this->x * this->x + this->y * this->y) / (this->x * this->x + this->y * this->y + z * z);
    sintheta = sqrtf(sintheta);
    this->et = this->e * sintheta;
  }
};

struct TwoCaloCluster {
  float e1 = 0.f;
  float et1 = 0.f;
  float x1 = 0.f;
  float y1 = 0.f;
  float CaloNeutralE19_1 = -1.f;

  float e2 = 0.f;
  float et2 = 0.f;
  float x2 = 0.f;
  float y2 = 0.f;
  float CaloNeutralE19_2 = -1.f;

  float Mass = 0.f;
  float Pt = 0.f;
  float Eta = 0.f;
  float Distance = 0.f;

  __device__ __host__ TwoCaloCluster() {}

  __device__ __host__ TwoCaloCluster(const CaloCluster& c1, const CaloCluster& c2) :
    e1 {c1.e}, et1 {c1.et}, x1 {c1.x}, y1 {c1.y}, CaloNeutralE19_1 {c1.CaloNeutralE19}, e2 {c2.e}, et2 {c2.et},
    x2 {c2.x}, y2 {c2.y}, CaloNeutralE19_2 {c2.CaloNeutralE19}
  {
    CalcMassEt(c1, c2);
    CalcDistance(c1, c2);
  }

private:
  __device__ __host__ void CalcMassEt(const CaloCluster& c1, const CaloCluster& c2)
  {
    const float& z = Calo::Constants::z; // mm

    // Cluster 1
    float sintheta = sqrtf((c1.x * c1.x + c1.y * c1.y) / (c1.x * c1.x + c1.y * c1.y + z * z));
    float cosPhi = c1.x / sqrtf(c1.x * c1.x + c1.y * c1.y);
    float sinPhi = c1.y / sqrtf(c1.x * c1.x + c1.y * c1.y);
    const float E1_x = c1.e * sintheta * cosPhi;
    const float E1_y = c1.e * sintheta * sinPhi;
    const float E1_z = c1.e * z / sqrtf(c1.x * c1.x + c1.y * c1.y + z * z);

    // Cluster 2
    sintheta = sqrtf((c2.x * c2.x + c2.y * c2.y) / (c2.x * c2.x + c2.y * c2.y + z * z));
    cosPhi = c2.x / sqrtf(c2.x * c2.x + c2.y * c2.y);
    sinPhi = c2.y / sqrtf(c2.x * c2.x + c2.y * c2.y);
    const float E2_x = c2.e * sintheta * cosPhi;
    const float E2_y = c2.e * sintheta * sinPhi;
    const float E2_z = c2.e * z / sqrtf(c2.x * c2.x + c2.y * c2.y + z * z);

    // TwoCluster
    // Note: for photons, \vec{p} = \vec{E}
    const float Pt2 = (E1_x + E2_x) * (E1_x + E2_x) + (E1_y + E2_y) * (E1_y + E2_y);
    const float P2 = Pt2 + (E1_z + E2_z) * (E1_z + E2_z);
    this->Pt = sqrtf(Pt2);
    this->Mass = sqrtf((c2.e + c1.e) * (c2.e + c1.e) - P2);
    this->Eta = atanhf((E1_z + E2_z) / sqrtf(P2));
  }

  __device__ __host__ void CalcDistance(const CaloCluster& c1, const CaloCluster& c2)
  {
    this->Distance = sqrtf((c1.x - c2.x) * (c1.x - c2.x) + (c1.y - c2.y) * (c1.y - c2.y));
  }
};

struct CaloOverlapCluster {
  uint16_t id = 0;
  uint16_t adc = 0;
  uint16_t seedId_1 = 0;
  uint16_t clId_1 = 0;
  uint16_t seedId_2 = 0;
  uint16_t clId_2 = 0;

  __device__ __host__ CaloOverlapCluster() {}

  __device__ __host__
  CaloOverlapCluster(uint16_t cellid, uint16_t a, uint16_t seed1, uint16_t cl1, uint16_t seed2, uint16_t cl2) :
    id {cellid},
    adc {a}, seedId_1 {seed1}, clId_1 {cl1}, seedId_2 {seed2}, clId_2 {cl2}
  {}
};

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

struct CaloSeedCluster {
  uint16_t id = 0;
  int16_t adc = 0;
  float x = 0.f;
  float y = 0.f;

  __device__ __host__ CaloSeedCluster() {}

  __device__ __host__ CaloSeedCluster(uint16_t cellid, int16_t a, float rX, float rY) :
    id {cellid}, adc {a}, x {rX}, y {rY}
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

  __device__ __host__ CaloCluster() {}

  __device__ __host__ CaloCluster(const CaloGeometry& calo, const CaloSeedCluster& seed) :
    e {calo.getE(seed.id, seed.adc)}, x {seed.x}, y {seed.y}, center_id {seed.id}
  {}

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
  float Et = 0.f;
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

    float sintheta = sqrtf((c1.x * c1.x + c1.y * c1.y) / (c1.x * c1.x + c1.y * c1.y + z * z));
    float cosPhi = c1.x / sqrtf(c1.x * c1.x + c1.y * c1.y);
    float sinPhi = c1.y / sqrtf(c1.x * c1.x + c1.y * c1.y);
    const float E1_x = c1.e * sintheta * cosPhi;
    const float E1_y = c1.e * sintheta * sinPhi;
    const float E1_z = c1.e * z / sqrtf(c1.x * c1.x + c1.y * c1.y + z * z);

    sintheta = sqrtf((c2.x * c2.x + c2.y * c2.y) / (c2.x * c2.x + c2.y * c2.y + z * z));
    cosPhi = c2.x / sqrtf(c2.x * c2.x + c2.y * c2.y);
    sinPhi = c2.y / sqrtf(c2.x * c2.x + c2.y * c2.y);
    const float E2_x = c2.e * sintheta * cosPhi;
    const float E2_y = c2.e * sintheta * sinPhi;
    const float E2_z = c2.e * z / sqrtf(c2.x * c2.x + c2.y * c2.y + z * z);

    this->Et = sqrtf((E1_x + E2_x) * (E1_x + E2_x) + (E1_y + E2_y) * (E1_y + E2_y));
    this->Mass = sqrtf(
      (c2.e + c1.e) * (c2.e + c1.e) - (E1_x + E2_x) * (E1_x + E2_x) - (E1_y + E2_y) * (E1_y + E2_y) -
      (E1_z + E2_z) * (E1_z + E2_z));
  }

  __device__ __host__ void CalcDistance(const CaloCluster& c1, const CaloCluster& c2)
  {
    this->Distance = sqrtf((c1.x - c2.x) * (c1.x - c2.x) + (c1.y - c2.y) * (c1.y - c2.y));
  }
};

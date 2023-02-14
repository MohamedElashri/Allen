/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration          *
\*****************************************************************************/
#pragma once

// source: https://root.cern/doc/v608/eta_8h_source.html#l00050
__device__ __host__ inline float eta_from_rho_z(const float rho, const float z)
{
  if (rho > 0.f) {
    // value to control Taylor expansion of sqrt
    // constant value from std::pow(std::numeric_limits<float>::epsilon(), static_cast<float>(-.25));
    constexpr float big_z_scaled = 53.817371f;
    float z_scaled = z / rho;
    if (std::fabs(z_scaled) < big_z_scaled) {
      // HLT2 eta always calculated with this
      // No difference for forward tracks, O(10-4) for backward ones
      return std::log(z_scaled + std::sqrt(z_scaled * z_scaled + 1.f));
    }
    else {
      // apply correction using first order Taylor expansion of sqrt
      return z > 0.f ? std::log(2.f * z_scaled + 0.5f / z_scaled) : -std::log(-2.f * z_scaled);
    }
  }
  // case vector has rho = 0
  return z + 22756.f;
}

__device__ __host__ inline float eta_from_rho(const float rho)
{
  const float z = 1.f;
  return eta_from_rho_z(rho, z);
}

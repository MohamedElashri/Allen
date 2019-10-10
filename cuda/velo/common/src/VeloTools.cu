#include "VeloTools.cuh"

__device__ float hit_phi_odd(const float x, const float y) { return atan2f(y, x); }

__device__ float hit_phi_even(const float x, const float y)
{
  const float phi = atan2f(y, x);
  const float addition = (phi < 0.f) ? (2 * static_cast<float>(CUDART_PI_F)) : 0.f;
  return phi + addition;
}

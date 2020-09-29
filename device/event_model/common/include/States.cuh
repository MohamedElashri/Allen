#pragma once

#include "CudaCommon.h"

/**
 * @brief A simplified state for the Velo
 *
 *        {x, y, z, tx, ty}
 *
 *        associated with a simplified covariance
 *        since we do two fits (one in X, one in Y)
 *
 *        c00 0.f c20 0.f 0.f
 *            c11 0.f c31 0.f
 *                c22 0.f 0.f
 *                    c33 0.f
 *                        0.f
 */
struct KalmanVeloState {
  float x, y, z, tx, ty;
  float c00, c20, c22, c11, c31, c33;

  __host__ __device__ KalmanVeloState() {}

  __host__ __device__ KalmanVeloState(const KalmanVeloState& other) :
    x(other.x), y(other.y), z(other.z), tx(other.tx), ty(other.ty), c00(other.c00), c20(other.c20), c22(other.c22),
    c11(other.c11), c31(other.c31), c33(other.c33)
  {}
};

/**
 * Minimal state used in most track reconstruction algorithms
 */
struct MiniState {
  float x, y, z, tx, ty;

  __host__ __device__ MiniState() {}

  __host__ __device__ MiniState(const KalmanVeloState& other) :
    x(other.x), y(other.y), z(other.z), tx(other.tx), ty(other.ty)
  {}

  __host__ __device__ MiniState(const MiniState& other) : x(other.x), y(other.y), z(other.z), tx(other.tx), ty(other.ty)
  {}

  __host__ __device__ MiniState(const float _x, const float _y, const float _z, const float _tx, const float _ty) :
    x(_x), y(_y), z(_z), tx(_tx), ty(_ty)
  {}

  __host__ __device__ MiniState operator=(const MiniState& other)
  {
    x = other.x;
    y = other.y;
    z = other.z;
    tx = other.tx;
    ty = other.ty;

    return *this;
  }
};

struct ProjectionState {
  float x, y, z;

  __host__ __device__ ProjectionState() {}

  __host__ __device__ ProjectionState(const MiniState& state) : x(state.x), y(state.y), z(state.z) {}

  __host__ __device__ ProjectionState(const KalmanVeloState& state) : x(state.x), y(state.y), z(state.z) {}
};

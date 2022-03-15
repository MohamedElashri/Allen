/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "Common.h"

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

  __host__ __device__ KalmanVeloState(
    const float _x,
    const float _y,
    const float _z,
    const float _tx,
    const float _ty,
    const float _c00,
    const float _c20,
    const float _c22,
    const float _c11,
    const float _c31,
    const float _c33)
  {
    x = _x;
    y = _y;
    z = _z;
    tx = _tx;
    ty = _ty;
    c00 = _c00;
    c20 = _c20;
    c22 = _c22;
    c11 = _c11;
    c31 = _c31;
    c33 = _c33;
  }

  __host__ __device__ KalmanVeloState(const KalmanVeloState& other) :
    x(other.x), y(other.y), z(other.z), tx(other.tx), ty(other.ty), c00(other.c00), c20(other.c20), c22(other.c22),
    c11(other.c11), c31(other.c31), c33(other.c33)
  {}
};

/**
 * Minimal state used in most track reconstruction algorithms
 */
struct MiniState {
  float x = 0, y = 0, z = 0, tx = 0, ty = 0;

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

namespace Allen {
  namespace Views {
    namespace Physics {
      struct KalmanState {
      private:
        // 6 elements to define the state: x, y, z, tx, ty, qop
        constexpr static unsigned nb_elements_state = 6;
        // Assume (x, tx) and (y, ty) are uncorrelated for 6 elements + chi2 and ndf
        constexpr static unsigned nb_elements_cov = 8;

        const float* m_base_pointer = nullptr;
        unsigned m_index = 0;
        unsigned m_total_number_of_tracks = 0;

      public:
        __host__ __device__
        KalmanState(const char* base_pointer, const unsigned index, const unsigned total_number_of_tracks) :
          m_base_pointer(reinterpret_cast<const float*>(base_pointer)),
          m_index(index), m_total_number_of_tracks(total_number_of_tracks)
        {}

        __host__ __device__ float x() const { return m_base_pointer[nb_elements_state * m_index]; }

        __host__ __device__ float y() const { return m_base_pointer[nb_elements_state * m_index + 1]; }

        __host__ __device__ float z() const { return m_base_pointer[nb_elements_state * m_index + 2]; }

        __host__ __device__ float tx() const { return m_base_pointer[nb_elements_state * m_index + 3]; }

        __host__ __device__ float ty() const { return m_base_pointer[nb_elements_state * m_index + 4]; }

        __host__ __device__ float qop() const { return m_base_pointer[nb_elements_state * m_index + 5]; }

        __host__ __device__ float c00() const
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index];
        }

        __host__ __device__ float c20() const
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 1];
        }

        __host__ __device__ float c22() const
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 2];
        }

        __host__ __device__ float c11() const
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 3];
        }

        __host__ __device__ float c31() const
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 4];
        }

        __host__ __device__ float c33() const
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 5];
        }

        __host__ __device__ float chi2() const
        {
          return m_base_pointer[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 6];
        }

        __host__ __device__ unsigned ndof() const
        {
          return reinterpret_cast<const unsigned*>(
            m_base_pointer)[nb_elements_state * m_total_number_of_tracks + nb_elements_cov * m_index + 7];
        }

        __host__ __device__ float px() const { return (tx() / fabsf(qop())) / sqrtf(1.0f + tx() * tx() + ty() * ty()); }

        __host__ __device__ float py() const { return (ty() / fabsf(qop())) / sqrtf(1.0f + tx() * tx() + ty() * ty()); }

        __host__ __device__ float pz() const { return (1.0f / fabsf(qop())) / sqrtf(1.0f + tx() * tx() + ty() * ty()); }

        __host__ __device__ float pt() const
        {
          const float sumt2 = tx() * tx() + ty() * ty();
          return (sqrtf(sumt2) / fabsf(qop())) / sqrtf(1.0f + sumt2);
        }

        __host__ __device__ float p() const { return 1.0f / fabsf(qop()); }

        __host__ __device__ float e(const float mass) const { return sqrtf(p() * p() + mass * mass); }

        __host__ __device__ float eta() const { return atanhf(pz() / p()); }

        __host__ __device__ operator MiniState() const { return MiniState {x(), y(), z(), tx(), ty()}; }

        __host__ __device__ operator KalmanVeloState() const
        {
          return KalmanVeloState {x(), y(), z(), tx(), ty(), c00(), c20(), c22(), c11(), c31(), c33()};
        }
      };

      struct KalmanStates {
      private:
        const char* m_base_pointer = nullptr;
        unsigned m_offset = 0;
        unsigned m_size = 0;
        unsigned m_total_number_of_tracks = 0;

      public:
        __host__ __device__ KalmanStates(
          const char* base_pointer,
          const unsigned* offset_tracks,
          const unsigned event_number,
          const unsigned number_of_events) :
          m_base_pointer(base_pointer),
          m_offset(offset_tracks[event_number]), m_size(offset_tracks[event_number + 1] - offset_tracks[event_number]),
          m_total_number_of_tracks(offset_tracks[number_of_events])
        {}

        __host__ __device__ unsigned size() const { return m_size; }

        __host__ __device__ unsigned offset() const { return m_offset; }

        __host__ __device__ KalmanState state(const unsigned track_index) const
        {
          assert(track_index < m_size);
          return KalmanState {m_base_pointer, m_offset + track_index, m_total_number_of_tracks};
        }
      };

      struct SecondaryVertex {
        // 3 elements for position + 3 elements for momentum
        constexpr static unsigned nb_elements_vrt = 6;
        // Just the 3x3 position covariance + chi2 + ndof?
        constexpr static unsigned nb_elements_cov = 8;

      private:
        const float* m_base_pointer = nullptr;
        unsigned m_index = 0;
        unsigned m_total_number_of_vrts = 0;

      public:
        __host__ __device__
        SecondaryVertex(const char* base_pointer, const unsigned index, const unsigned total_number_of_vrts) :
          m_base_pointer(reinterpret_cast<const float*>(base_pointer)),
          m_index(index), m_total_number_of_vrts(total_number_of_vrts)
        {}

        __host__ __device__ float x() const { return m_base_pointer[nb_elements_vrt * m_index]; }

        __host__ __device__ float y() const { return m_base_pointer[nb_elements_vrt * m_index + 1]; }

        __host__ __device__ float z() const { return m_base_pointer[nb_elements_vrt * m_index + 2]; }

        __host__ __device__ float px() const { return m_base_pointer[nb_elements_vrt * m_index + 3]; }

        __host__ __device__ float py() const { return m_base_pointer[nb_elements_vrt * m_index + 4]; }

        __host__ __device__ float pz() const { return m_base_pointer[nb_elements_vrt * m_index + 5]; }

        __host__ __device__ float c00() const
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index];
        }

        __host__ __device__ float c11() const
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 1];
        }

        __host__ __device__ float c10() const
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 2];
        }

        __host__ __device__ float c22() const
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 3];
        }

        __host__ __device__ float c21() const
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 4];
        }

        __host__ __device__ float c20() const
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 5];
        }

        __host__ __device__ float chi2() const
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 6];
        }

        __host__ __device__ unsigned ndof() const
        {
          return reinterpret_cast<const unsigned*>(
            m_base_pointer)[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 7];
        }

        __host__ __device__ float pt2() const { return px() * px() + py() * py(); }

        __host__ __device__ float pt() const { return sqrtf(pt2()); }

        __host__ __device__ float p2() const { return pt2() + pz() * pz(); }

        __host__ __device__ float p() const { return sqrtf(p2()); }
      };
    } // namespace Physics
  }   // namespace Views
} // namespace Allen
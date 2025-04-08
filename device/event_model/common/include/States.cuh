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

#include "BackendCommon.h"
#include "Common.h"

/**
 * Minimal state used in most track reconstruction algorithms
 */
struct MiniState {

  MiniState() = default;
  MiniState(const MiniState&) = default;
  MiniState& operator=(const MiniState&) = default;

  __host__ __device__ MiniState(const float _x, const float _y, const float _z, const float _tx, const float _ty) :
    m_x(_x), m_y(_y), m_z(_z), m_tx(_tx), m_ty(_ty)
  {}

  __host__ __device__ float x() const { return m_x; }
  __host__ __device__ float y() const { return m_y; }
  __host__ __device__ float z() const { return m_z; }
  __host__ __device__ float tx() const { return m_tx; }
  __host__ __device__ float ty() const { return m_ty; }

  __host__ __device__ float& x() { return m_x; }
  __host__ __device__ float& y() { return m_y; }
  __host__ __device__ float& z() { return m_z; }
  __host__ __device__ float& tx() { return m_tx; }
  __host__ __device__ float& ty() { return m_ty; }

  __host__ __device__ float xAt(float z) const { return m_x + m_tx * (z - m_z); }
  __host__ __device__ float yAt(float z) const { return m_y + m_ty * (z - m_z); }

  float m_x, m_y, m_z, m_tx, m_ty;
};

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

  KalmanVeloState() = default;
  KalmanVeloState(const KalmanVeloState&) = default;
  KalmanVeloState& operator=(const KalmanVeloState&) = default;

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
    m_ministate = MiniState(_x, _y, _z, _tx, _ty);
    m_c00 = _c00;
    m_c20 = _c20;
    m_c22 = _c22;
    m_c11 = _c11;
    m_c31 = _c31;
    m_c33 = _c33;
  }

  __host__ __device__ float x() const { return m_ministate.x(); }
  __host__ __device__ float y() const { return m_ministate.y(); }
  __host__ __device__ float z() const { return m_ministate.z(); }
  __host__ __device__ float tx() const { return m_ministate.tx(); }
  __host__ __device__ float ty() const { return m_ministate.ty(); }
  __host__ __device__ float c00() const { return m_c00; }
  __host__ __device__ float c20() const { return m_c20; }
  __host__ __device__ float c22() const { return m_c22; }
  __host__ __device__ float c11() const { return m_c11; }
  __host__ __device__ float c31() const { return m_c31; }
  __host__ __device__ float c33() const { return m_c33; }

  __host__ __device__ float& x() { return m_ministate.x(); }
  __host__ __device__ float& y() { return m_ministate.y(); }
  __host__ __device__ float& z() { return m_ministate.z(); }
  __host__ __device__ float& tx() { return m_ministate.tx(); }
  __host__ __device__ float& ty() { return m_ministate.ty(); }
  __host__ __device__ float& c00() { return m_c00; }
  __host__ __device__ float& c20() { return m_c20; }
  __host__ __device__ float& c22() { return m_c22; }
  __host__ __device__ float& c11() { return m_c11; }
  __host__ __device__ float& c31() { return m_c31; }
  __host__ __device__ float& c33() { return m_c33; }

  MiniState m_ministate;
  float m_c00, m_c20, m_c22, m_c11, m_c31, m_c33;
};

struct ProjectionState {
  float x, y, z;

  __host__ __device__ ProjectionState() {}

  __host__ __device__ ProjectionState(const MiniState& state) : x(state.x()), y(state.y()), z(state.z()) {}

  __host__ __device__ ProjectionState(const KalmanVeloState& state) : x(state.x()), y(state.y()), z(state.z()) {}
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
        KalmanState() = default;

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

        __host__ __device__ int charge() const { return qop() > 0 ? +1 : -1; }

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

        __host__ __device__ float rho() const { return sqrtf(tx() * tx() + ty() * ty()); }

        __host__ __device__ float phi() const { return tx() == 0.f && ty() == 0.f ? 0.f : atan2f(tx(), ty()); }

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
        KalmanStates() = default;

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

        // The downstream composite model does not account for errors.
        // Therefore, we repurpose some of the memory originally allocated for error storage to hold other information
        __host__ __device__ float downstream_doca() const
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 0];
        }
        __host__ __device__ float downstream_quality() const
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 1];
        }
        __host__ __device__ float downstream_armentero_podolanski_x() const
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 2];
        }
        __host__ __device__ float downstream_armentero_podolanski_y() const
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 3];
        }
        __host__ __device__ float downstream_helicity() const
        {
          return m_base_pointer[nb_elements_vrt * m_total_number_of_vrts + nb_elements_cov * m_index + 4];
        }
      };

      struct SecondaryVertices {
      private:
        const char* m_base_pointer = nullptr;
        unsigned m_offset = 0;
        unsigned m_size = 0;
        unsigned m_total_number_of_vrts = 0;

      public:
        SecondaryVertices() = default;

        __host__ __device__ SecondaryVertices(
          const char* base_pointer,
          const unsigned* offset_svs,
          const unsigned event_number,
          const unsigned number_of_events) :
          m_base_pointer(base_pointer),
          m_offset(offset_svs[event_number]), m_size(offset_svs[event_number + 1] - offset_svs[event_number]),
          m_total_number_of_vrts(offset_svs[number_of_events])
        {}

        __host__ __device__ unsigned size() const { return m_size; }

        __host__ __device__ unsigned offset() const { return m_offset; }

        __host__ __device__ const SecondaryVertex vertex(const unsigned sv_index) const
        {
          assert(sv_index < m_size);
          return SecondaryVertex {m_base_pointer, m_offset + sv_index, m_total_number_of_vrts};
        }
      };

      template<typename state_type>
      __host__ __device__ void _doca_calc(state_type sA, state_type sB, float& det, float& muA, float& muB)
      {

        float secondAA = sA.tx() * sA.tx() + sA.ty() * sA.ty() + 1.f;
        float secondBB = sB.tx() * sB.tx() + sB.ty() * sB.ty() + 1.f;
        float secondAB = -sA.tx() * sB.tx() - sA.ty() * sB.ty() - 1.f;
        det = secondAA * secondBB - secondAB * secondAB;

        if (fabsf(det) > 0.f) {
          float secondinvAA = secondBB / det;
          float secondinvBB = secondAA / det;
          float secondinvAB = -secondAB / det;
          float firstA = sA.tx() * (sA.x() - sB.x()) + sA.ty() * (sA.y() - sB.y()) + (sA.z() - sB.z());
          float firstB = -sB.tx() * (sA.x() - sB.x()) - sB.ty() * (sA.y() - sB.y()) - (sA.z() - sB.z());
          muA = -(secondinvAA * firstA + secondinvAB * firstB);
          muB = -(secondinvBB * firstB + secondinvAB * firstA);
        }
        return;
      }

      template<typename state_type>
      __host__ __device__ float state_doca(state_type sA, state_type sB)
      {

        float ret = -1;
        float det = 0.f;
        float muA = 0.f;
        float muB = 0.f;
        _doca_calc(sA, sB, det, muA, muB);

        if (fabsf(det) > 0) {
          float dx = (sA.x() + muA * sA.tx()) - (sB.x() + muB * sB.tx());
          float dy = (sA.y() + muA * sA.ty()) - (sB.y() + muB * sB.ty());
          float dz = (sA.z() + muA) - (sB.z() + muB);
          ret = sqrtf(dx * dx + dy * dy + dz * dz);
        }
        return ret;
      }

      template<typename state_type>
      __host__ __device__ float state_poca(state_type sA, state_type sB, float& poca_x, float& poca_y, float& poca_z)
      {
        float det = 0.f;
        float muA = 0.f;
        float muB = 0.f;
        _doca_calc(sA, sB, det, muA, muB);
        if (fabsf(det) > 0) {
          poca_x = 0.5f * (sA.x() + muA * sA.tx() + sB.x() + muB * sB.tx());
          poca_y = 0.5f * (sA.y() + muA * sA.ty() + sB.y() + muB * sB.ty());
          // Because floating point addition is non-associative, the parentheses
          // below are needed to ensure that z does not depend on the order in which
          // tracks are passed to the function.
          poca_z = 0.5f * ((sA.z() + muA) + (sB.z() + muB));
          return true;
        }
        return false;
      }

    } // namespace Physics
  }   // namespace Views
} // namespace Allen

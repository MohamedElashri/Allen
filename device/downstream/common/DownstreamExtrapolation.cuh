/*****************************************************************************\
* (c) Copyright 2022-2024 CERN for the benefit of the LHCb Collaboration      *
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
 * @file DownstreamExtrapolation.cuh
 * @brief This file contains the extrapolation functions for the downstream
 * tracks. The extrapolation is done using the magnet point calculated from Scifi seeds.
 */

#include "States.cuh"
namespace Downstream {
  //
  namespace DownstreamExtrapolation {
    namespace Corrections {
      __device__ inline float dy(const float ty, const float y)
      {
        return (-6.551111E-02f) + (2.695234E-01f) * y + (-2.514965E+03f) * ty;
      }
      __device__ inline float dty(const float ty, const float y)
      {
        return (4.601425E-07f) + (1.066950E-04f) * y + (-9.881966E-01f) * ty;
      }
    } // namespace Corrections

    namespace MagnetPoint {
      __device__ inline float
      zMagnet(const float scifi_x, const float scifi_y, const float scifi_tx, const float scifi_ty, const float qop)
      {
        return (5.362780E+03f) + (1.028418E+04f) * fabsf(qop) + (-3.878377E+08f) * fabsf(qop) * fabsf(qop) +
               (4.366723E-03f) * fabsf(scifi_x) + (-1.904676E-05f) * fabsf(scifi_x) * fabsf(scifi_x) +
               (1.057300E-01f) * fabsf(scifi_y) + (-8.798887E-05f) * fabsf(scifi_y) * fabsf(scifi_y) +
               (3.358789E+01f) * fabsf(scifi_tx) + (8.376555E+02f) * fabsf(scifi_tx) * fabsf(scifi_tx) +
               (-7.903139E+02f) * fabsf(scifi_ty) + (4.627501E+03f) * fabsf(scifi_ty) * fabsf(scifi_ty);
      }
    } // namespace MagnetPoint

    namespace Physics {
      __device__ inline float qop(const float tx, const float ty, const float scifi_tx, const float magnet_polarity)
      {
        const auto dslope = scifi_tx - tx;
        const auto abs_p = (2.011328E+01f) + ((1.208754E+03f) + (5.222969E+02f) * (scifi_tx * scifi_tx) +
                                              (8.131686E+01f) * (scifi_tx * scifi_tx * scifi_tx * scifi_tx) +
                                              (5.099099E+02f) * (scifi_tx * tx) + (2.494386E+03f) * (ty * ty) +
                                              (-6.255134E+03f) * (ty * ty * ty * ty) + (1.891522E+02f) * (tx * tx)) /
                                               fabsf(dslope);
        const auto sign = -dslope * magnet_polarity > 0 ? 1.f : -1.f;
        return sign / abs_p;
      }

      __device__ inline float gamma(const float qop, const float magnet_polarity)
      {
        // (3.669061E-08) + (1.183515E-02) * abs(qop) + (-1.974256E+00) * (qop)**2
        // const auto abs_gamma = (3.790512E-08f) + (1.043583E-02f) * fabsf(qop) + (-2.714840E+00f) * qop*qop;
        const auto abs_gamma = (3.669061E-08f) + (1.183515E-02f) * fabsf(qop) + (-1.974256E+00f) * qop * qop;

        const auto sign = -qop * magnet_polarity > 0 ? 1.f : -1.f;

        return sign * abs_gamma;
      }
    } // namespace Physics

    namespace Tolerance {
      //
      // The tolerance function is fitted by requiring 99% efficiency. Output format: (val, min, max)
      //
      __device__ __forceinline__ float3 X(const unsigned layer, const float qop)
      {
        switch (layer) {
        case 0: return {((5.663452E+03f) * fabsf(qop) + (5.787033E-01f)), 0.5f, 1.4f};
        case 1: return {((1.796488E+04f) * fabsf(qop) + (9.839816E-01f)), 0.6f, 3.6f};
        case 2: return {((1.510435E+04f) * fabsf(qop) + (9.287219E-01f)), 0.6f, 3.1f};
        default: return {((2.426073E+05f) * fabsf(qop) + (1.007460E+00f)), 3.f, 60.8f};
        }
      }

      __device__ __forceinline__ float3 Y(const unsigned layer, const float qop)
      {
        switch (layer) {
        case 0: return {((8.070860E+04f) * fabsf(qop) + (3.080773E+00f)), 3.f, 14.f};
        case 1: return {((8.210163E+04f) * fabsf(qop) + (3.240486E+00f)), 3.f, 14.f};
        case 2: return {((4.204240E+04f) * fabsf(qop) + (-1.042032E-01f)), 3.f, 13.f};
        default: return {((7.942334E+04f) * fabsf(qop) + (2.272749E+00f)), 3.f, 13.f};
        }
      }

    } // namespace Tolerance

    namespace ConstantTolerance {
      __device__ __forceinline__ float X(const unsigned layer)
      {
        switch (layer) {
        case 0: return 3.f;
        case 1: return 5.f;
        case 2: return 5.f;
        default: return 60.f;
        }
      }

      __device__ __forceinline__ float Y(const unsigned layer)
      {
        switch (layer) {
        case 0: return 10.f;
        case 1: return 10.f;
        case 2: return 6.f;
        default: return 10.f;
        }
      }
    } // namespace ConstantTolerance

    struct ExtrapolateTrack {
    private:
      float m_xMagnet;
      float m_yMagnet;
      float m_zMagnet;
      float m_tx;
      float m_ty;
      float m_qop;

    public:
      ExtrapolateTrack() = default;

      __device__ ExtrapolateTrack(
        const float xMagnet,
        const float yMagnet,
        const float zMagnet,
        const float tx,
        const float ty,
        const float qop) :
        m_xMagnet(xMagnet),
        m_yMagnet(yMagnet), m_zMagnet(zMagnet), m_tx(tx), m_ty(ty), m_qop(qop)
      {}

      // This is only used to run for calculate magnet point and estimate the first hit position
      __device__ ExtrapolateTrack(const MiniState scifi_state, const float scifi_qop)
      {
        // Calculate Y extrapolation correction
        const float dty = Corrections::dty(scifi_state.ty(), scifi_state.y());
        const float dy = Corrections::dy(scifi_state.ty(), scifi_state.y());
        m_ty = scifi_state.ty() + dty;

        // Magent point
        m_zMagnet =
          MagnetPoint::zMagnet(scifi_state.x(), scifi_state.y(), scifi_state.tx(), scifi_state.ty(), scifi_qop);
        m_xMagnet = scifi_state.x() + scifi_state.tx() * (m_zMagnet - scifi_state.z());
        m_yMagnet = (scifi_state.y() + dy) + m_ty * (m_zMagnet - scifi_state.z());

        // Slope
        m_tx = m_xMagnet / m_zMagnet;

        // Update momentum
        m_qop = scifi_qop;
      }

      // Wrap
      __device__ inline auto& zMagnet() const { return m_zMagnet; }
      __device__ inline auto& xMagnet() const { return m_xMagnet; }
      __device__ inline auto& tx() const { return m_tx; }
      __device__ inline auto& ty() const { return m_ty; }
      __device__ inline auto& yMagnet() const { return m_yMagnet; }
      __device__ inline auto& qop() const { return m_qop; }

      // Useful extrapolation function
      __device__ inline auto xAtZ(const float z) const { return m_xMagnet + m_tx * (z - m_zMagnet); }

      __device__ inline auto yAtZ(const float z) const { return m_yMagnet + m_ty * (z - m_zMagnet); }

      __device__ inline auto get_new_tx(const float z, const float x) { return (x - m_xMagnet) / (z - m_zMagnet); }
      __device__ inline auto get_new_qop(const float new_tx, const float scifi_tx, const float magnet_polarity)
      {
        return Physics::qop(new_tx, ty(), scifi_tx, magnet_polarity);
      }

      __device__ inline auto is_in_beampipe(const float z, const float tol)
      {
        const auto expected_x = xAtZ(z);
        const auto expected_y = yAtZ(z);

        return (fabsf(expected_x) < tol) && (fabsf(expected_y) < tol);
      }

      __device__ inline auto xTol(const unsigned layer)
      {
        const auto tol = Tolerance::X(layer, qop());
        return (tol.x > tol.z) ? tol.z : (tol.x < tol.y) ? tol.y : tol.x;
      }

      __device__ inline auto yTol(const unsigned layer)
      {
        const auto tol = Tolerance::Y(layer, qop());
        return (tol.x > tol.z) ? tol.z : (tol.x < tol.y) ? tol.y : tol.x;
      }

      __device__ inline auto xTolConst(const unsigned layer)
      {
        const auto tol = ConstantTolerance::X(layer);
        return tol;
      }

      __device__ inline auto yTolConst(const unsigned layer)
      {
        const auto tol = ConstantTolerance::Y(layer);
        return tol;
      }
    };

  } // namespace DownstreamExtrapolation

} // namespace Downstream

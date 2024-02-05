/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
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
      __device__ inline float dy(const float qop, const float ty, const float y)
      {
        return (-5.130062E-01f) + (1.409223E-01f) * y + (-1.470980E+03f) * ty + (-2.317281E+05f) * qop;
      }
      __device__ inline float dty(const float qop, const float ty, const float y)
      {
        return (-5.468134E-05f) + (6.705295E-05f) * y + (-6.321917E-01f) * ty + (-3.407640E+01f) * qop;
      }
      __device__ inline float dtx(const float qop, const float ty)
      {
        return (2.247261E-05f) + (-8.680666E-05f) * ty + (8.003155E+00f) * qop;
      }
    } // namespace Corrections

    namespace MagnetPoint {
      __device__ inline float
      zMagnet(const float scifi_x, const float scifi_y, const float scifi_tx, const float scifi_ty, const float qop)
      {
        return (5.367359E+03f) + (-2.660298E+03f) * scifi_ty * scifi_ty + (3.253875E+02f) * scifi_tx * scifi_tx +
               (-4.985715E+03f) * qop + (-2.634312E-02f) * abs(scifi_x) + (-6.648777E-02f) * abs(scifi_y) +
               (7.241572E+02f) * abs(scifi_ty) + (1.482586E+02f) * abs(scifi_tx);
      }
    } // namespace MagnetPoint

    namespace Physics {
      __device__ inline float qop(const float tx, const float ty, const float scifi_tx, const float magnet_polarity)
      {
        const auto momentumParam = 1217.77f + 454.598f * tx * tx + 3353.39f * ty * ty;
        return (tx - scifi_tx) / momentumParam * magnet_polarity;
      }
    } // namespace Physics

    namespace Tolerance {
      //
      // The tolerance function is fitted by requiring 98% efficiency, the max limit is calculated by requiring 99%
      // efficiency
      //
      __device__ __forceinline__ std::pair<float, float> X(const unsigned layer, const float qop)
      {
        switch (layer) {
        case 0: return {(4.932216E+03f) * fabsf(qop) + (4.622822E-01f), 1.92f};
        case 1: return {(4.229975E+07f) * qop * qop + (3.339328E+03f) * fabsf(qop) + (1.775429E+00f), 4.93f};
        case 2: return {(3.973958E+07f) * qop * qop + (1.400553E+03f) * fabsf(qop) + (1.760519E+00f), 4.25f};
        default: return {(2.011148E+05f) * fabsf(qop) + (2.836915E+00f), 57.71f};
        }
      }

      __device__ __forceinline__ std::pair<float, float> Y(const unsigned layer, const float qop)
      {
        switch (layer) {
        case 0: return {(2.926494E+04f) * fabsf(qop) + (5.932930E+00f), 23.72f};
        case 1: return {(2.384459E+04f) * fabsf(qop) + (6.367733E+00f), 22.86f};
        case 2: return {(3.128338E+04f) * fabsf(qop) + (4.971600E+00f), 21.44f};
        default: return {(2.575863E+04f) * fabsf(qop) + (5.166317E+00f), 21.28f};
        }
      }

    } // namespace Tolerance

    struct ExtrapolateTrack {
    private:
      float m_xMagnet;
      float m_yMagnet;
      float m_zMagnet;
      float m_tx;
      float m_ty;
      float m_qop;

    public:
      __device__ ExtrapolateTrack() = default;

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
      __device__ ExtrapolateTrack(const MiniState scifi_state, const float scifi_qop, const float magnet_polarity)
      {
        // Calculate Y extrapolation correction
        const float dty = Corrections::dty(scifi_qop, scifi_state.ty, scifi_state.y);
        const float dy = Corrections::dy(scifi_qop, scifi_state.ty, scifi_state.y);
        m_ty = scifi_state.ty + dty;

        // Calculate the extra correction for first hit
        const float dtx = Corrections::dtx(scifi_qop, m_ty);

        // Magent point
        m_zMagnet = MagnetPoint::zMagnet(scifi_state.x, scifi_state.y, scifi_state.tx, scifi_state.ty, scifi_qop);
        m_xMagnet = scifi_state.x + scifi_state.tx * (m_zMagnet - scifi_state.z);
        m_yMagnet = (scifi_state.y + dy) + m_ty * (m_zMagnet - scifi_state.z);

        // Slope
        m_tx = m_xMagnet / m_zMagnet;

        // Update momentum
        m_qop = Physics::qop(m_tx, m_ty, scifi_state.tx, magnet_polarity);

        // Apply the correction for first hit
        m_tx += dtx;
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
        const auto [val, max] = Tolerance::X(layer, qop());
        return (val > max) ? max : val;
      }

      __device__ inline auto yTol(const unsigned layer)
      {
        const auto [val, max] = Tolerance::Y(layer, qop());
        return (val > max) ? max : val;
      }
    };

  } // namespace DownstreamExtrapolation

} // namespace Downstream

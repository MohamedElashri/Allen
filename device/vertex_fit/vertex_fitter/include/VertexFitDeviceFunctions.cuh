/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "ParKalmanDefinitions.cuh"
#include "ParKalmanFittedTrack.cuh"
#include "ParKalmanMath.cuh"
#include "VertexDefinitions.cuh"
#include "ParticleTypes.cuh"
#include "PV_Definitions.cuh"
#include "MassDefinitions.h"

namespace VertexFit {

  __device__ inline bool poca(
    const Allen::Views::Physics::BasicParticle& trackA,
    const Allen::Views::Physics::BasicParticle& trackB,
    float& x,
    float& y,
    float& z);

  __device__ inline float doca(
    const Allen::Views::Physics::BasicParticle& trackA,
    const Allen::Views::Physics::BasicParticle& trackB);

  __device__ inline float ip(float x0, float y0, float z0, float x, float y, float z, float tx, float ty);

  __device__ inline float addToDerivatives(
    const Allen::Views::Physics::BasicParticle& track,
    const float& x,
    const float& y,
    const float& z,
    float& halfDChi2_0,
    float& halfDChi2_1,
    float& halfDChi2_2,
    float& halfD2Chi2_00,
    float& halfD2Chi2_11,
    float& halfD2Chi2_20,
    float& halfD2Chi2_21,
    float& halfD2Chi2_22);

  __device__ inline float solve(
    float& x,
    float& y,
    float& z,
    float& cov00,
    float& cov10,
    float& cov11,
    float& cov20,
    float& cov21,
    float& cov22,
    const float& halfDChi2_0,
    const float& halfDChi2_1,
    const float& halfDChi2_2,
    const float& halfD2Chi2_00,
    const float& halfD2Chi2_11,
    const float& halfD2Chi2_20,
    const float& halfD2Chi2_21,
    const float& halfD2Chi2_22);

  __device__ inline void doFit(
    const Allen::Views::Physics::BasicParticle& trackA,
    const Allen::Views::Physics::BasicParticle& trackB,
    TrackMVAVertex& vertex);

  __device__ inline void fill_extra_info(
    TrackMVAVertex& sv,
    const Allen::Views::Physics::BasicParticle& trackA,
    const Allen::Views::Physics::BasicParticle& trackB);

  __device__ inline int fill_extra_pv_info(
    TrackMVAVertex& sv,
    Allen::device::span<PV::Vertex const> pvs,
    const Allen::Views::Physics::BasicParticle& trackA,
    const Allen::Views::Physics::BasicParticle& trackB,
    const float max_assoc_ipchi2);

  //----------------------------------------------------------------------
  // Point of closest approach. Reimplementation from TrackVertexUtils.
  __device__ bool poca(
    const Allen::Views::Physics::BasicParticle& trackA,
    const Allen::Views::Physics::BasicParticle& trackB,
    float& x,
    float& y,
    float& z)
  {
    const Allen::Views::Physics::KalmanState stateA = trackA.state();
    const Allen::Views::Physics::KalmanState stateB = trackB.state();
    float zA = stateA.z();
    float xA = stateA.x();
    float yA = stateA.y();
    float txA = stateA.tx();
    float tyA = stateA.ty();
    float zB = stateB.z();
    float xB = stateB.x();
    float yB = stateB.y();
    float txB = stateB.tx();
    float tyB = stateB.ty();
    float secondAA = txA * txA + tyA * tyA + 1.0f;
    float secondBB = txB * txB + tyB * tyB + 1.0f;
    float secondAB = -txA * txB - tyA * tyB - 1.0f;
    float det = secondAA * secondBB - secondAB * secondAB;
    if (fabsf(det) > 0) {
      float secondinvAA = secondBB / det;
      float secondinvBB = secondAA / det;
      float secondinvAB = -secondAB / det;
      float firstA = txA * (xA - xB) + tyA * (yA - yB) + (zA - zB);
      float firstB = -txB * (xA - xB) - tyB * (yA - yB) - (zA - zB);
      float muA = -(secondinvAA * firstA + secondinvAB * firstB);
      float muB = -(secondinvBB * firstB + secondinvAB * firstA);
      x = 0.5f * (xA + muA * txA + xB + muB * txB);
      y = 0.5f * (yA + muA * tyA + yB + muB * tyB);
      // Because floating point addition is non-associative, the parentheses
      // below are needed to ensure that z does not depend on the order in which
      // tracks are passed to the function.
      z = 0.5f * ((zA + muA) + (zB + muB));
      return true;
    }
    return false;
  }

  __device__ float ip(float x0, float y0, float z0, float x, float y, float z, float tx, float ty)
  {
    float dz = z0 - z;
    float dx = x + dz * tx - x0;
    float dy = y + dz * ty - y0;
    return sqrtf((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
  }

  __device__ float doca(
    const Allen::Views::Physics::BasicParticle& trackA,
    const Allen::Views::Physics::BasicParticle& trackB)
  {
    const float xA = trackA.state().x();
    const float yA = trackA.state().y();
    const float zA = trackA.state().z();
    const float txA = trackA.state().tx();
    const float tyA = trackA.state().ty();
    const float xB = trackB.state().x();
    const float yB = trackB.state().y();
    const float zB = trackB.state().z();
    const float txB = trackB.state().tx();
    const float tyB = trackB.state().ty();
    const float secondAA = txA * txA + tyA * tyA + 1.f;
    const float secondBB = txB * txB + tyB * tyB + 1.f;
    const float secondAB = -txA * txB - tyA * tyB - 1.f;
    const float det = secondAA * secondBB - secondAB * secondAB;
    float ret = -1.f;
    if (fabsf(det) > 0) {
      const float secondinvAA = secondBB / det;
      const float secondinvBB = secondAA / det;
      const float secondinvAB = -secondAB / det;
      const float firstA = txA * (xA - xB) + tyA * (yA - yB) + (zA - zB);
      const float firstB = -txB * (xA - xB) - tyB * (yA - yB) - (zA - zB);
      const float muA = -(secondinvAA * firstA + secondinvAB * firstB);
      const float muB = -(secondinvBB * firstB + secondinvAB * firstA);
      const float dx = (xA + muA * txA) - (xB + muB * txB);
      const float dy = (yA + muA * tyA) - (yB + muB * tyB);
      const float dz = (zA + muA) - (zB + muB);
      ret = sqrtf(dx * dx + dy * dy + dz * dz);
    }
    return ret;
  }

  //----------------------------------------------------------------------
  // Add the contribution from one track to the vertex weight
  // matrix. NB this assumes (x, tx) and (y, ty) are uncorrelated.
  __device__ float addToDerivatives(
    const Allen::Views::Physics::BasicParticle& track,
    const float& x,
    const float& y,
    const float& z,
    float& halfDChi2_0,
    float& halfDChi2_1,
    float& halfDChi2_2,
    float& halfD2Chi2_00,
    float& halfD2Chi2_11,
    float& halfD2Chi2_20,
    float& halfD2Chi2_21,
    float& halfD2Chi2_22)
  {
    const Allen::Views::Physics::KalmanState state = track.state();
    float dz = z - state.z();
    float rX = state.x() + dz * state.tx() - x;
    float rY = state.y() + dz * state.ty() - y;
    float cov00 = state.c00() + dz * dz * state.c22() + 2.f * dz * state.c20();
    float cov11 = state.c11() + dz * dz * state.c33() + 2.f * dz * state.c31();
    float invcov00 = 1.f / cov00;
    float invcov11 = 1.f / cov11;
    halfDChi2_0 += invcov00 * rX;
    halfDChi2_1 += invcov11 * rY;
    halfDChi2_2 += -(invcov00 * rX * state.tx() + invcov11 * rY * state.ty());
    halfD2Chi2_00 += invcov00;
    halfD2Chi2_11 += invcov11;
    halfD2Chi2_20 += -invcov00 * state.tx();
    halfD2Chi2_21 += -invcov11 * state.ty();
    halfD2Chi2_22 += invcov00 * state.tx() * state.tx() + invcov11 * state.ty() * state.ty();
    return invcov00 * rX * rX + invcov11 * rY * rY;
  }

  //----------------------------------------------------------------------
  // Correct the POCA to find the vertex position.
  __device__ float solve(
    float& x,
    float& y,
    float& z,
    float& cov00,
    float& cov10,
    float& cov11,
    float& cov20,
    float& cov21,
    float& cov22,
    const float& halfDChi2_0,
    const float& halfDChi2_1,
    const float& halfDChi2_2,
    const float& halfD2Chi2_00,
    const float& halfD2Chi2_11,
    const float& halfD2Chi2_20,
    const float& halfD2Chi2_21,
    const float& halfD2Chi2_22)
  {
    const float det = halfD2Chi2_00 * halfD2Chi2_11 * halfD2Chi2_22 - halfD2Chi2_00 * halfD2Chi2_21 * halfD2Chi2_21 -
                      halfD2Chi2_11 * halfD2Chi2_20 * halfD2Chi2_20;
    const float invdet = 1.f / det;
    cov00 = (halfD2Chi2_11 * halfD2Chi2_22 - halfD2Chi2_21 * halfD2Chi2_21) * invdet;
    cov11 = (halfD2Chi2_00 * halfD2Chi2_22 - halfD2Chi2_20 * halfD2Chi2_20) * invdet;
    cov10 = halfD2Chi2_20 * halfD2Chi2_21 * invdet;
    cov20 = -halfD2Chi2_11 * halfD2Chi2_20 * invdet;
    cov21 = -halfD2Chi2_00 * halfD2Chi2_21 * invdet;
    cov22 = halfD2Chi2_00 * halfD2Chi2_11 * invdet;
    x += halfDChi2_0 * cov00 + halfDChi2_1 * cov10 + halfDChi2_2 * cov20;
    y += halfDChi2_0 * cov10 + halfDChi2_1 * cov11 + halfDChi2_2 * cov21;
    z += halfDChi2_0 * cov20 + halfDChi2_1 * cov21 + halfDChi2_2 * cov22;
    return -1 * (halfDChi2_0 * (halfDChi2_0 * cov00 + halfDChi2_1 * cov10 + halfDChi2_2 * cov20) +
                 halfDChi2_1 * (halfDChi2_0 * cov10 + halfDChi2_1 * cov11 + halfDChi2_2 * cov21) +
                 halfDChi2_2 * (halfDChi2_0 * cov20 + halfDChi2_1 * cov21 + halfDChi2_2 * cov22));
  }

  //----------------------------------------------------------------------
  // Perform a vertex fit assuming x and y are uncorrelated.
  __device__ void doFit(
    const Allen::Views::Physics::BasicParticle& trackA,
    const Allen::Views::Physics::BasicParticle& trackB,
    TrackMVAVertex& vertex)
  {
    float vertexweight00 = 0.f;
    float vertexweight11 = 0.f;
    float vertexweight20 = 0.f;
    float vertexweight21 = 0.f;
    float vertexweight22 = 0.f;
    float halfDChi2_0 = 0.f;
    float halfDChi2_1 = 0.f;
    float halfDChi2_2 = 0.f;
    /// Add DOCA
    const auto stateA = trackA.state();
    vertex.doca = 2.f * ip(vertex.x, vertex.y, vertex.z, stateA.x(), stateA.y(), stateA.z(), stateA.tx(), stateA.ty());
    vertex.chi2 = addToDerivatives(
      trackA,
      vertex.x,
      vertex.y,
      vertex.z,
      halfDChi2_0,
      halfDChi2_1,
      halfDChi2_2,
      vertexweight00,
      vertexweight11,
      vertexweight20,
      vertexweight21,
      vertexweight22);
    vertex.chi2 += addToDerivatives(
      trackB,
      vertex.x,
      vertex.y,
      vertex.z,
      halfDChi2_0,
      halfDChi2_1,
      halfDChi2_2,
      vertexweight00,
      vertexweight11,
      vertexweight20,
      vertexweight21,
      vertexweight22);
    vertex.chi2 += solve(
      vertex.x,
      vertex.y,
      vertex.z,
      vertex.cov00,
      vertex.cov10,
      vertex.cov11,
      vertex.cov20,
      vertex.cov21,
      vertex.cov22,
      halfDChi2_0,
      halfDChi2_1,
      halfDChi2_2,
      vertexweight00,
      vertexweight11,
      vertexweight20,
      vertexweight21,
      vertexweight22);
  }

  __device__ void fill_extra_info(
    TrackMVAVertex& sv,
    const Allen::Views::Physics::BasicParticle& trackA,
    const Allen::Views::Physics::BasicParticle& trackB)
  {
    // SV momentum.
    sv.px = trackA.px() + trackB.px();
    sv.py = trackA.py() + trackB.py();
    sv.pz = trackA.pz() + trackB.pz();

    // For calculating mass.
    sv.p1 = trackA.p();
    sv.p2 = trackB.p();
    sv.cos = (trackA.px() * trackB.px() + trackA.py() * trackB.py() + trackA.pz() * trackB.pz()) / (sv.p1 * sv.p2);

    // Sum of track pT.
    sv.sumpt = trackA.pt() + trackB.pt();

    // Minimum pt of constituent tracks.
    sv.minpt = trackA.pt() < trackB.pt() ? trackA.pt() : trackB.pt();

    // Muon ID.
    sv.is_dimuon = trackA.is_muon() && trackB.is_muon();
    sv.trk1_is_muon = trackA.is_muon();
    sv.trk2_is_muon = trackB.is_muon();

    // IP of constituent tracks

    sv.ip1 = trackA.ip();
    sv.ip2 = trackB.ip();

    // Minimum IP of constituent tracks.
    // sv.minip = trackA.ip() < trackB.ip() ? trackA.ip() : trackB.ip();

    // Dimuon mass.
    if (sv.is_dimuon) {
      const float mdimu2 = 2.f * Allen::mMu * Allen::mMu +
                           2.f * (sqrtf(
                                    (trackA.p() * trackA.p() + Allen::mMu * Allen::mMu) *
                                    (trackB.p() * trackB.p() + Allen::mMu * Allen::mMu)) -
                                  trackA.px() * trackB.px() - trackA.py() * trackB.py() - trackA.pz() * trackB.pz());
      sv.mdimu = sqrtf(mdimu2);
    }
    else {
      sv.mdimu = -1.f;
    }
  }

  __device__ int fill_extra_pv_info(
    TrackMVAVertex& sv,
    Allen::device::span<PV::Vertex const> pvs,
    const Allen::Views::Physics::BasicParticle& trackA,
    const Allen::Views::Physics::BasicParticle& trackB,
    const float max_assoc_ipchi2)
  {
    // Number of tracks with ip chi2 < 16.
    sv.ntrks16 = (trackA.ip_chi2() < max_assoc_ipchi2) + (trackB.ip_chi2() < max_assoc_ipchi2);

    const unsigned n_pvs = pvs.size();
    float minfdchi2 = -1.;
    int pv_idx = -1;

    for (unsigned ipv = 0; ipv < n_pvs; ipv++) {
      auto pv = pvs[ipv];

      // Get PV-SV separation.
      const float dx = sv.x - pv.position.x;
      const float dy = sv.y - pv.position.y;
      const float dz = sv.z - pv.position.z;

      // Get covariance and FD chi2.
      const float cov00 = sv.cov00 + pv.cov00;
      const float cov10 = sv.cov10 + pv.cov10;
      const float cov11 = sv.cov11 + pv.cov11;
      const float cov20 = sv.cov20 + pv.cov20;
      const float cov21 = sv.cov21 + pv.cov21;
      const float cov22 = sv.cov22 + pv.cov22;
      const float invdet = 1.f / (2.f * cov10 * cov20 * cov21 - cov11 * cov20 * cov20 - cov00 * cov21 * cov21 +
                                  cov00 * cov11 * cov22 - cov22 * cov10 * cov10);
      const float invcov00 = (cov11 * cov22 - cov21 * cov21) * invdet;
      const float invcov10 = (cov20 * cov21 - cov10 * cov22) * invdet;
      const float invcov11 = (cov00 * cov22 - cov20 * cov20) * invdet;
      const float invcov20 = (cov10 * cov21 - cov11 * cov20) * invdet;
      const float invcov21 = (cov10 * cov20 - cov00 * cov21) * invdet;
      const float invcov22 = (cov00 * cov11 - cov10 * cov10) * invdet;
      const float fdchi2 = invcov00 * dx * dx + invcov11 * dy * dy + invcov22 * dz * dz + 2.f * invcov20 * dx * dz +
                           2.f * invcov21 * dy * dz + 2.f * invcov10 * dx * dy;
      if (fdchi2 < minfdchi2 || pv_idx < 0) {
        minfdchi2 = fdchi2;
        pv_idx = ipv;
      }
    }

    if (pv_idx < 0) return -1;

    // Get PV-SV separation.
    sv.fdchi2 = minfdchi2;
    auto pv = pvs[pv_idx];
    const float dx = sv.x - pv.position.x;
    const float dy = sv.y - pv.position.y;
    const float dz = sv.z - pv.position.z;
    const float fd = sqrtf(dx * dx + dy * dy + dz * dz);

    // PV-SV eta.
    sv.eta = atanhf(dz / fd);
    // SVz - PVz
    sv.dz = dz;

    // SV IP
    sv.vertex_ip = ip(pv.position.x, pv.position.y, pv.position.z, sv.x, sv.y, sv.z, sv.px / sv.pz, sv.py / sv.pz);

    if (sv.is_dimuon) {
      const float txA = trackA.state().tx();
      const float tyA = trackA.state().ty();

      const float txB = trackB.state().tx();
      const float tyB = trackB.state().ty();

      const float vx = tyA - tyB;
      const float vy = -txA + txB;
      const float vz = txA * tyB - txB * tyA;
      sv.vertex_clone_sin2 =
        (vx * vx + vy * vy + vz * vz) / ((txA * txA + tyA * tyA + 1.f) * (txB * txB + tyB * tyB + 1.f));
    }
    else {
      sv.vertex_clone_sin2 = -1.f;
    }

    // Corrected mass.
    const float px = trackA.px() + trackB.px();
    const float py = trackA.py() + trackB.py();
    const float pz = trackA.pz() + trackB.pz();
    const float mvis2 =
      2.f * Allen::mPi * Allen::mPi +
      2.f *
        (sqrtf(
           (trackA.p() * trackA.p() + Allen::mPi * Allen::mPi) * (trackB.p() * trackB.p() + Allen::mPi * Allen::mPi)) -
         trackA.px() * trackB.px() - trackA.py() * trackB.py() - trackA.pz() * trackB.pz());
    const float pperp2 = ((py * dz - dy * pz) * (py * dz - dy * pz) + (pz * dx - dz * px) * (pz * dx - dz * px) +
                          (px * dy - dx * py) * (px * dy - dx * py)) /
                         fd / fd;
    sv.mcor = sqrtf(mvis2 + pperp2) + sqrtf(pperp2);

    // Minimum IP chi2 of constituent tracks.
    sv.minipchi2 = min(trackA.ip_chi2(), trackB.ip_chi2());
    sv.minip = min(trackA.ip(), trackB.ip());

    // cos DIRA.
    const float p = sqrtf(sv.px * sv.px + sv.py * sv.py + sv.pz * sv.pz);
    sv.dira = (sv.px * dx + sv.py * dy + sv.pz * dz) / (p * fd);

    return pv_idx;
  }

} // namespace VertexFit

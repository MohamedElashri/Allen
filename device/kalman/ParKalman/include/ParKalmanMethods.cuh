/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                            *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "KalmanParametrizations.cuh"
#include "ParKalmanDefinitions.cuh"
#include "ParKalmanFittedTrack.cuh"
#include "ParKalmanMath.cuh"
#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "BeamlinePVConstants.cuh"

namespace ParKalmanFilter {

  //----------------------------------------------------------------------
  // Fit information.
  struct trackInfo {

    // Pointer to the extrapolator that should be used.
    // Jacobians.
    Matrix5x5 m_RefPropForwardTotal;

    // Reference states.
    Vector<4> m_RefStateForwardV;

    KalmanFloat m_BestMomEst;

    KalmanFloat m_Lastz;

    KalmanFloat m_polarity;

    // Chi2s.
    KalmanFloat m_chi2T;
    KalmanFloat m_chi2V;
    KalmanFloat m_chi2UT;
  };

} // namespace ParKalmanFilter

using namespace ParKalmanFilter;

using Vector10 = Vector<10>;
using Vector2 = Vector<2>;
using SymMatrix2x2 = SquareMatrix<true, 2>;
using Matrix2x2 = SquareMatrix<false, 2>;

// Parameters for beamline propagation and VELO-only Kalman Filter.
static constexpr float rffoilscatter = 0.6;

static constexpr float scatterSensorParameter_VPHit2VPHit_cms = 1.48;
static constexpr float scatterSensorParameter_VPHit2VPHit_etaxx = 0.643;
static constexpr float scatterSensorParameter_VPHit2VPHit_etaxtx = 0.526;
static constexpr float scatterSensorParameter_VPHit2VPHit_Eloss = 0.592;

static constexpr float scatterSensorParameter_VPHit2ClosestToBeam_cms = 2.91;
static constexpr float scatterSensorParameter_VPHit2ClosestToBeam_etaxx = 0.808;
static constexpr float scatterSensorParameter_VPHit2ClosestToBeam_etaxtx = 0.793;
static constexpr float scatterSensorParameter_VPHit2ClosestToBeam_Eloss = 1.29;

////////////////////////////////////////////////////////////////////////
// Functions related to SciFi hits and their geometry
__device__ inline float SciFi_yMin(const Allen::Views::SciFi::Consolidated::Track& track, unsigned& hit_counter)
{
  // endPointY is the inner (small abs(y)) end of the fibre. For top that's what we want for
  // Bottom we need the subtract the length of the fibre.
  // Special case if the fibre is shorter because we are in the beam pipe region, which is easily checked based
  // on the value of the endPointY.
  // There is a clear seperation between fibre in the beam hole region and outside by the absolute value
  // of endPointY being smaller or larger than 50 mm, this also works for tilted mats.
  constexpr float min_beamhole_clearance = 50.f;
  float y_inner = track.hit(hit_counter).endPointY();
  bool isBeamHole = abs(y_inner) > min_beamhole_clearance;
  return y_inner - track.hit(hit_counter).isBottom() * (Approx_dy - isBeamHole * Approx_BeamHole_dy);
}

__device__ inline float SciFi_dy(const Allen::Views::SciFi::Consolidated::Track& track, unsigned& hit_counter)
{
  // return the fibre length, as defined in ParKalmanDefinitions.cuh under consideration of the beam pipe hole.
  // for more explanation see above.
  constexpr float min_beamhole_clearance = 50.f;
  float y_inner = track.hit(hit_counter).endPointY();
  bool isBeamHole = abs(y_inner) > min_beamhole_clearance;
  return Approx_dy - isBeamHole * Approx_BeamHole_dy;
}

////////////////////////////////////////////////////////////////////////
// Functions for doing the extrapolation.
__device__ inline void
ExtrapolateInV(const float* dev_pars, KalmanFloat zTo, Vector5& x, Matrix2x2& F, SymMatrix5x5& Q, trackInfo& tI)
{
  // step size in z
  KalmanFloat dz = zTo - tI.m_Lastz;
  if (dz == 0) return;
  // which set of parameters should be used
  unsigned index_offset = (dz > 0 ? 0 : 6);

  KalmanFloat par =
    (tI.m_polarity * dev_pars[index_offset + 2] * ((KalmanFloat) 1.0e-5) * dz *
     ((dz > 0 ? tI.m_Lastz : zTo) + dev_pars[index_offset + 3] * ((KalmanFloat) 1.0e3)));

  // parametrizations for state extrapolation
  x[0] += (x[2]) * ((KalmanFloat) 0.5) * dz;
  x[2] += x[4] * par;
  x[0] += (x[2]) * ((KalmanFloat) 0.5) * dz; // update on x is the average of tx before and after the update
  x[1] += x[3] * dz;

  // determine the Jacobian
  // NB: F is *not* the standard definition of f_ij = del f_i / del x_j
  // would be F(0,2), F(1,3)
  F(0, 0) = dz;
  F(0, 1) = dz;

  // would be F(2, 4)
  F(1, 0) = par;

  // would be F(0,4)
  F(1, 1) = ((KalmanFloat) 0.5) * dz * F(1, 0);

  // Set noise matrix
  KalmanFloat sigt = dev_pars[index_offset + 0] * ((KalmanFloat) 1.0e-5) + dev_pars[index_offset + 1] * fabsf(x[4]);

  // sigma x/y
  KalmanFloat sigx = dev_pars[index_offset + 4] * sigt * fabsf(dz);
  // Correlation between x/y and tx/ty
  KalmanFloat corr = dev_pars[index_offset + 5];

  Q(0, 0) = sigx * sigx;
  Q(1, 1) = sigx * sigx;
  Q(2, 2) = sigt * sigt;
  Q(3, 3) = sigt * sigt;

  Q(0, 2) = corr * sigx * sigt;
  Q(1, 3) = corr * sigx * sigt;
}

__device__ inline void
ExtrapolateVUT(const float* dev_pars, KalmanFloat zTo, Vector5& x, Matrix5x5& F, SymMatrix5x5& Q, trackInfo& tI)
{

  // cache the old state
  KalmanFloat tx_old = x[2];
  KalmanFloat ty_old = x[3];
  // step size in z
  KalmanFloat zFrom = tI.m_Lastz;
  KalmanFloat dz = zTo - zFrom;
  // which set of parameters should be used
  // extrapolate the current state and define noise

  // ty
  float par = tI.m_polarity * dev_pars[0];
  x[3] += par * std::copysign((KalmanFloat) 1.0, x[1]) * x[4] * tx_old;

  // calculate jacobian
  // ty
  F(3, 2) = par * x[4];
  F(3, 4) = par * tx_old;
  // y
  par = dev_pars[3];
  x[1] += (par * ty_old + (((KalmanFloat) 1.0) - par) * x[3]) * dz;
  KalmanFloat DyDty = (((KalmanFloat) 1.0) - par) * dz;
  F(1, 2) = DyDty * F(3, 2);
  F(1, 3) = dz;
  F(1, 4) = DyDty * F(3, 4);

  // tx
  par = tI.m_polarity * dev_pars[7];
  KalmanFloat coeff = tI.m_polarity * dev_pars[5] * ((KalmanFloat) 1e1) +
                      tI.m_polarity * dev_pars[6] * ((KalmanFloat) 1e-2) * zFrom +
                      par * ((KalmanFloat) 1e2) * ty_old * ty_old;

  KalmanFloat a = x[4] * coeff;
  KalmanFloat t = ((KalmanFloat) 1.0) + tx_old * tx_old + ty_old * ty_old;
  KalmanFloat b = a * a * t + ((KalmanFloat) 2.0) * a * tx_old * sqrtf(t);
  KalmanFloat c = b - ty_old * ty_old - ((KalmanFloat) 1.0);
  c = fabsf(c) < ((KalmanFloat) 1e-10) ? std::copysign((KalmanFloat) 1e-10, c) : c;
  KalmanFloat sqroot_term = -(x[3] * x[3] + ((KalmanFloat) 1.0)) * (b + tx_old * tx_old) * c;
  sqroot_term =
    sqroot_term > ((KalmanFloat) 0.0) ? sqroot_term : ((KalmanFloat) 0.0); // happens with very low |tx| tracks
  KalmanFloat sqroot = sqrtf(sqroot_term);

  x[2] += (tx_old * c + std::copysign((KalmanFloat) 1.0, tx_old) * sqroot) / c;

  KalmanFloat daDty = par * ((KalmanFloat) 2e2) * ty_old * x[4];
  KalmanFloat dadqop = coeff;

  KalmanFloat dtDtx = ((KalmanFloat) 2.) * tx_old;
  KalmanFloat dtDty = ((KalmanFloat) 2.) * ty_old;

  KalmanFloat dbDtx = ((KalmanFloat) 2.) * a;
  KalmanFloat dbda = ((KalmanFloat) 2.) * (a * t + tx_old);
  KalmanFloat dbdt = a * a + ((KalmanFloat) 0.5) / sqrtf(t);

  // KalmanFloat dcdb = 1;
  KalmanFloat dcDty = ((KalmanFloat) -2.) * ty_old;

  KalmanFloat dtxDtx = ((KalmanFloat) 1.0) + tx_old * tx_old * sqroot / (b + tx_old * tx_old) + sqroot;
  KalmanFloat dtxdb = tx_old * sqroot / (((KalmanFloat) 2.0) * (b + tx_old * tx_old));
  KalmanFloat dtxdc = tx_old * sqroot / (((KalmanFloat) 2.0) * c);
  KalmanFloat dtxdnty = x[3] * tx_old * sqroot / (x[3] * x[3] + 1);

  F(2, 2) = dtxDtx + dtxdb * (dbDtx + dbdt * dtDtx) + dtxdnty * F(3, 2);                                // DtxDtx
  F(2, 3) = dtxdb * dbda * (daDty + dbdt * dtDty) + dtxdc * (dbda * daDty + dcDty) + dtxdnty * F(3, 3); // DtxDy
  F(2, 4) = dtxdb * dbda * dadqop + dtxdc * dbda * dadqop + dtxdnty * F(3, 4);                          // DtxDqop

  par = dev_pars[12];
  // x
  KalmanFloat zmag = dev_pars[9] * ((KalmanFloat) 1e3) + dev_pars[10] * ((KalmanFloat) 1e-3) * zFrom +
                     dev_pars[11] * ((KalmanFloat) 1e-5) * zFrom * zFrom + par * ((KalmanFloat) 1e3) * ty_old * ty_old;

  x[0] += (zmag - zFrom) * tx_old + (zTo - zmag) * x[2];

  // x
  F(0, 2) = (zmag - zFrom) + (zTo - zmag) * F(2, 2);
  F(0, 3) = (zTo - zmag) * F(2, 3) + (tx_old - x[2]) * ((KalmanFloat) 2.0) * par * ((KalmanFloat) 1e3) * ty_old;
  F(0, 4) = (zTo - zmag) * F(2, 4);

  // add noise
  KalmanFloat tyErr = dev_pars[1] * fabsf(x[4]);
  KalmanFloat yErr = dev_pars[4] * fabsf(dz * x[4]);
  KalmanFloat txErr = dev_pars[8] * fabsf(x[4]);
  KalmanFloat xErr = dev_pars[13] * fabsf(dz * x[4]);

  Q(0, 0) = xErr * xErr;
  Q(0, 2) = dev_pars[2] * xErr * txErr;
  Q(1, 1) = yErr * yErr;
  Q(1, 3) = dev_pars[14] * yErr * tyErr;
  Q(2, 2) = txErr * txErr;
  Q(3, 3) = tyErr * tyErr;
}

__device__ inline void ExtrapolateInUT(
  const float* dev_pars,
  KalmanFloat zTo,
  Vector5& x,
  Matrix5x5& F,
  SymMatrix5x5& Q,
  trackInfo& tI,
  unsigned& layer)
{
  // cache the old state
  float old_y = x[1];
  float old_tx = x[2];
  float old_ty = x[3];
  // step size in z
  KalmanFloat dz = zTo - tI.m_Lastz;
  tI.m_Lastz = zTo;
  // which set of parameters should be used (0-3 are forward) (0 -> from 0 to 1)
  unsigned offset = (layer - 1) * 12;

  float par = dev_pars[offset + 6] * tI.m_polarity;
  float par1 = dev_pars[offset + 4] * tI.m_polarity;
  float par2 = dev_pars[offset + 5] * tI.m_polarity;

  x[2] += dz * (par1 * ((KalmanFloat) 1.e-1) * x[4] + par2 * ((KalmanFloat) 1.e3) * x[4] * x[4] * x[4] +
                par * ((KalmanFloat) 1e-7) * x[1] * x[1] * x[4]);
  F(2, 1) = ((KalmanFloat) 2.0) * dz * par * ((KalmanFloat) 1e-7) * old_y * x[4];
  F(2, 4) = dz * (par1 * ((KalmanFloat) 1.e-1) + ((KalmanFloat) 3.0) * par2 * ((KalmanFloat) 1.e3) * x[4] * x[4] +
                  par * ((KalmanFloat) 1e-7) * old_y * old_y);

  par1 = dev_pars[offset + 7] * tI.m_polarity;
  x[3] += par1 * x[4] * x[2] * std::copysign((KalmanFloat) 1.0, x[1]);

  par = dev_pars[offset + 2];
  x[1] += dz * (par * old_ty + (((KalmanFloat) 1.0) - par) * x[3]);

  par = dev_pars[offset + 0];
  x[0] += dz * (par * old_tx + (((KalmanFloat) 1.0) - par) * x[2]);
  F(0, 1) = dz * (((KalmanFloat) 1.0) - par) * F(2, 1);
  F(0, 2) = dz;
  F(0, 4) = dz * (((KalmanFloat) 1.0) - par) * F(2, 4);

  F(3, 2) = par1 * x[4] * std::copysign((KalmanFloat) 1.0, x[1]);
  F(3, 4) = par1 * x[2] * std::copysign((KalmanFloat) 1.0, x[1]);

  par = dev_pars[offset + 2];
  F(1, 2) = dz * (((KalmanFloat) 1.0) - par) * F(3, 2);
  F(1, 3) = dz;
  F(1, 4) = dz * (((KalmanFloat) 1.0) - par) * F(3, 4);

  // Define noise
  KalmanFloat xErr = dev_pars[offset + 1] * fabsf(dz * x[4]);
  KalmanFloat yErr = dev_pars[offset + 3] * fabsf(dz * x[4]);
  KalmanFloat txErr = dev_pars[offset + 8] * fabsf(x[4]);
  KalmanFloat tyErr = dev_pars[offset + 10] * fabsf(x[4]);

  // Add noise
  Q(0, 0) = xErr * xErr;
  Q(0, 2) = dev_pars[offset + 9] * xErr * txErr;
  Q(1, 1) = yErr * yErr;
  Q(1, 3) = dev_pars[offset + 11] * yErr * tyErr;
  Q(2, 2) = txErr * txErr;
  Q(3, 3) = tyErr * tyErr;
}

__device__ inline void extrapUTT(
  const KalmanParametrizations* kalman_params,
  const float* dev_UTT_META,
  KalmanFloat& x,
  KalmanFloat& y,
  KalmanFloat& tx,
  KalmanFloat& ty,
  KalmanFloat qOp,
  KalmanFloat* der_tx,
  KalmanFloat* der_ty,
  KalmanFloat* der_qop,
  trackInfo& tI)
{
  // Definitons of the dev_UTT_META indices
  // 00 ZINI
  // 01 ZFIN
  // 02 PMIN
  // 03 BENDX
  // 04 BENDX_X2
  // 05 BENDX_Y2
  // 06 BENDY_XY
  // 07 Txmax
  // 08 Tymax
  // 09 XFmax
  // 10 Dtxy
  // 11 Nbinx
  // 12 Nbiny
  // 13 XGridOption
  // 14 YGridOption
  // 15 DEGX1
  // 16 DEGX2
  // 17 DEGY1
  // 18 DEGY2
  // Xmax = ZINI * Txmax;
  // Ymax = ZINI * Tymax;

  KalmanFloat qop = qOp * tI.m_polarity;

  KalmanFloat xx(0), yy(0), dx, dy, ux, uy;
  int ix, iy;
  KalmanFloat zi = dev_UTT_META[0];
  KalmanFloat zf = dev_UTT_META[1];

  // XGridOption and YGridOption are just always 1.
  xx = x / (zi * dev_UTT_META[7]);
  yy = y / (zi * dev_UTT_META[8]);

  dx = dev_UTT_META[11] * (xx + ((KalmanFloat) 1.0)) / ((KalmanFloat) 2.0);
  ix = dx;
  dx -= ix;
  dy = dev_UTT_META[12] * (yy + ((KalmanFloat) 1.0)) / ((KalmanFloat) 2.0);
  iy = dy;
  dy -= iy;

  KalmanFloat DtxyInv = ((KalmanFloat) 1.0) / dev_UTT_META[10];
  KalmanFloat ziInv = ((KalmanFloat) 1.0) / zi;
  KalmanFloat bendx =
    dev_UTT_META[3] + dev_UTT_META[4] * (x * ziInv) * (x * ziInv) + dev_UTT_META[5] * (y * ziInv) * (y * ziInv);
  KalmanFloat bendy = dev_UTT_META[6] * (x * ziInv) * (y * ziInv);
  ux = (tx - x * ziInv - bendx * qop) * DtxyInv;
  uy = (ty - y * ziInv - bendy * qop) * DtxyInv;

  KalmanFloat gx, gy;
  gx = dx - ((KalmanFloat) 0.5);
  gy = dy - ((KalmanFloat) 0.5);
  if (ix <= 0) {
    ix = 1;
    gx -= (KalmanFloat) 1.;
  }
  if (ix >= dev_UTT_META[11] - 1) {
    ix = dev_UTT_META[11] - 2;
    gx += (KalmanFloat) 1.;
  }
  if (iy <= 0) {
    iy = 1;
    gy -= (KalmanFloat) 1.;
  }
  if (iy >= dev_UTT_META[12] - 1) {
    iy = dev_UTT_META[12] - 2;
    gy += (KalmanFloat) 1.;
  }

  int rx, ry, sx, sy;
  rx = (gx >= 0);
  sx = 2 * rx - 1;
  ry = (gy >= 0);
  sy = 2 * ry - 1;
  StandardCoefs c;
  StandardCoefs c_buff;

  setZero(c);
  c_buff = kalman_params->C[ix][iy];
  // aPEbxp := a += b * c
  aPEbxp(c, c_buff, ((KalmanFloat) 1) - (gx * gx + gy * gy) + sx * sy * gx * gy);
  c_buff = kalman_params->C[ix + 1][iy];
  aPEbxp(c, c_buff, (gx * gx + gx) * ((KalmanFloat) 0.5) - rx * sy * gx * gy);
  c_buff = kalman_params->C[ix][iy + 1];
  aPEbxp(c, c_buff, (gy * gy + gy) * ((KalmanFloat) 0.5) - ry * sx * gx * gy);
  c_buff = kalman_params->C[ix][iy - 1];
  aPEbxp(c, c_buff, (gy * gy - gy) * ((KalmanFloat) 0.5) + (!ry) * sx * gx * gy);
  c_buff = kalman_params->C[ix - 1][iy];
  aPEbxp(c, c_buff, (gx * gx - gx) * ((KalmanFloat) 0.5) + (!rx) * sy * gx * gy);
  c_buff = kalman_params->C[ix + sx][iy + sy];
  aPEbxp(c, c_buff, sx * sy * gx * gy);

  x = x + tx * (zf - zi);
  y = y + ty * (zf - zi);

  for (int k = 0; k < 4; k++)
    der_tx[k] = der_ty[k] = der_qop[k] = 0;
  // corrections to straight line -------------------------
  KalmanFloat fq = qop * dev_UTT_META[2];
  // x and tx ---------
  KalmanFloat ff = 1;
  KalmanFloat term1, term2;
  for (int deg = 0; deg < DEGx1; deg++) {
    term1 = c.x00(deg) + c.x10(deg) * ux + c.x01(deg) * uy;
    term2 = c.tx00(deg) + c.tx10(deg) * ux + c.tx01(deg) * uy;
    der_qop[0] += (deg + 1) * term1 * ff;
    der_qop[2] += (deg + 1) * term2 * ff;
    ff *= fq;
    x += term1 * ff;
    tx += term2 * ff;
    der_tx[0] += c.x10(deg) * ff;
    der_ty[0] += c.x01(deg) * ff;
    der_tx[2] += c.tx10(deg) * ff;
    der_ty[2] += c.tx01(deg) * ff;
  }

  for (int deg = DEGx1; deg < DEGx2; deg++) {
    der_qop[0] += (deg + 1) * c.x00(deg) * ff;
    der_qop[2] += (deg + 1) * c.tx00(deg) * ff;
    ff *= fq;
    x += c.x00(deg) * ff;
    tx += c.tx00(deg) * ff;
  }

  // y and ty ---------
  ff = 1;
  for (int deg = 0; deg < DEGy1; deg++) {
    term1 = c.y00(deg) + c.y10(deg) * ux + c.y01(deg) * uy;
    term2 = c.ty00(deg) + c.ty10(deg) * ux + c.ty01(deg) * uy;
    der_qop[1] += (deg + 1) * term1 * ff;
    der_qop[3] += (deg + 1) * term2 * ff;
    ff *= fq;
    y += term1 * ff;
    ty += term2 * ff;
    der_tx[1] += c.y10(deg) * ff;
    der_ty[1] += c.y01(deg) * ff;
    der_tx[3] += c.ty10(deg) * ff;
    der_ty[3] += c.ty01(deg) * ff;
  }
  for (int deg = DEGy1; deg < DEGy2; deg++) {
    der_qop[1] += (deg + 1) * c.y00(deg) * ff;
    der_qop[3] += (deg + 1) * c.ty00(deg) * ff;
    ff *= fq;
    y += c.y00(deg) * ff;
    ty += c.ty00(deg) * ff;
  }
  for (int k = 0; k < 4; k++) {
    der_qop[k] *= dev_UTT_META[2];
    der_tx[k] *= DtxyInv;
    der_ty[k] *= DtxyInv;
  }
  // from straight line
  der_tx[0] += zf - zi;
  der_ty[1] += zf - zi;
  der_tx[2] += 1;
  der_ty[3] += 1;

  der_qop[0] = tI.m_polarity * der_qop[0];
  der_qop[1] = tI.m_polarity * der_qop[1];
  der_qop[2] = tI.m_polarity * der_qop[2];
  der_qop[3] = tI.m_polarity * der_qop[3];
}

__device__ inline void ExtrapolateUTT(
  const float* dev_pars,
  const float* dev_UTT_META,
  const KalmanParametrizations* kalman_params,
  Vector5& x,
  Matrix5x5& F,
  SymMatrix5x5& Q,
  trackInfo& tI)
{
  // extrapolating from last UT layer (z=2642.5) to fixed z in T (z=7855)

  // determine the momentum at this state from the momentum saved in the state vector
  // (representing always the PV qop)
  float par = dev_pars[18];

  KalmanFloat qopHere =
    x[4] + x[4] * ((KalmanFloat) 1e-4) * par + x[4] * fabsf(x[4]) * dev_pars[19]; // TODO make this a tuneable parameter

  // buffers for the derivatives
  KalmanFloat der_tx[4];
  KalmanFloat der_ty[4];
  KalmanFloat der_qop[4];
  // do the actual extrapolation
  extrapUTT(kalman_params, dev_UTT_META, x[0], x[1], x[2], x[3], qopHere, der_tx, der_ty, der_qop, tI);

  F(0, 4) = der_qop[0];
  F(1, 4) = der_qop[1];
  F(2, 4) = der_qop[2];
  F(3, 4) = der_qop[3];

  // Set jacobian matrix
  // TODO study impact of der_x, der_y
  // ty
  F(3, 2) = der_tx[3];
  F(3, 3) = der_ty[3];

  // y
  F(1, 2) = der_tx[1];
  F(1, 3) = der_ty[1];

  // tx
  F(2, 2) = der_tx[2];
  F(2, 3) = der_ty[2];

  // x
  F(0, 2) = der_tx[0];
  F(0, 3) = der_ty[0];

  // sorted by par;
  F(3, 4) += ((KalmanFloat) 2.0) * fabsf(x[4]) * par;
  F(1, 4) += ((KalmanFloat) 2.0) * fabsf(x[4]) * par;
  F(2, 4) += ((KalmanFloat) 2.0) * fabsf(x[4]) * par;
  F(0, 4) += ((KalmanFloat) 2.0) * fabsf(x[4]) * par;

  par = dev_pars[0] * tI.m_polarity;
  F(3, 4) += par + ((KalmanFloat) 2.0) * dev_pars[1] * x[4] * ((KalmanFloat) 1e5) +
             ((KalmanFloat) 3.0) * dev_pars[2] * tI.m_polarity * x[4] * x[4] * ((KalmanFloat) 1e8);
  x[3] += par * x[4];

  par = dev_pars[3] * tI.m_polarity;
  F(1, 4) += par * ((KalmanFloat) 1e2) + ((KalmanFloat) 2.0) * dev_pars[4] * x[4] * ((KalmanFloat) 1e5) +
             ((KalmanFloat) 3.0) * dev_pars[5] * tI.m_polarity * x[4] * x[4] * ((KalmanFloat) 1e8);
  x[1] += par * x[4] * ((KalmanFloat) 1e2);

  par = dev_pars[6] * tI.m_polarity;
  F(2, 4) += par;
  x[2] += par * x[4];

  par = dev_pars[7] * x[4] * ((KalmanFloat) 1e5);
  F(2, 4) += ((KalmanFloat) 2.0) * par;
  x[2] += par * x[4];

  par = dev_pars[8] * tI.m_polarity * x[4] * x[4] * ((KalmanFloat) 1e8);
  F(2, 4) += ((KalmanFloat) 3.0) * par;
  x[2] += par * x[4];

  par = dev_pars[9] * tI.m_polarity * ((KalmanFloat) 1e2);
  F(0, 4) += par;
  x[0] += par * x[4];

  par = dev_pars[10] * x[4] * ((KalmanFloat) 1e5);
  F(0, 4) += ((KalmanFloat) 2.0) * par;
  x[0] += par * x[4];

  par = dev_pars[11] * tI.m_polarity * x[4] * x[4] * ((KalmanFloat) 1e10);
  F(0, 4) += ((KalmanFloat) 3.0) * par;
  x[0] += par * x[4];

  // Define noise
  KalmanFloat xErr = dev_pars[13] * ((KalmanFloat) 1e2) * fabsf(x[4]);
  KalmanFloat yErr = dev_pars[16] * ((KalmanFloat) 1e2) * fabsf(x[4]);
  KalmanFloat txErr = dev_pars[12] * fabsf(x[4]);
  KalmanFloat tyErr = dev_pars[15] * fabsf(x[4]);

  // Add noise
  Q(0, 0) = xErr * xErr;
  Q(0, 2) = dev_pars[14] * xErr * txErr;
  Q(1, 1) = yErr * yErr;
  Q(1, 3) = dev_pars[17] * yErr * tyErr;
  Q(2, 2) = txErr * txErr;
  Q(3, 3) = tyErr * tyErr;
}

__device__ inline void ExtrapolateInT(
  const float* dev_pars,
  KalmanFloat zTo,
  KalmanFloat DzDy,
  KalmanFloat DzDty,
  Vector5& x,
  Matrix5x5& F,
  SymMatrix5x5& Q,
  trackInfo& tI,
  unsigned& layer)
{
  // cache the old state
  float old_x1 = x[1];
  float old_x2 = x[2];
  float old_x3 = x[3];

  // step size in z
  KalmanFloat dz = zTo - tI.m_Lastz;
  // which set of parameters should be used
  // Reminder: forward offset definition
  //     0   2  4   6   8  10 12   14  16 18 20
  // y  |  |  |  |     |  |  |  |     |  |  |  |
  // ∧  |  |  |  |     |  |  |  |     |  |  |  |
  // |   1  3  5    7   9  11 13   15  17 19 21
  // --> z
  int offset = 2 * (layer - 1);
  if (x[1] < 0) offset += 1;
  offset *= 12;
  // predict state
  // tx
  x[2] += dz * tI.m_polarity * dev_pars[offset + 4] * ((KalmanFloat) 1.e-1) * x[4];
  x[2] += dz * tI.m_polarity * dev_pars[offset + 5] * ((KalmanFloat) 1.e3) * x[4] * x[4] * x[4];
  x[2] += dz * tI.m_polarity * dev_pars[offset + 6] * ((KalmanFloat) 1e-7) * x[1] * x[1] * x[4];

  // ty
  float par = dev_pars[offset + 7] * x[4];
  x[3] += par * x[4] * x[1];
  F(3, 4) = ((KalmanFloat) 2.0) * par;

  // y
  par = dev_pars[offset + 2];
  x[1] += dz * (par * old_x3 + (((KalmanFloat) 1.0) - par) * x[3]);
  F(1, 4) = dz * (((KalmanFloat) 1.0) - par) * F(3, 4);

  // calculate jacobian
  KalmanFloat dtxddz = tI.m_polarity * dev_pars[offset + 4] * ((KalmanFloat) 1.e-1) * x[4];
  dtxddz += tI.m_polarity * dev_pars[offset + 5] * ((KalmanFloat) 1.e3) * x[4] * x[4] * x[4];
  dtxddz += tI.m_polarity * dev_pars[offset + 6] * ((KalmanFloat) 1e-7) * x[1] * x[1] * x[4];

  F(2, 1) = ((KalmanFloat) 2.0) * dz * tI.m_polarity * dev_pars[offset + 6] * ((KalmanFloat) 1e-7) * old_x1 * x[4];
  F(2, 1) += dtxddz * DzDy;
  F(2, 3) = dtxddz * DzDty;
  F(2, 4) = dz * tI.m_polarity * dev_pars[offset + 4] * ((KalmanFloat) 1.e-1);
  F(2, 4) += dz * ((KalmanFloat) 3.0) * tI.m_polarity * dev_pars[offset + 5] * ((KalmanFloat) 1.e3) * x[4] * x[4];
  F(2, 4) += dz * tI.m_polarity * dev_pars[offset + 6] * ((KalmanFloat) 1e-7) * old_x1 * old_x1;

  // x
  par = dev_pars[offset + 0];
  x[0] += dz * (par * old_x2 + (((KalmanFloat) 1.0) - par) * x[2]);

  KalmanFloat dxddz = par * old_x2 + (((KalmanFloat) 1.0) - par) * x[2];
  F(0, 1) = dz * (((KalmanFloat) 1.0) - par) * F(2, 1) + dxddz * DzDy;
  F(0, 2) = dz;
  F(0, 3) = dz * (((KalmanFloat) 1.0) - par) * F(2, 3) + dxddz * DzDty;
  F(0, 4) = dz * (((KalmanFloat) 1.0) - par) * F(2, 4);

  F(1, 3) = dz;

  // Define noise
  KalmanFloat xErr = dev_pars[offset + 1] * fabsf(dz * x[4]);
  KalmanFloat yErr = dev_pars[offset + 3] * fabsf(dz * x[4]);
  KalmanFloat txErr = dev_pars[offset + 8] * fabsf(x[4]);
  KalmanFloat tyErr = dev_pars[offset + 10] * fabsf(x[4]);

  Q(0, 0) = xErr * xErr;
  Q(0, 2) = dev_pars[offset + 9] * xErr * txErr;
  Q(1, 1) = yErr * yErr;
  Q(1, 3) = dev_pars[offset + 11] * yErr * tyErr;
  Q(2, 2) = txErr * txErr;
  Q(3, 3) = tyErr * tyErr;

  tI.m_Lastz = zTo;
}
__device__ inline void ExtrapolateTFT(const float* dev_pars, KalmanFloat& zTo, Vector5& x, Matrix5x5& F, trackInfo& tI)
{
  // cache the old state
  float x_old_2 = x[2];
  // step size in z
  KalmanFloat dz = zTo - tI.m_Lastz;

  // do the extrapolation of the state vector
  // tx
  float par = dev_pars[1] * tI.m_polarity;

  x[2] += par * x[4] * dz;
  F(2, 4) = par * dz;

  par = dev_pars[2] * tI.m_polarity;
  x[2] += ((KalmanFloat) 1e4) * par * x[4] * dz * x[4] * dz * x[4] * dz;
  F(2, 4) += ((KalmanFloat) 3.0) * ((KalmanFloat) 1e4) * par * dz * dz * dz * x[4] * x[4];

  par = dev_pars[3];
  // x
  x[0] += ((((KalmanFloat) 1.0) - par) * x[2] + par * x_old_2) * dz;
  F(0, 4) = (((KalmanFloat) 1.0) - par) * dz * F(2, 4);

  // ty
  par = dev_pars[0];
  x[1] += (x[3]) * ((KalmanFloat) 0.5) * dz;

  x[3] += par * (x[4] * dz) * (x[4] * dz);
  // y
  x[1] += (x[3]) * ((KalmanFloat) 0.5) * dz;
  // qop

  // Jacobian
  F(0, 2) = dz;
  F(1, 3) = dz;
  // x

  // ty
  F(3, 4) = ((KalmanFloat) 2.0) * par * x[4] * dz * dz;
  // y
  F(1, 4) = ((KalmanFloat) 0.5) * dz * F(3, 4);

  // Set noise: none
  tI.m_Lastz = zTo;
}

__device__ inline void ExtrapolateTFTDef(
  const float* dev_UTT_META,
  const float* dev_pars,
  const float* dev_T_lay,
  Vector5& x,
  Matrix5x5& F,
  trackInfo& tI)
{
  KalmanFloat z0 = dev_UTT_META[1];
  KalmanFloat y0 = 0;
  KalmanFloat dydz = dev_T_lay[12];
  KalmanFloat zTo = (tI.m_Lastz * x[3] - z0 * dydz - x[1] + y0) / (x[3] - dydz);
  ExtrapolateTFT(dev_pars, zTo, x, F, tI);
}

////////////////////////////////////////////////////////////////////////
// Functions for updating and predicting states.
////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------
// Create a seed state at the first VELO hit.
__device__ inline void CreateVeloSeedState(
  const Allen::Views::Velo::Consolidated::Track& track,
  const int nVeloHits,
  Vector5& x,
  SymMatrix5x5& C,
  trackInfo& tI)
{
  // Set the state.
  x(0) = (KalmanFloat) track.hit(nVeloHits - 1).x();
  x(1) = (KalmanFloat) track.hit(nVeloHits - 1).y();
  x(2) = (KalmanFloat)(
    (track.hit(0).x() - track.hit(nVeloHits - 1).x()) / (track.hit(0).z() - track.hit(nVeloHits - 1).z()));
  x(3) = (KalmanFloat)(
    (track.hit(0).y() - track.hit(nVeloHits - 1).y()) / (track.hit(0).z() - track.hit(nVeloHits - 1).z()));
  tI.m_Lastz = (KalmanFloat) track.hit(nVeloHits - 1).z();

  // Set covariance matrix with large uncertainties and no correlations.
  C(0, 0) = (KalmanFloat) 100.0;
  C(0, 1) = (KalmanFloat) 0.0;
  C(0, 2) = (KalmanFloat) 0.0;
  C(0, 3) = (KalmanFloat) 0.0;
  C(0, 4) = (KalmanFloat) 0.0;
  C(1, 1) = (KalmanFloat) 100.0;
  C(1, 2) = (KalmanFloat) 0.0;
  C(1, 3) = (KalmanFloat) 0.0;
  C(1, 4) = (KalmanFloat) 0.0;
  C(2, 2) = (KalmanFloat) 0.01;
  C(2, 3) = (KalmanFloat) 0.0;
  C(2, 4) = (KalmanFloat) 0.0;
  C(3, 3) = (KalmanFloat) 0.01;
  C(3, 4) = (KalmanFloat) 0.0;
  C(4, 4) = ((KalmanFloat) 0.09) * x(4) * x(4);
}
//----------------------------------------------------------------------
// Predict in the VELO.
__device__ inline void PredictStateV(
  const Allen::Views::Velo::Consolidated::Track& track,
  const float* dev_pars,
  int nHit,
  Vector5& x,
  SymMatrix5x5& C,
  trackInfo& tI)
{

  // Transportation and noise.
  Matrix2x2 F;
  SymMatrix5x5 Q;
  Q.SetElements(Q_sym_zero);
  ExtrapolateInV(dev_pars, (KalmanFloat) track.hit(nHit).z(), x, F, Q, tI);

  // Transport the covariance matrix.
  C = similarity_5_5_VP(F, C);

  // Add noise.
  // C = C + Q;
  AeApB(C, Q);

  // Set current z position.
  // In Velo each layer has a hit, thus this update could be skiped and only change in UpdateStateV.
  tI.m_Lastz = (KalmanFloat) track.hit(nHit).z();
}

//----------------------------------------------------------------------
// Predict VELO <-> UT.
__device__ inline void PredictStateVUT(
  const Allen::Views::UT::Consolidated::Track& track,
  const float* dev_lays,
  const float* dev_pars,
  Vector5& x,
  SymMatrix5x5& C,
  trackInfo& tI,
  unsigned& hit_counter)
{
  // Predicted z position.
  KalmanFloat zTo = dev_lays[0];
  // Noise.
  SymMatrix5x5 Q;
  Q.SetElements(Q_sym_zero);
  // Jacobian.
  Matrix5x5 F;
  F.SetElements(F_diag);

  // Prediction.
  tI.m_RefStateForwardV[0] = x[0];
  tI.m_RefStateForwardV[1] = x[1];
  tI.m_RefStateForwardV[2] = x[2];
  tI.m_RefStateForwardV[3] = x[3];

  // Check if there is a hit in the first layer
  if (hit_counter != 0xf) {
    zTo = (KalmanFloat) track.hit(hit_counter).zAtYEq0();
  }

  ExtrapolateVUT(dev_pars, zTo, x, F, Q, tI);

  // Init transport matrix
  tI.m_RefPropForwardTotal = F;
  // Transport the covariance matrix
  C = similarity_5_5_VUT(F, C);

  // Add noise.
  // C = C + Q;
  AeApB(C, Q);

  // Set current z position.
  tI.m_Lastz = zTo;
}

//----------------------------------------------------------------------
// Predict UT <-> UT.
__device__ inline void PredictStateUT(
  const Allen::Views::UT::Consolidated::Track& track,
  const float* dev_lays,
  const float* dev_pars,
  Vector5& x,
  SymMatrix5x5& C,
  trackInfo& tI,
  unsigned& layer,
  unsigned& hit_counter)
{
  KalmanFloat zTo = dev_lays[layer];
  Matrix5x5 F;
  F.SetElements(F_diag);
  SymMatrix5x5 Q;
  Q.SetElements(Q_sym_zero);

  // Check if there's a hit in this layer and extrapolate to it.
  if (hit_counter != 0xf) {
    zTo = (KalmanFloat) track.hit(hit_counter).zAtYEq0();
  }

  ExtrapolateInUT(dev_pars, zTo, x, F, Q, tI, layer);
  tI.m_RefPropForwardTotal = F * tI.m_RefPropForwardTotal;
  C = similarity_5_5_UT(F, C);
  // C = C + Q;
  AeApB(C, Q);
  // tI.m_Lastz = zTo; // is set in the ExtrapolateInUT function
}

// Predict T(fixed z=7783) <-> first T layer.
__device__ inline void PredictStateTFT(
  const float* dev_UTT_META,
  const float* dev_pars,
  const float* dev_T_lay,
  Vector5& x,
  SymMatrix5x5& C,
  trackInfo& tI,
  Matrix5x5& F)
{
  ExtrapolateTFTDef(dev_UTT_META, dev_pars, dev_T_lay, x, F, tI);

  // Transport the covariance matrix.
  tI.m_RefPropForwardTotal = F * tI.m_RefPropForwardTotal;
  C = similarity_5_5_TFT(F, C);
  // lastz = z; Done in extrapolate
}
//----------------------------------------------------------------------
// Predict UT <-> T precise version(?)
__device__ inline void PredictStateUTT(
  const float* dev_pars,
  const float* dev_pars_TFT,
  const float* dev_pars_UTTF,
  const float* dev_UTT_META,
  const float* dev_T_lay,
  const KalmanParametrizations* kalman_params,
  Vector5& x,
  SymMatrix5x5& C,
  trackInfo& tI,
  unsigned& layer)
{
  // Extrapolate the state to the beginning of the UT->T Paramterisation.
  KalmanFloat zBegin = dev_UTT_META[0];
  Matrix5x5 F;
  F.SetElements(F_diag);
  SymMatrix5x5 Q;
  Q.SetElements(Q_sym_zero);

  // Extrapolate to the beginning of the UT -> T extrapolation
  ExtrapolateInUT(dev_pars, zBegin, x, F, Q, tI, layer);
  // Q is not physical, since the scattering would be double counted otherwise. -> Potential to save on the calculation
  // F is a physical transport that needs to be added to tI.m_RefPropForwardTotal
  tI.m_RefPropForwardTotal = F * tI.m_RefPropForwardTotal;
  C = similarity_5_5_UT(F, C);
  tI.m_Lastz = zBegin; // not really needed but good for understanding.

  // Calculate the extrapolation for a reference state that uses
  // the initial forward momentum estimate.
  F.SetElements(F_diag);
  Q.SetElements(Q_sym_zero);
  Vector5 xref = x;
  // Switch out for the best momentum measurement.
  xref[4] = tI.m_BestMomEst;
  Vector5 xtmp = xref;

  // Transportation and noise matrices.
  ExtrapolateUTT(dev_pars_UTTF, dev_UTT_META, kalman_params, xref, F, Q, tI);

  // Save reference state/jacobian after this intermediate extrapolation.
  x = xref + F * (x - xtmp); // TODO: This step could be optimized.
  tI.m_Lastz = dev_UTT_META[1];

  // Transport covariance matrix.
  tI.m_RefPropForwardTotal = F * tI.m_RefPropForwardTotal;
  C = similarity_5_5_UTT(F, C);
  // C = C + Q;
  AeApB(C, Q);

  F.SetElements(F_diag);

  // When going backwards: predict to the last VELO measurement.
  // Go from generic T position to the first T layer
  PredictStateTFT(dev_UTT_META, dev_pars_TFT, dev_T_lay, x, C, tI, F);
}

//----------------------------------------------------------------------
// Predict T <-> T.
__device__ inline void PredictStateT(
  const Allen::Views::SciFi::Consolidated::Track& track,
  const float* dev_lays,
  const float* dev_pars,
  Vector5& x,
  SymMatrix5x5& C,
  trackInfo& tI,
  unsigned& layer,
  unsigned& hit_counter)
{
  Matrix5x5 F;
  F.SetElements(F_diag);
  SymMatrix5x5 Q;
  Q.SetElements(Q_sym_zero);

  // set default values to variables
  KalmanFloat z0 = dev_lays[layer];
  KalmanFloat y0 = 0;
  KalmanFloat dydz = dev_lays[12 + layer];

  if (hit_counter != 0xf) {
    z0 = track.hit(hit_counter).z0();
    y0 = SciFi_yMin(track, hit_counter);
    // dydz = ((KalmanFloat) 1.) / SciFi::Constants::dzdy; // currently there's no difference
  }

  KalmanFloat zTo = (tI.m_Lastz * x[3] - z0 * dydz - x[1] + y0) / (x[3] - dydz);
  KalmanFloat DzDy = ((KalmanFloat) -1.0) / (x[3] - dydz);
  KalmanFloat DzDty = tI.m_Lastz * (-DzDy) - (tI.m_Lastz * x[3] - z0 * dydz - x[1] + y0) * DzDy * DzDy;

  ExtrapolateInT(dev_pars, zTo, DzDy, DzDty, x, F, Q, tI, layer);

  // Transport matrix
  tI.m_RefPropForwardTotal = F * tI.m_RefPropForwardTotal;
  C = similarity_5_5_T(F, C);
  // C = C + Q;
  AeApB(C, Q);
  // tI.m_Lastz = zTo; Done in extrapolate
}

//----------------------------------------------------------------------
// Update state with velo measurement.
__device__ inline void UpdateStateV(
  const Allen::Views::Velo::Consolidated::Track& track,
  int forward,
  int nHit,
  Vector5& x,
  SymMatrix5x5& C,
  trackInfo& tI)
{
  // Get residual.
  // Vector2 res({hits.x(nHit)-x(0), hits.y(nHit)-x(1)});
  Vector2 res;
  res(0) = (KalmanFloat) track.hit(nHit).x() - x(0);
  res(1) = (KalmanFloat) track.hit(nHit).y() - x(1);
  KalmanFloat xErr = 0.0125f;
  KalmanFloat yErr = 0.0125f;
  KalmanFloat CResTmp[3] = {xErr * xErr + C(0, 0), C(0, 1), yErr * yErr + C(1, 1)};
  SymMatrix2x2 CRes(CResTmp);

  // Kalman formalism.
  SymMatrix2x2 CResInv; // = inverse(CRes);
  KalmanFloat Dinv = ((KalmanFloat) 1.) / (CRes(0, 0) * CRes(1, 1) - CRes(1, 0) * CRes(1, 0));
  CResInv(0, 0) = CRes(1, 1) * Dinv;
  CResInv(1, 0) = -CRes(1, 0) * Dinv;
  CResInv(1, 1) = CRes(0, 0) * Dinv;

  Vector10 K;
  multiply_S5x5_S2x2(C, CResInv, K);
  x = x + K * res;
  SymMatrix5x5 KCrKt;
  similarity_5x2_2x2(K, CRes, KCrKt);

  // C = C - KCrKt;
  AeAmB(C, KCrKt);

  // Update the chi2.
  KalmanFloat chi2Tmp = similarity_2x1_2x2(res, CResInv);
  if (forward > 0) {
    tI.m_chi2V += chi2Tmp;
  }
}

//----------------------------------------------------------------------
// Update state with UT measurement.
__device__ inline void UpdateStateUT(
  const Allen::Views::UT::Consolidated::Track& track,
  Vector5& x,
  SymMatrix5x5& C,
  trackInfo& tI,
  unsigned& nHit)
{

  // Get the hit information.
  // const KalmanFloat slopes[4] = {0.0, +0.087155742747, -0.087155742747, 0.0}; -> Now from geometry
  // TODO: Get slopes from simplified geometry.
  const KalmanFloat dxDy = (KalmanFloat) track.hit(nHit).dxDy();
  const KalmanFloat y0 = (KalmanFloat) track.hit(nHit).yBegin();
  const KalmanFloat y1 = (KalmanFloat) track.hit(nHit).yEnd();
  const KalmanFloat x0 = (KalmanFloat) track.hit(nHit).xAtYEq0() + y0 * dxDy;
  const KalmanFloat x1 = (KalmanFloat) track.hit(nHit).xAtYEq0() + y1 * dxDy;

  // Rotate by alpha = atan(dx/dy).
  const KalmanFloat x2y2 = sqrtf((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
  Vector2 H;
  H(0) = (y1 - y0) / x2y2;
  H(1) = -(x1 - x0) / x2y2;

  // Get the residual.
  const KalmanFloat res = H(0) * x0 + H(1) * y0 - (H(0) * x[0] + H(1) * x[1]);
  KalmanFloat CRes;
  similarity_1x2_S5x5_2x1(H, C, CRes);
  KalmanFloat err2 = ((KalmanFloat) 1.) / (KalmanFloat) track.hit(nHit).weight();
  CRes += err2;

  // K = P*H
  Vector5 K;
  multiply_S5x5_2x1(C, H, K);

  // K*S^-1
  K = K / CRes;
  x = x + res * K;

  // K*S*K(T)
  SymMatrix5x5 KCResKt;
  tensorProduct(sqrtf(CRes) * K, sqrtf(CRes) * K, KCResKt);

  // P -= KSK(T)
  // C = C - KCResKt;
  AeAmB(C, KCResKt);

  // Update chi2.
  tI.m_chi2UT += res * res / CRes;

  // Update z. Already be done in the prediction step
  // tI.m_Lastz = (KalmanFloat) track.hit(nHit).zAtYEq0();
}

//----------------------------------------------------------------------
// Update state with T measurement.
__device__ inline void UpdateStateT(
  const Allen::Views::SciFi::Consolidated::Track& track,
  const float* dev_lays,
  Vector5& x,
  SymMatrix5x5& C,
  trackInfo& tI,
  unsigned& nHit,
  unsigned& layer)
{
  const KalmanFloat dxdy = dev_lays[24 + layer]; // TODO: Get slopes from simplified geometry.
  const KalmanFloat dzdy = SciFi::Constants::dzdy;
  const KalmanFloat y0 = (KalmanFloat) SciFi_yMin(track, nHit);
  const KalmanFloat dy = (KalmanFloat) SciFi_dy(track, nHit);
  const KalmanFloat x0 = (KalmanFloat) track.hit(nHit).x0() + y0 * dxdy;
  const KalmanFloat x1 = x0 + dy * dxdy;
  const KalmanFloat z0 = (KalmanFloat) track.hit(nHit).z0();
  const KalmanFloat x2y2 = sqrtf((x1 - x0) * (x1 - x0) + dy * dy);
  Vector2 H;
  H(0) = dy / x2y2;
  H(1) = -(x1 - x0) / x2y2;

  // Residual.
  // Take the beginning point of trajectory and rotate.
  const KalmanFloat res = H(0) * x0 + H(1) * y0 - (H(0) * x[0] + H(1) * x[1]);
  KalmanFloat CRes;
  similarity_1x2_S5x5_2x1(H, C, CRes);
  // TODO: This needs a better parametrization as a function of
  // cluster size (if we actually do clustering).
  KalmanFloat err2 = dev_lays[36 + track.hit(nHit).pseudoSize()]; // TODO: Get slopes from simplified geometry.
  CRes += err2;

  // K = P*H
  Vector5 K;
  multiply_S5x5_2x1(C, H, K);

  // K = K/CRes;
  K = K / CRes;
  x = x + res * K;

  // K*S*K(T)
  SymMatrix5x5 KCResKt;
  tensorProduct(sqrtf(CRes) * K, sqrtf(CRes) * K, KCResKt);

  // P -= KSK
  // C = C - KCResKt;
  AeAmB(C, KCResKt);

  // Update the chi2.
  tI.m_chi2T += res * res / CRes;

  // Update z. -> Should be a really minimal update, since x[1] is updated and dzdy != 0.
  tI.m_Lastz = z0 + dzdy * (x[1] - y0);
}

//----------------------------------------------------------------------
// Extrapolate to the vertex using straight line extrapolation.
__device__ inline void ExtrapolateToVertex(Vector5& x, SymMatrix5x5& C, KalmanFloat& lastz);

__device__ inline void add_noise_2d(
  const KalmanFloat dz,
  const KalmanFloat tx,
  const KalmanFloat ty,
  KalmanFloat& qop,
  SymMatrix5x5& Q,
  const KalmanFloat Cms,
  const KalmanFloat etaxx,
  const KalmanFloat etaxtx,
  const KalmanFloat Eloss,
  const bool infoil)
{

  // Adds full noise.
  // Scattering paramters are defined in the include/ParKalmanVeloOnly.cuh as
  // scatterSensorParameter_VPHit2VPHit_{cms,etaxx, etaxtx, Eloss}
  // Values are taken from the Rec/Tr/TrackFitEvent/include/Event/ParametrisedScatters.h
  // fine tuned on 10k events of upgrade-magdown-sim10-up08-30000000-digi from TestFileDB
  // as of 14.12.21

  const KalmanFloat tx2 = tx * tx;
  const KalmanFloat ty2 = ty * ty;
  const KalmanFloat n2 = 1 + tx2 + ty2;
  const KalmanFloat n = sqrtf(n2);
  const KalmanFloat invp = fabsf(qop);
  const KalmanFloat norm = n2 * invp * invp * n;

  KalmanFloat normCms = norm * Cms;
  normCms += infoil ? (norm * rffoilscatter) : 0;

  Q(2, 2) = (1 + tx2) * normCms;
  Q(3, 3) = (1 + ty2) * normCms;
  Q(3, 2) = tx * ty * normCms;

  // x, tx part
  Q(0, 0) = Q(2, 2) * dz * dz * etaxx * etaxx;
  Q(2, 0) = Q(2, 2) * dz * etaxtx;
  // y, ty part
  Q(1, 1) = Q(3, 3) * dz * dz * etaxx * etaxx;
  Q(3, 1) = Q(3, 3) * dz * etaxtx;

  Q(1, 0) = Q(3, 2) * dz * dz * etaxx * etaxx;
  Q(3, 0) = Q(3, 2) * dz * etaxtx;
  Q(2, 1) = Q(3, 0);

  const KalmanFloat deltaE = ((dz) < 0 ? 1 : -1) * Eloss * n;
  const KalmanFloat charge = (qop > 0) ? 1. : -1.;
  const KalmanFloat momnew =
    (fabsf(qop) > 1e-20f && 10.f < (fabsf(1.f / qop) + deltaE)) ? fabsf(1.f / qop) + deltaE : 10.f;
  qop = (fabsf(momnew) > 10.f && fabsf(qop) > 1e-20f) ? (charge / momnew) : qop;
}

__device__ inline void add_noise_1d(
  const KalmanFloat dz,
  const KalmanFloat tx,
  KalmanFloat& qop,
  KalmanFloat& predcovXX,
  KalmanFloat& predcovXTx,
  KalmanFloat& predcovTxTx,
  const KalmanFloat Cms,
  const KalmanFloat etaxx,
  const KalmanFloat etaxtx,
  const KalmanFloat Eloss,
  const bool infoil)
{
  // Adds full noise.
  // Scattering paramters are defined in the include/ParKalmanVeloOnly.cuh as
  // scatterSensorParameter_VPHit2VPHit_{cms,etaxx, etaxtx, Eloss}
  // Values are taken from the Rec/Tr/TrackFitEvent/include/Event/ParametrisedScatters.h
  // fine tuned on 10k events of upgrade-magdown-sim10-up08-30000000-digi from TestFileDB
  // as of 14.12.21

  const KalmanFloat tx2 = tx * tx;
  const KalmanFloat n2 = 1 + tx2;
  const KalmanFloat n = sqrtf(n2);
  const KalmanFloat invp = fabsf(qop);
  const KalmanFloat norm = n2 * invp * invp * n;

  KalmanFloat normCms = norm * Cms;
  normCms += infoil ? norm * rffoilscatter : 0;

  const KalmanFloat sig = (1 + tx2) * normCms;
  // x, tx part
  predcovXX += sig * dz * dz * etaxx * etaxx;
  predcovXTx += sig * dz * etaxtx;
  predcovTxTx += sig;

  const KalmanFloat deltaE = ((dz) < 0 ? 1 : -1) * Eloss * n;
  const KalmanFloat charge = qop > 0 ? 1. : -1.;
  const KalmanFloat momnew =
    (fabsf(qop) > 1e-20f && 10.f < (fabsf(1.f / qop) + deltaE)) ? fabsf(1.f / qop) + deltaE : 10.f;
  qop = (fabsf(momnew) > 10.f && fabsf(qop) > 1e-20f) ? (charge / momnew) : qop;
}

__device__ inline void propagate_to_beamline(
  FittedTrack& track,
  const BeamlinePVConstants::Common::Beamline dev_beamline,
  const bool add_eloss = true)
{
  float tx_beam;
  float ty_beam;
  if (track.z > BeamlinePVConstants::Common::SMOG2_pp_separation) {
    tx_beam = dev_beamline.tx.x;
    ty_beam = dev_beamline.tx.y;
  }
  else {
    tx_beam = dev_beamline.tx_SMOG.x;
    ty_beam = dev_beamline.tx_SMOG.y;
  }
  KalmanFloat x = track.state[0];
  KalmanFloat y = track.state[1];
  KalmanFloat tx = track.state[2] - tx_beam;
  KalmanFloat ty = track.state[3] - ty_beam;
  const KalmanFloat t2 = sqrtf(tx * tx + ty * ty);

  // Get the beam position.
  KalmanFloat zBeam = track.z;
  KalmanFloat denom = t2 * t2;
  const KalmanFloat tol = (KalmanFloat) 0.001;
  zBeam =
    (denom < tol * tol) ?
      zBeam :
      track.z +
        ((dev_beamline.pos.x + tx_beam * track.z - x) * tx + (dev_beamline.pos.y + ty_beam * track.z - y) * ty) / denom;
  const KalmanFloat dz = zBeam - track.z;
  KalmanFloat qop = track.state[4];
  // Propagate the covariance matrix.
  const KalmanFloat dz2 = dz * dz;
  track.cov(0, 0) += dz2 * track.cov(2, 2) + 2 * dz * track.cov(0, 2);
  track.cov(0, 2) += dz * track.cov(2, 2);
  track.cov(1, 1) += dz2 * track.cov(3, 3) + 2 * dz * track.cov(1, 3);
  track.cov(1, 3) += dz * track.cov(3, 3);

  // Propagate the state.
  track.state[0] = x + dz * tx;
  track.state[1] = y + dz * ty;
  track.z = zBeam;

  //
  x = track.state[0];
  y = track.state[1];
  tx = track.state[2];
  ty = track.state[3];

  SymMatrix5x5 Q;
  // add noise
  // Note: for VPhit2BeamLine propagation the rf-foil is included in the parameters,
  // so infoil has to be set to false.
  add_noise_2d(
    dz,
    tx,
    ty,
    qop,
    Q,
    scatterSensorParameter_VPHit2ClosestToBeam_cms,
    scatterSensorParameter_VPHit2ClosestToBeam_etaxx,
    scatterSensorParameter_VPHit2ClosestToBeam_etaxtx,
    scatterSensorParameter_VPHit2ClosestToBeam_Eloss,
    false);

  // Optionally update momentum.
  if (add_eloss) {
    track.state[4] = qop;
  }

  track.cov(0, 0) += Q(0, 0);
  track.cov(1, 1) += Q(1, 1);
  track.cov(2, 2) += Q(2, 2);
  track.cov(3, 3) += Q(3, 3);

  track.cov(1, 0) += Q(1, 0);

  track.cov(2, 0) += Q(2, 0);
  track.cov(2, 1) += Q(2, 1);

  track.cov(3, 0) += Q(3, 0);
  track.cov(3, 1) += Q(3, 1);
  track.cov(3, 2) += Q(3, 2);
}

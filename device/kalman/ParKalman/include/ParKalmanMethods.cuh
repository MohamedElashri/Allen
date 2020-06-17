#pragma once

#include "KalmanParametrizations.cuh"
#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"

namespace ParKalmanFilter {

  //----------------------------------------------------------------------
  // Fit information.
  struct trackInfo {

    // Pointer to the extrapolator that should be used.
    // const KalmanParametrizations *m_extr;
    const KalmanParametrizations* m_extr;

    // Jacobians.
    Matrix5x5 m_RefPropForwardTotal;

    // Reference states.
    Vector5 m_RefStateForwardV;

    KalmanFloat m_BestMomEst;
    KalmanFloat m_FirstMomEst;

    // Chi2s.
    KalmanFloat m_chi2;
    KalmanFloat m_chi2T;
    KalmanFloat m_chi2V;

    int m_SciFiLayerIdxs[12];
    int m_UTLayerIdxs[4];

    // NDoFs.
    unsigned m_ndof;
    unsigned m_ndofT;
    unsigned m_ndofUT;
    unsigned m_ndofV;

    // Number of hits.
    unsigned m_NHits;
    unsigned m_NHitsV;
    unsigned m_NHitsUT;
    unsigned m_NHitsT;

    // Keep track of the previous UT and T layers.
    unsigned m_PrevUTLayer;
    unsigned m_PrevSciFiLayer;

    __device__ __host__ trackInfo()
    {
      for (int i_ut = 0; i_ut < 4; i_ut++)
        m_UTLayerIdxs[i_ut] = -1;
      for (int i_scifi = 0; i_scifi < 12; i_scifi++)
        m_SciFiLayerIdxs[i_scifi] = -1;
    }
  };
} // namespace ParKalmanFilter

using namespace ParKalmanFilter;

////////////////////////////////////////////////////////////////////////
// Functions for doing the extrapolation.
__device__ inline void
ExtrapolateInV(KalmanFloat zFrom, KalmanFloat zTo, Vector5& x, Matrix5x5& F, SymMatrix5x5& Q, trackInfo& tI);

__device__ inline bool
ExtrapolateVUT(KalmanFloat zFrom, KalmanFloat zTo, Vector5& x, Matrix5x5& F, SymMatrix5x5& Q, trackInfo& tI);

__device__ inline void GetNoiseVUTBackw(KalmanFloat zFrom, KalmanFloat zTo, Vector5& x, SymMatrix5x5& Q, trackInfo& tI);

__device__ inline void ExtrapolateInUT(
  KalmanFloat zFrom,
  unsigned nLayer,
  KalmanFloat zTo,
  Vector5& x,
  Matrix5x5& F,
  SymMatrix5x5& Q,
  trackInfo& tI);

__device__ inline void ExtrapolateUTFUTDef(KalmanFloat& zFrom, Vector5& x, Matrix5x5& F, trackInfo& tI);

__device__ inline void ExtrapolateUTFUT(KalmanFloat zFrom, KalmanFloat zTo, Vector5& x, Matrix5x5& F, trackInfo& tI);

__device__ inline void ExtrapolateUTT(Vector5& x, Matrix5x5& F, SymMatrix5x5& Q, trackInfo& tI);

__device__ inline void GetNoiseUTTBackw(const Vector5& x, SymMatrix5x5& Q, trackInfo& tI);

__device__ inline void ExtrapolateInT(
  KalmanFloat zFrom,
  unsigned nLayer,
  KalmanFloat& zTo,
  Vector5& x,
  Matrix5x5& F,
  SymMatrix5x5& Q,
  trackInfo& tI);

__device__ inline void ExtrapolateInT(
  KalmanFloat zFrom,
  unsigned nLayer,
  KalmanFloat zTo,
  KalmanFloat DzDy,
  KalmanFloat DzDty,
  Vector5& x,
  Matrix5x5& F,
  SymMatrix5x5& Q,
  trackInfo& tI);

__device__ inline void
ExtrapolateTFT(KalmanFloat zFrom, KalmanFloat& zTo, Vector5& x, Matrix5x5& F, SymMatrix5x5& Q, trackInfo& tI);

__device__ inline void
ExtrapolateTFTDef(KalmanFloat zFrom, KalmanFloat& zTo, Vector5& x, Matrix5x5& F, SymMatrix5x5& Q, trackInfo& tI);

__device__ inline int extrapUTT(
  KalmanFloat zi,
  KalmanFloat zf,
  KalmanFloat& x,
  KalmanFloat& y,
  KalmanFloat& tx,
  KalmanFloat& ty,
  KalmanFloat qop,
  KalmanFloat* der_tx,
  KalmanFloat* der_ty,
  KalmanFloat* der_qop,
  trackInfo& tI);

////////////////////////////////////////////////////////////////////////
// Functions for updating and predicting states.
////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------
// Create a seed state at the first VELO hit.
__device__ inline void CreateVeloSeedState(
  Velo::Consolidated::ConstHits& hits,
  const int nVeloHits,
  int nHit,
  Vector5& x,
  SymMatrix5x5& C,
  KalmanFloat& lastz,
  trackInfo& tI);

//----------------------------------------------------------------------
// Predict in the VELO.
__device__ inline void PredictStateV(
  Velo::Consolidated::ConstHits& hits,
  int nHit,
  Vector5& x,
  SymMatrix5x5& C,
  KalmanFloat& lastz,
  trackInfo& tI);

//----------------------------------------------------------------------
// Predict VELO <-> UT.
__device__ inline bool
PredictStateVUT(UT::Consolidated::ConstHits& hitsUT, Vector5& x, SymMatrix5x5& C, KalmanFloat& lastz, trackInfo& tI);

//----------------------------------------------------------------------
// Predict UT <-> UT.
__device__ inline void PredictStateUT(
  UT::Consolidated::ConstHits& hits,
  const unsigned layer,
  Vector5& x,
  SymMatrix5x5& C,
  KalmanFloat& lastz,
  trackInfo& tI);

//----------------------------------------------------------------------
// Predict last UT layer <-> start of UTTF.
__device__ inline void PredictStateUTFUT(Vector5& x, SymMatrix5x5& C, KalmanFloat& lastz, trackInfo& tI);

//----------------------------------------------------------------------
// Predict UT <-> T precise version(?)
__device__ inline void PredictStateUTT(Vector5& x, SymMatrix5x5& C, KalmanFloat& lastz, trackInfo& tI);

//----------------------------------------------------------------------
// Predict T <-> T.
__device__ inline void PredictStateT(
  SciFi::Consolidated::ConstExtendedHits& hits,
  unsigned layer,
  Vector5& x,
  SymMatrix5x5& C,
  KalmanFloat& lastz,
  trackInfo& tI);

//----------------------------------------------------------------------
// Predict T(fixed z=7783) <-> first T layer.
__device__ inline void
PredictStateTFT(SciFi::Consolidated::ConstExtendedHits& hits, Vector5& x, SymMatrix5x5& C, KalmanFloat& lastz, trackInfo& tI);

//----------------------------------------------------------------------
// Predict T(fixed z=7783) <-> first T layer.
__device__ inline void PredictStateTFT(Vector5& x, SymMatrix5x5& C, KalmanFloat& lastz, trackInfo& tI);

//----------------------------------------------------------------------
// Update state with velo measurement.
__device__ inline void
UpdateStateV(Velo::Consolidated::ConstHits& hits, int forward, int nHit, Vector5& x, SymMatrix5x5& C, trackInfo& tI);

//----------------------------------------------------------------------
// Update state with UT measurement.
__device__ inline void UpdateStateUT(
  UT::Consolidated::ConstHits& hits,
  unsigned layer,
  Vector5& x,
  SymMatrix5x5& C,
  KalmanFloat& lastz,
  trackInfo& tI);

//----------------------------------------------------------------------
// Update state with T measurement.
__device__ inline void UpdateStateT(
  SciFi::Consolidated::ConstExtendedHits& hits,
  unsigned layer,
  Vector5& x,
  SymMatrix5x5& C,
  KalmanFloat& lastz,
  trackInfo& tI);

//----------------------------------------------------------------------
// Extrapolate to the vertex using straight line extrapolation.
__device__ inline void ExtrapolateToVertex(Vector5& x, SymMatrix5x5& C, KalmanFloat& lastz);

#include "ParKalmanMethods.icc"

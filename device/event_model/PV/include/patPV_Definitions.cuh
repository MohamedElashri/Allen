/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"

namespace PatPV {

  // maximum number of vertices in a event
  static constexpr unsigned max_number_vertices = 32;

  // auxiliary class for searching of clusters of tracks

  // don't forget to actually calculate this!!
  // double  m_scatCons = 0;     // calculated from m_x0MS
  static constexpr float X0cu = 0.01;
  // static constexpr  double m_scatCons = (13.6*sqrt(X0)*(1.+0.038*log(X0)));
  static constexpr float mcu_scatCons = 0.01;

  // configuration for fitting seeds
  static constexpr size_t m_minTr = 4;
  static constexpr int m_Iterations = 20;
  static constexpr int m_minIter = 5;
  static constexpr float m_maxDeltaZ = 0.0005; // unit:: mm
  static constexpr float m_minTrackWeight = 0.00000001;
  static constexpr float m_TrackErrorScaleFactor = 1.0;
  static constexpr float m_maxChi2 = 400.0;
  static constexpr float m_trackMaxChi2 = 12.;
  // static constexpr  double m_trackChi = sqrtf(m_trackMaxChi2);     // sqrt of trackMaxChi2
  static constexpr float m_trackChi = 3.464; // sqrt of trackMaxChi2
  static constexpr float m_trackMaxChi2Remove = 25.;
  static constexpr float m_maxDeltaZCache = 1.; // unit: mm

  struct vtxCluster final {
    float z = 0;         // z of the cluster
    float sigsq = 0;     // sigma**2 of the cluster
    float sigsqmin = 0;  // minimum sigma**2 of the tracks forming cluster
    int ntracks = 1;     // number of tracks in the cluster
    bool merged = false; // flag for iterative merging
  };

  struct XYZPoint {
    float x = 0.;
    float y = 0.;
    float z = 0.;
    __device__ __host__ XYZPoint(float m_x, float m_y, float m_z) : x(m_x), y(m_y), z(m_z) {};
    __device__ __host__ XYZPoint() {};
  };

  class Vertex {
  public:
    __device__ Vertex() {};
    float x = 0.;
    float y = 0.;
    float z = 0.;
    float chi2;
    int ndof;

    float cov00 = 0.;
    float cov10 = 0.;
    float cov11 = 0.;
    float cov20 = 0.;
    float cov21 = 0.;
    float cov22 = 0.;

    __device__ void setChi2AndDoF(float m_chi2, int m_ndof)
    {
      chi2 = m_chi2;
      ndof = m_ndof;
    }
    __device__ void setPosition(XYZPoint& point)
    {
      x = point.x;
      y = point.y;
      z = point.z;
    }
    __device__ void setCovMatrix(float* m_cov)
    {
      cov00 = m_cov[0];
      cov10 = m_cov[1];
      cov11 = m_cov[2];
      cov20 = m_cov[3];
      cov21 = m_cov[4];
      cov22 = m_cov[5];
    }
    int nTracks = 0;
  };

} // namespace PatPV

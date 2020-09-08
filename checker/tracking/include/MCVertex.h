/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <vector>
#include <PV_Definitions.cuh>
#include <patPV_Definitions.cuh>

struct MCVertex {
  double x;
  double y;
  double z;
  int numberTracks;
};

struct MCPVInfo {
  MCVertex const* pMCPV;    // pointer to MC PV
  int nRecTracks;           // number of reconstructed tracks from this MCPV
  int nRecBackTracks;       // number of reconstructed backward tracks
  int indexRecPVInfo;       // index to reconstructed PVInfo (-1 if not reco)
  int nCorrectTracks;       // correct tracks belonging to reconstructed PV
  int multClosestMCPV;      // multiplicity of closest reconstructable MCPV
  double distToClosestMCPV; // distance to closest reconstructible MCPV
  int decayCharm;           // type of mother particle
  int decayBeauty;
  int number_rec_vtx = 0; // number of associated rec vertices
};

struct RecPVInfo {
  int nTracks;     // number of tracks
  int nVeloTracks; // number of velo tracks in a vertex
  int nLongTracks;
  double minTrackRD; //
  double maxTrackRD; //
  double chi2;
  double nDoF;
  double d0;
  double d0nTr;
  double chi2nTr;
  double mind0;
  double maxd0;
  int mother;
  // XYZPoint position;       // position
  double x;
  double y;
  double z;
  PatPV::XYZPoint positionSigma; // position sigmas
  int indexMCPVInfo;             // index to MCPVInfo
  PV::Vertex const* pRECPV;      // pointer to REC PV
};

using MCVertices = std::vector<MCVertex>;

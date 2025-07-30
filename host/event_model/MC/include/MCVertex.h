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

#include <vector>
#include <PV_Definitions.cuh>
#include <patPV_Definitions.cuh>

struct MCVertex {
  double x {0};
  double y {0};
  double z {0};
  int numberTracks {0};
};

struct MCPVInfo {
  MCVertex const* pMCPV {nullptr}; // pointer to MC PV
  int nRecTracks {0};              // number of reconstructed tracks from this MCPV
  int nRecBackTracks {0};          // number of reconstructed backward tracks
  int indexRecPVInfo {0};          // index to reconstructed PVInfo (-1 if not reco)
  int nCorrectTracks {0};          // correct tracks belonging to reconstructed PV
  int multClosestMCPV {0};         // multiplicity of closest reconstructable MCPV
  double distToClosestMCPV {0};    // distance to closest reconstructible MCPV
  int decayCharm {0};              // type of mother particle
  int decayBeauty {0};
  int number_rec_vtx {0}; // number of associated rec vertices
};

struct AllenRecPVInfo {
  float nTracks {0};   // number of tracks
  int nVeloTracks {0}; // number of velo tracks in a vertex
  int nLongTracks {0};
  double minTrackRD {0}; //
  double maxTrackRD {0}; //
  float chi2 {0};
  float nDoF {0};
  double d0 {0};
  double d0nTr {0};
  double chi2nTr {0};
  double mind0 {0};
  double maxd0 {0};
  int mother {0};
  // XYZPoint position;       // position
  double x {0};
  double y {0};
  double z {0};
  PatPV::XYZPoint positionSigma;      // position sigmas
  int indexMCPVInfo {0};              // index to MCPVInfo
  PV::Vertex const* pRECPV {nullptr}; // pointer to REC PV
};

using MCVertices = std::vector<MCVertex>;

#pragma once

#include "Common.h"
#include "InputTools.h"
#include "PV_Definitions.cuh"
#include "patPV_Definitions.cuh"

#include <algorithm>

// configuration for PV checker -> check values
static constexpr int nTracksToBeRecble = 4;
static constexpr float dzIsolated = 10.f; // mm
static constexpr bool matchByTracks = false;

void checkPVs(
  const std::string& foldername,
  uint number_of_files,
  PV::Vertex* rec_vertex,
  int* number_of_vertex,
  const uint number_of_selected_events,
  const uint* event_list,
  const std::string mode);

struct MCVertex {
  double x;
  double y;
  double z;
  int numberTracks;
};

typedef struct {
  MCVertex* pMCPV;          // pointer to MC PV
  int nRecTracks;           // number of reconstructed tracks from this MCPV
  int nRecBackTracks;       // number of reconstructed backward tracks
  int indexRecPVInfo;       // index to reconstructed PVInfo (-1 if not reco)
  int nCorrectTracks;       // correct tracks belonging to reconstructed PV
  int multClosestMCPV;      // multiplicity of closest reconstructable MCPV
  double distToClosestMCPV; // distance to closest reconstructible MCPV
  int decayCharm;           // type of mother particle
  int decayBeauty;
  int number_rec_vtx = 0; // number of associated rec vertices
} MCPVInfo;

typedef struct {
public:
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
  PV::Vertex* pRECPV;            // pointer to REC PV
} RecPVInfo;

void match_mc_vertex_by_distance(int ipv, std::vector<RecPVInfo>& rinfo, std::vector<MCPVInfo>& mcpvvec);

void printRat(std::string mes, int a, int b);

std::vector<MCPVInfo>::iterator closestMCPV(std::vector<MCPVInfo>& rblemcpv, std::vector<MCPVInfo>::iterator& itmc);

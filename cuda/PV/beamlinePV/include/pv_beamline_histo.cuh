#pragma once

#include <cstdint>
#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "patPV_Definitions.cuh"
#include "Handler.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsPV.cuh"
#include "FloatOperations.cuh"

__global__ void pv_beamline_histo(
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  PVTrack* dev_pvtracks,
  float* dev_zhisto,
  float* dev_beamline);

ALGORITHM(
  pv_beamline_histo,
  pv_beamline_histo_t,
  ARGUMENTS(dev_atomics_velo, dev_velo_track_hit_number, dev_pvtracks, dev_zhisto))

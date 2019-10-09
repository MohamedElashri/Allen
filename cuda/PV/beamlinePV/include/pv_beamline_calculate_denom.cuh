#pragma once

#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "Handler.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsPV.cuh"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "FloatOperations.cuh"
#include <cstdint>

__global__ void pv_beamline_calculate_denom(
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  PVTrack* dev_pvtracks,
  float* dev_pvtracks_denom,
  float* dev_zpeaks,
  uint* dev_number_of_zpeaks);

ALGORITHM(
  pv_beamline_calculate_denom,
  pv_beamline_calculate_denom_t,
  ARGUMENTS(
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_pvtracks,
    dev_zpeaks,
    dev_number_of_zpeaks,
    dev_pvtracks_denom))

/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "SMOG2_DiTrack.cuh"

INSTANTIATE_LINE(SMOG2_ditrack_line::SMOG2_ditrack_line_t, SMOG2_ditrack_line::Parameters)

__device__ bool SMOG2_ditrack_line::SMOG2_ditrack_line_t::select(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&> input)
{
  const auto& vtx = std::get<0>(input);
  if (vtx.chi2 < 0) {
    return false;
  }
  
  const bool mass_decision = parameters.m1 == -1 and parameters.m2 == -1 ?
                               true :
                               fabsf(vtx.m(parameters.m1, parameters.m2) - parameters.mMother) < parameters.massWindow;

  const bool decision = vtx.z < parameters.maxZ && vtx.z >= parameters.minZ && 
                        vtx.minp > parameters.minTrackP && vtx.minpt > parameters.minTrackPt &&
                        vtx.chi2 < parameters.maxVertexChi2 && vtx.doca <= parameters.maxDoca &&
                        vtx.charge == parameters.combCharge && mass_decision;
  return decision;
}

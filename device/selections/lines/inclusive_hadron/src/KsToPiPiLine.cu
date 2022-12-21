
/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "KsToPiPiLine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"

INSTANTIATE_LINE(kstopipi_line::kstopipi_line_t, kstopipi_line::Parameters)

__device__ bool kstopipi_line::kstopipi_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);
  const bool opposite_sign = vertex.charge() == 0;

  const bool decision = vertex.minipchi2() > parameters.minIPChi2 && opposite_sign == parameters.OppositeSign &&
                        vertex.vertex().chi2() < parameters.maxVertexChi2 && vertex.ip() < parameters.maxIP &&
                        vertex.m12(Allen::mPi, Allen::mPi) > parameters.minMass &&
                        vertex.m12(Allen::mPi, Allen::mPi) < parameters.maxMass &&
                        vertex.pv().position.z >= parameters.minZ && vertex.vertex().z() >= parameters.minZ;

  return decision;
}

__device__ void kstopipi_line::kstopipi_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  const auto ks = std::get<0>(input);
  if (sel) {
    parameters.sv_masses[index] = ks.m12(Allen::mPi, Allen::mPi);
    parameters.pt[index] = ks.vertex().pt();
    parameters.mipchi2[index] = ks.minipchi2();
  }
}

/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "ParticleContainerLifeSupport.cuh"

INSTANTIATE_ALGORITHM(particle_container_life_support::particle_container_life_support_t)

void particle_container_life_support::particle_container_life_support_t::set_arguments_size(
  ArgumentReferences<Parameters>,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  return;
}

void particle_container_life_support::particle_container_life_support_t::operator()(
  const ArgumentReferences<Parameters>&,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context&) const
{
  return;
}
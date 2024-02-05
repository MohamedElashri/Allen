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
#include "MCParticle.h"
#include "CheckerTypes.h"

template<>
uint32_t get_num_hits<Checker::Subdetector::Velo>(const MCParticle& mc_particle)
{
  return mc_particle.velo_num_hits;
}

template<>
uint32_t get_num_hits<Checker::Subdetector::UT>(const MCParticle& mc_particle)
{
  return mc_particle.ut_num_hits + mc_particle.velo_num_hits;
}

template<>
uint32_t get_num_hits<Checker::Subdetector::SciFi>(const MCParticle& mc_particle)
{
  return mc_particle.scifi_num_hits;
}

template<>
uint32_t get_num_hits<Checker::Subdetector::SciFiSeeding>(const MCParticle& mc_particle)
{
  return mc_particle.scifi_num_hits;
}

template<>
uint32_t get_num_hits_subdetector<Checker::Subdetector::Velo>(const MCParticle& mc_particle)
{
  return mc_particle.velo_num_hits;
}

template<>
uint32_t get_num_hits_subdetector<Checker::Subdetector::UT>(const MCParticle& mc_particle)
{
  return mc_particle.ut_num_hits;
}

template<>
uint32_t get_num_hits_subdetector<Checker::Subdetector::SciFi>(const MCParticle& mc_particle)
{
  return mc_particle.scifi_num_hits;
}

template<>
uint32_t get_num_hits_subdetector<Checker::Subdetector::SciFiSeeding>(const MCParticle& mc_particle)
{
  return mc_particle.scifi_num_hits;
}

template<>
uint32_t get_num_hits_subdetector<Checker::Subdetector::Downstream>(const MCParticle& mc_particle)
{
  return mc_particle.ut_num_hits + mc_particle.scifi_num_hits;
}
/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
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

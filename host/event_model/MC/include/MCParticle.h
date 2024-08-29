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
/** @file MCParticle.h
 *
 * @brief a simple MCParticle
 *
 * @author Rainer Schwemmer
 * @author Daniel Campora
 * @author Manuel Schiller
 * @date 2018-02-18
 *
 * 07-2018: updated categories and names, Dorothea vom Bruch
 */

#pragma once

#include <cstdint>
#include <cstdlib>
#include <cmath>
#include <vector>

// Monte Carlo information
struct MCParticle {
  uint32_t key {0};
  int pid {0};
  float p {0};
  float pt {0};
  float eta {0};
  float phi {0};
  float ovtx_x {0};
  float ovtx_y {0};
  float ovtx_z {0};
  bool isLong {false};
  bool isDown {false};
  bool hasVelo {false};
  bool hasUT {false};
  bool hasSciFi {false};
  bool fromBeautyDecay {false};
  bool fromCharmDecay {false};
  bool fromStrangeDecay {false};
  bool fromSignal {false};
  int motherKey {0};
  int mother_pid {0};
  int DecayOriginMother_key {0};
  int DecayOriginMother_pid {0};
  float DecayOriginMother_pt {0};
  float DecayOriginMother_tau {0};
  float charge {0};
  uint32_t velo_num_hits {0};
  uint32_t ut_num_hits {0};
  uint32_t scifi_num_hits {0};
  uint32_t numHits {0};
  uint32_t nPV {0}; // # of reconstructible primary vertices in event
  uint32_t nbHits_in_Velo {0};
  uint32_t nbHits_in_UT {0};
  uint32_t nbHits_in_SciFi {0};
  std::vector<uint32_t> hits;

  bool isMuon() const { return 13 == std::abs(pid); }
  bool isElectron() const { return 11 == std::abs(pid); }
  bool inEta2_5() const { return (eta < 5.f && eta > 2.f); }
};

template<typename T>
uint32_t get_num_hits(const MCParticle& mc_particle);

template<typename T>
uint32_t get_num_hits_subdetector(const MCParticle& mc_particle);

using MCParticles = std::vector<MCParticle>;

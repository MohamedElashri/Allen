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
  uint32_t key;
  int pid;
  float p;
  float pt;
  float eta;
  float phi;
  float ovtx_x;
  float ovtx_y;
  float ovtx_z;
  bool isLong;
  bool isDown;
  bool hasVelo;
  bool hasUT;
  bool hasSciFi;
  bool fromBeautyDecay;
  bool fromCharmDecay;
  bool fromStrangeDecay;
  uint32_t motherKey;
  int DecayOriginMother_key;
  int DecayOriginMother_pid;
  float DecayOriginMother_pt;
  float DecayOriginMother_tau;
  float charge;
  uint32_t velo_num_hits;
  uint32_t ut_num_hits;
  uint32_t scifi_num_hits;
  uint32_t numHits;
  uint32_t nPV; // # of reconstructible primary vertices in event
  std::vector<uint32_t> hits;

  bool isMuon() const { return 13 == std::abs(pid); }
  bool isElectron() const { return 11 == std::abs(pid); };
  bool inEta2_5() const { return (eta < 5.f && eta > 2.f); };
};

template<typename T>
uint32_t get_num_hits(const MCParticle& mc_particle);

template<typename T>
uint32_t get_num_hits_subdetector(const MCParticle& mc_particle);

using MCParticles = std::vector<MCParticle>;

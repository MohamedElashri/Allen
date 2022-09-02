
/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
/** @file Tracks.h
 *
 * @brief SOA Velo Tracks
 *
 * @author Rainer Schwemmer
 * @author Daniel Campora
 * @author Manuel Schiller
 * @date 2018-02-06
 */

#pragma once

#include <array>
#include <cstdint>

#include "LHCbID.cuh"

namespace Checker {
  struct Track {
    LHCbID allids[42];
    unsigned total_number_of_hits = 0;
    // SciFi information
    unsigned velo_track_index = 0;
    // Kalman information.
    float z = 0.f, x = 0.f, y = 0.f, tx = 0.f, ty = 0.f, qop = 0.f;
    float first_qop = 0.f, best_qop = 0.f;
    float chi2 = 0.f, chi2V = 0.f, chi2T = 0.f;
    unsigned ndof = 0, ndofV = 0, ndofT = 0;
    float kalman_ip = 0.f, kalman_ip_chi2 = 0.f, kalman_ipx = 0.f, kalman_ipy = 0.f;
    float kalman_docaz = 0.f;
    float velo_ip = 0.f, velo_ip_chi2 = 0.f, velo_ipx = 0.f, velo_ipy = 0.f;
    float velo_docaz = 0.f;
    float long_ip = 0.f, long_ip_chi2 = 0.f, long_ipx = 0.f, long_ipy = 0.f;
    std::size_t n_matched_total = 0;
    float p = 0.f, pt = 0.f, eta = 0.f, rho = 0.f;
    float muon_catboost_output = 0.f;
    bool is_muon = false;

    __device__ __host__ void addId(LHCbID id)
    { // 0-26 VELO , 26-30 UT, 30 - 42 SciFi
      allids[total_number_of_hits] = id;
      total_number_of_hits++;
    }

    __host__ bool containsDuplicates()
    {
      std::sort(std::begin(allids), std::begin(allids) + total_number_of_hits);
      return (std::unique(std::begin(allids), std::begin(allids) + total_number_of_hits)) !=
             std::begin(allids) + total_number_of_hits;
    }

    __device__ __host__ int nIDs() const { return sizeof(allids) / sizeof(allids[0]); }
  };
  using Tracks = std::vector<Track>;
} // namespace Checker
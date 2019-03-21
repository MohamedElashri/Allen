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

#include "LHCbID.h"

namespace Checker {
  namespace Subdetector {
    struct Velo;
    struct UT;
    struct SciFi;
  }

  struct TruthCounter {
    uint n_velo {0};
    uint n_ut {0};
    uint n_scifi {0};
  };

  struct Track {
    LHCbIDs allids;
    // Kalman information.
    float z, x, y, tx, ty, qop;
    float chi2, chi2V, chi2T;
    uint ndof, ndofV, ndofT;
    std::size_t n_matched_total = 0;
    float p;

    void addId(LHCbID id) { allids.push_back(id); }

    LHCbIDs ids() const { return allids; }

    int nIDs() const { return allids.size(); }
  };

  using Tracks = std::vector<Track>;
} // namespace Checker
